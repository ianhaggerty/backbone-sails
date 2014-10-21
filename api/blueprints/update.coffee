
actionUtil = require './helpers/actionUtil'
_ = require 'lodash'

module.exports = (req, res)->

	Model = actionUtil.parseModel(req)

	pk = actionUtil.requirePk(req)

	data = actionUtil.parseValues(req)
	if data.id? then delete data.id

	parsedData = actionUtil.parseData data, Model

	auto = {}

	# TODO - roll back created instances on error
	# TODO - optimise if no populate/addto requests

	# create all new associated instances
	_.forOwn parsedData.associated, (relation, alias)->

		# if there are new instances to be created...
		if relation.create.length
			auto[alias] = (cb)->
				relation.Model.create(relation.create).exec (err, associatedRecordsCreated) ->
					if err then return cb(err)
					if !associatedRecordsCreated
						sails.log.warn 'No associated records were created for some reason...'

					# publish create for all associated instances created
					if req._sails.hooks.pubsub
						if req.isSocket
							for associatedRecord in associatedRecordsCreated
								relation.Model.introduce associatedRecord
						for associatedRecord in associatedRecordsCreated
							relation.Model.publishCreate associatedRecord, !req.options.mirror && req

					# resolve with an array of id's that have been created
					ids = _.pluck associatedRecordsCreated, relation.Model.primaryKey

					# data.alias will be array of created id's
					cb(null, ids)

	# at the same time, query and populate the record
	auto._record = (cb)->

		query = Model.findOne(pk)

		# populate all models and the *collections to be added to*
		for alias, association of req.options.associations
			if parsedData.associated[association.alias] || association.type == 'model'
				query = query.populate association.alias

		query.exec (err, matchingRecord)->
			if (err) then return cb(err)
			cb(null, matchingRecord)

	async.auto auto, (err, asyncData)->
		if err then return res.negotiate(err)

		# grab the record
		matchingRecord = asyncData._record
		# and delete so only created id arrays are present on data
		delete asyncData._record
		if !matchingRecord then return res.notFound("Could not find record with the `id`: #{pk}")

		# add the created id's to the ids to be added
		for alias, ids of asyncData
			parsedData.associated[alias].add = _.uniq parsedData.associated[alias].add.concat(ids)

		## Set up the matchingRecord to be .save()'d

		# Carefully set up the relations
		for alias, relation of parsedData.associated
			# if an associated collection was passed in the body

			mirrorAlias = actionUtil.mirror(Model, alias)

			if relation.association.type == 'collection'
				# add any new records, and remove those not in the body presently
				if matchingRecord[alias]
					relation.remove = _.pluck matchingRecord[alias], relation.Model.primaryKey

					intersection = _.intersection relation.remove, relation.add

					# don't remove any to be added
					relation.remove = _.difference relation.remove, intersection
					# and don't add any to be removed
					relation.add = _.difference relation.add, intersection

					# remove those not to be persisted
					for id in relation.remove
						matchingRecord[alias].remove(id)

					if mirrorAlias
						for id in relation.remove
							matchingRecord[mirrorAlias].remove(id)

				# add those that are not currently added
				for id in relation.add
					try
						matchingRecord[alias].add(id)
					catch e
						if e then return res.negotiate(e)

				if mirrorAlias
					for id in relation.add
						try
							matchingRecord[mirrorAlias].add(id)
						catch e
							if e then return res.negotiate(e)
			# if an associated model was passed
			else if relation.association.type == 'model' && relation.add.length
				# simply set it on the record
				matchingRecord[alias] = relation.add[0]

		# and set the raw attributes passed as well
		for key, raw of parsedData.raw
			matchingRecord[key] = raw

		# follow all that up with a save
		matchingRecord.save (err)->
			if err then return res.negotiate err

			if req._sails.hooks.pubsub
				# publish addition and removal
				for alias, relation of parsedData.associated

					mirrorAlias = actionUtil.mirror(Model, alias)

					if relation.association.type == 'collection'
						if relation.remove
							for removedId in relation.remove
								Model.publishRemove matchingRecord[Model.primaryKey], relation.association.alias, removedId, !req.options.mirror && req
							if mirrorAlias
								for removedId in relation.remove
									Model.publishRemove matchingRecord[Model.primaryKey], mirrorAlias, removedId, !req.options.mirror && req

						for addedId in relation.add
							Model.publishAdd matchingRecord[Model.primaryKey], relation.association.alias, addedId, !req.options.mirror && req
						if mirrorAlias
							for addedId in relation.add
								Model.publishAdd matchingRecord[Model.primaryKey], mirrorAlias, addedId, !req.options.mirror && req

			# and then finally find and populate as requested by populate params/settings
			query = Model.findOne(matchingRecord[Model.primaryKey])
			query = actionUtil.populateEach query, req

			query.exec (err, populatedRecord) ->
				if err then return res.serverError(err)
				if !populatedRecord then return res.notFound('Could not find record after updating...')

				if req._sails.hooks.pubsub
					if req.isSocket
						Model.subscribe req, populatedRecord            # subscribe to record returned
						actionUtil.subscribeDeep req, populatedRecord   # subscribe to records populated

					# and finally publish update...
					Model.publishUpdate populatedRecord[Model.primaryKey], _.cloneDeep(data), !req.options.mirror && req,
						previous: matchingRecord # .toJSON()

				populatedRecord = actionUtil.populateNull(populatedRecord, req)

				res.ok(populatedRecord)