actionUtil  = require './helpers/actionUtil'
_           = require 'lodash'
Promise     = require "bluebird"

module.exports = (req, res)->

  Model = actionUtil.parseModel(req)
  
  relation = req.options.alias
  
  if !relation
    res.serverError(
      new Error('Missing required route option, `req.options.alias`.'))

  parentPk = req.param 'parentid'

  associationAttr = _.findWhere Model.associations, alias: relation
  ChildModel = sails.models[associationAttr.collection]
  childPkAttr = ChildModel.primaryKey

  child = undefined

  supposedChildPk = actionUtil.parsePk req
  
  # if the child has an i.d, it is assumed it exists
  if supposedChildPk
    child = {}
    child[childPkAttr] = supposedChildPk
    
  # otherwise it will be created
  else
    child = actionUtil.parseValues(req)

    if !child
      res.badRequest('You must specify the record to add (either the primary key of an existing record to link, or a new object without a primary key which will be used to create a record then link it.)');

    # no nested models are allowed to be created from an add request
    # the associations will be flattened
    child = actionUtil.flattenAssociations(child, ChildModel)
  
  
  createdChild = false
  
  
  promises =
  
    # find the parent record
    parent: new Promise (resolve, reject)->
      
      Model.findOne(parentPk).exec (err, parentRecord)->
        if err
          return reject(err)
          
        if !parentRecord
          return reject( status: 404 )
          
        if !parentRecord[relation]
          return reject( status: 404 )

        resolve(parentRecord)

    # create the child record, or find it
    child: new Promise (resolve, reject)->
      createChild = ->
        ChildModel.create(child).exec (err, newChildRecord)->
          if err then return reject(err)
          
          createdChild = true
          
          # resolve new instance
          resolve newChildRecord
      
      # if the child has an i.d, resolve with it
      if child[childPkAttr]
        ChildModel.findOne(child[childPkAttr]).exec (err, childRecord)->
          if err
            reject(err)
          if !childRecord
            return createChild()
        
          resolve(child)
          
      # otherwise create it
      else
        createChild()
          
  Promise.props(promises)

  .error (err)->
    return res.negotiate err

  .then (data)->
    
    if createdChild
      
      # publish the creation
      if req._sails.hooks.pubsub
        if req.isSocket
          ChildModel.subscribe req, data.child
          ChildModel.introduce data.child
        ChildModel.publishCreate data.child, !req.options.mirror && req
        
    
    try
      coll = data.parent[relation]
      coll.add data.child[childPkAttr]
  
      if (mirrorAlias = actionUtil.mirror(Model, relation))
        coll = data.parent[mirrorAlias]
        coll.add data.child[childPkAttr]
    
    catch err
      if (err)
        return res.negotiate err
    
    
    data.parent.save (err)->
      
      isDuplicateInsertError = (err?[0]?.type == 'insert')
      
      if err && !isDuplicateInsertError
        return res.negotiate err

      if !isDuplicateInsertError && req._sails.hooks.pubsub
        
        Model.publishAdd(
          data.parent[Model.primaryKey],
          relation,
          data.child[childPkAttr],
          !req.options.mirror && req,
          noReverse: createdChild
        )
        
        if (mirrorAlias = actionUtil.mirror(Model, relation))
          
          Model.publishAdd(
            data.parent[Model.primaryKey],
            mirrorAlias,
            data.child[childPkAttr],
            !req.options.mirror && req,
            noReverse: createdChild
          )

          
      # If a child was created, it'll be returned as a header regardless of
      # populate criteria.
      
      if createdChild
        res.set "created", JSON.stringify data.child
      

      # If there is no populate criteria specified & populate is false,
      # we can save another callback by simply returning the raw data here.
      
      populate = actionUtil.parsePopulate(req)
      if !populate || _.size(populate) == 0
        return res.ok data.parent
      

      query = Model.findOne(parentPk)
      query = actionUtil.populateEach query, req

      query.exec (err, parentRecord) ->
        if err then return res.serverError err
        if !parentRecord then return res.serverError()

        if req._sails.hooks.pubsub && req.isSocket
          Model.subscribe req, parentRecord
          actionUtil.subscribeDeep req, parentRecord

        parentRecord = actionUtil.populateNull(parentRecord, req)

        res.ok parentRecord