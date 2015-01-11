actionUtil = require './helpers/actionUtil'
_ = require 'lodash'

module.exports = (req, res)->

  Model = actionUtil.parseModel(req)
  relation = req.options.alias

  if !relation
    return res.serverError(
      new Error('Missing required route option, `req.options.alias`.'))

  parentPk = req.param 'parentid'

  childPk = actionUtil.parsePk(req)

  Model.findOne(parentPk).exec (err, parentRecord) ->
    
    
    if err
      return res.serverError(err)
      
    if !parentRecord || !parentRecord[relation]
      return res.notFound()

    
    parentRecord[relation].remove(childPk)

    if (mirrorAlias = actionUtil.mirror(Model, relation))
      parentRecord[mirrorAlias].remove(childPk)

    
    parentRecord.save (err)->
      
      
      if (err)
        return res.negotiate(err)

      
      if req._sails.hooks.pubsub
        
        Model.publishRemove(
          parentRecord[Model.primaryKey],
          relation,
          childPk,
          !sails.config.blueprints.mirror && req
        )
        
        if (mirrorAlias = actionUtil.mirror(Model, relation))
          Model.publishRemove(
            parentRecord[Model.primaryKey],
            mirrorAlias,
            childPk,
            !sails.config.blueprints.mirror && req
          )


      if req._sails.hooks.pubsub && req.isSocket
        Model.subscribe req, parentRecord
      
      
      # If there is no populate criteria specified & populate is false,
      # we can save another callback by simply returning the raw data here.

      populate = actionUtil.parsePopulate(req)
      if !populate || _.size(populate) == 0
        return res.ok(parentRecord)
      
      
      query = Model.findOne(parentPk)
      query = actionUtil.populateEach query, req
      
      
      query.exec (err, parentRecord)->
        
        if err
          return res.serverError err
          
        if !parentRecord
          return res.serverError()

        if req._sails.hooks.pubsub && req.isSocket
          actionUtil.subscribeDeep req, parentRecord

        parentRecord = actionUtil.populateNull(parentRecord, req)

        res.ok parentRecord