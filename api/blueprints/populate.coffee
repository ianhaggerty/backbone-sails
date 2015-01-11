actionUtil = require './helpers/actionUtil'

module.exports = (req, res)->

  Model = actionUtil.parseModel req
  relation = req.options.alias

  if !relation || !Model
    return res.serverError()

  parentPk = req.param 'parentid'

  childPk = actionUtil.parsePk req
  where = if childPk then [childPk] else actionUtil.parseCriteria(req)

  
  Model.findOne(parentPk)
  .populate(relation,
    where: where
    skip: actionUtil.parseSkip(req)
    limit: actionUtil.parseLimit(req)
    sort: actionUtil.parseSort(req)
  ).exec (err, parentRecord) ->
    
    if err
      return res.serverError(err)
    
    if !parentRecord
      return res.notFound "No record found with the specified `id`: #{parentPk}"
      
    if !parentRecord[relation]
      return res.notFound "Specified record #{parentPk} is\
       missing relation #{relation}."

    if req._sails.hooks.pubsub && req.isSocket
      # only subscribe to the records returned
      actionUtil.subscribeDeep req, parentRecord

    res.ok(parentRecord[relation])