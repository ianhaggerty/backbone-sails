actionUtil = require './helpers/actionUtil'

module.exports = (req, res)->

  Model = actionUtil.parseModel(req)
  pk = actionUtil.requirePk(req)

  Model.findOne(pk).populateAll().exec (err, record)->
    if err then return res.serverError(err)
    if !record then return res.notFound("No record found with the specified `id`: #{pk}")

    Model.destroy(pk).exec (err)->
      if (err) then return res.negotiate(err)

      if req._sails.hooks.pubsub
        Model.publishDestroy pk, !req.options.mirror && req, previous: record

        if req.isSocket
          Model.unsubscribe req, record
          Model.retire(record)

      record = actionUtil.populateNull(record, req)

      res.ok(record)