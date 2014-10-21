actionUtil = require './helpers/actionUtil'

module.exports = (req, res)->

	Model = actionUtil.parseModel(req)

	data = actionUtil.parseValues(req)

	parsedData = actionUtil.parseData data, Model

	Model.create(parsedData.raw).exec (err, newInstance) ->
		if err then return res.negotiate err

		auto = {}
		aliases = _.keys parsedData.associated

		# todo - roll back created instances on error
		# TODO - optimise if no populate/addto requests

		_.forOwn parsedData.associated, (relation, alias)->

			if relation.create.length
				auto[alias] = (cb)->
					relation.Model.create(relation.create).exec (err, associatedRecordsCreated) ->
						if err then return cb(err)
						if !associatedRecordsCreated
							sails.log.warn 'No associated records were created for some reason...'

						## subscribe to all associated instances created
						if req._sails.hooks.pubsub
							if req.isSocket
								for associatedRecord in associatedRecordsCreated
									# only subscribe to records returned
									# relation.Model.subscribe req, associatedRecord
									relation.Model.introduce associatedRecord

							for associatedRecord in associatedRecordsCreated
								relation.Model.publishCreate associatedRecord, !req.options.mirror && req

						ids = _.pluck associatedRecordsCreated, relation.Model.primaryKey
						cb(null, ids)

		async.auto auto, (error, data)->
			if error then return res.negotiate(err)

			for alias, relation of parsedData.associated
				# created records are to be added as well
				ids = data?[alias] || []
				parsedData.associated[alias].idsToAdd = _.uniq parsedData.associated[alias].add.concat(ids)


			for alias, relation of parsedData.associated
				if relation.association.type == 'collection'
					# collection, all 'add' ids to be added
					for id in relation.idsToAdd
						try
							newInstance[relation.association.alias].add(id)

							# mirrored collection
							if (mirrorAlias = actionUtil.mirror(Model, alias))
								newInstance[mirrorAlias].add(id)

						catch err
							if err then return res.negotiate(err)
				else if relation.association.type == 'model' && relation.idsToAdd.length
					# model, id should be at add[0]
					newInstance[relation.association.alias] = relation.idsToAdd[0]

			newInstance.save (err)->
				if err then return res.negotiate err
				# there should be no duplicate errors owing to the _.uniq above

				# publish add for all associated collection instances
				# this is only necessary for the 'reverse' publishing
				# no one will be subscribed to the created model yet
				if req._sails.hooks.pubsub
					for alias, relation of parsedData.associated
						if relation.association.type == 'collection'
							for id in relation.add
								Model.publishAdd newInstance[Model.primaryKey], relation.association.alias, id, !req.options.mirror && req

							# mirrored collection
							if (mirrorAlias = actionUtil.mirror(Model, alias))
								for id in relation.add
									Model.publishAdd newInstance[Model.primaryKey], mirrorAlias, id, !req.options.mirror && req

				query = Model.findOne(newInstance[Model.primaryKey])
				query = actionUtil.populateEach query, req # populate attributes requested

				query.exec (err, populatedRecord) ->
					if err then return res.serverError(err)

					# subscribe to instance created and all populated instances

					if req._sails.hooks.pubsub
						if req.isSocket
							Model.subscribe req, newInstance
							Model.introduce newInstance
							actionUtil.subscribeDeep req, populatedRecord
						Model.publishCreate newInstance, !req.options.mirror && req

					populatedRecord = actionUtil.populateNull(populatedRecord, req)

					res.status(201)
					res.ok populatedRecord # .toJSON()