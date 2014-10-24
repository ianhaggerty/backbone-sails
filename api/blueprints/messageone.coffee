actionUtil = require './helpers/actionUtil'

module.exports = (req, res)->

  Model = actionUtil.parseModel(req)
  pk = actionUtil.requirePk(req)

  query = Model.findOne(pk)

  query.exec (err, record)->
    if (err) then return res.serverError(err)
    if (!record) then return res.notFound('No record found with the specified `id`.')

    if req._sails.hooks.pubsub
      Model.message(record, req.body)

    res.ok()