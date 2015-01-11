actionUtil = require './helpers/actionUtil'
_ = require 'lodash'

module.exports = (req, res)->

  if actionUtil.parsePk(req)
    return require('./messageone')(req, res)

  Model = actionUtil.parseModel(req)

  query = Model.find()
  .where(actionUtil.parseCriteria(req))
  .limit(actionUtil.parseLimit(req))
  .skip(actionUtil.parseSkip(req))
  .sort(actionUtil.parseSort(req))

  query.exec (err, records)->
    if (err)
      return res.serverError(err)

    if req._sails.hooks.pubsub
      for record in records
        Model.message(record, req.body)

    res.ok()


