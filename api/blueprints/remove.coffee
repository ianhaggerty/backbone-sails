actionUtil = require './helpers/actionUtil'
_ = require 'lodash'

module.exports = (req, res)->

	Model = actionUtil.parseModel(req)
	relation = req.options.alias

	if !relation
		return res.serverError(new Error('Missing required route option, `req.options.alias`.'))

	parentPk = req.param 'parentid'

	childPk = actionUtil.parsePk(req)

	Model.findOne(parentPk).exec (err, parentRecord) ->
		if err then return res.serverError(err)
		if !parentRecord then return res.notFound()
		if !parentRecord[relation] then return res.notFound()

		parentRecord[relation].remove(childPk)

		if (mirrorAlias = actionUtil.mirror(Model, relation))
			parentRecord[mirrorAlias].remove(childPk)

		parentRecord.save (err)->
			if (err) then return res.negotiate(err)

			if req._sails.hooks.pubsub
				Model.publishRemove parentRecord[Model.primaryKey], relation, childPk, !sails.config.blueprints.mirror && req
				if (mirrorAlias = actionUtil.mirror(Model, relation))
					Model.publishRemove parentRecord[Model.primaryKey], mirrorAlias, childPk, !sails.config.blueprints.mirror && req

			query = Model.findOne(parentPk)
			query = actionUtil.populateEach query, req

			query.exec (err, parentRecord)->
				if err then return res.serverError err
				if !parentRecord then return res.serverError()

				if req._sails.hooks.pubsub && req.isSocket
					Model.subscribe req, parentRecord
					actionUtil.subscribeDeep req, parentRecord

				parentRecord = actionUtil.populateNull(parentRecord, req)

				res.ok parentRecord