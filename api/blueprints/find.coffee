actionUtil = require './helpers/actionUtil'
_ = require 'lodash'

module.exports = (req, res) ->

  if actionUtil.parsePk req
    return require('./findOne')(req, res)

  Model = actionUtil.parseModel(req)

  query = Model.find()
  .where(actionUtil.parseCriteria(req))
  .limit(actionUtil.parseLimit(req))
  .skip(actionUtil.parseSkip(req))
  .sort(actionUtil.parseSort(req))

  query = actionUtil.populateEach(query, req)

  query.exec (err, records)->
    if err then return res.serverError(err)

    # subscribe to records
    if req._sails.hooks.pubsub && req.isSocket
      Model.subscribe req, records

      # subscribe to populated records
      for record in records
        actionUtil.subscribeDeep req, record

    # the only place where 'created' events are subscribed to
    watch = req.query.watch || req.options.autowatch || req.options.autoWatch
    if watch == 'false' || !watch
      Model.unwatch(req)
    else if watch # == 'true' /model?watch=true
      Model.watch(req)

    records = actionUtil.populateNull(records, req)

    res.ok records