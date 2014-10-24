actionUtil = require './helpers/actionUtil'

module.exports = (req, res)->

  Model = actionUtil.parseModel(req)
  pk = actionUtil.requirePk(req)

  query = Model.findOne(pk)

  query = actionUtil.populateEach query, req

  query.exec (err, record)->
    if err then return res.serverError(err)
    if !record then return res.notFound "No record found with the specified `id`: #{pk}"

    # subscribe to the record and populated records
    if req._sails.hooks.pubsub && req.isSocket
      Model.subscribe req, record
      actionUtil.subscribeDeep req, record

    record = actionUtil.populateNull(record, req)

    res.ok record

