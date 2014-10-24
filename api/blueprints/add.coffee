actionUtil = require './helpers/actionUtil'
_ = require 'lodash'
async = require 'async'

module.exports = (req, res)->

  Model = actionUtil.parseModel(req)
  relation = req.options.alias
  if !relation
    res.serverError(new Error('Missing required route option, `req.options.alias`.'))

  parentPk = req.param 'parentid'

  associationAttr = _.findWhere Model.associations, alias: relation
  ChildModel = sails.models[associationAttr.collection]
  childPkAttr = ChildModel.primaryKey

  child = undefined

  supposedChildPk = actionUtil.parsePk req
  if supposedChildPk
    child = {}
    child[childPkAttr] = supposedChildPk
  else
    req.options.values ?= {}
    req.options.values.blacklist ?= ['limit', 'skip', 'sort', 'where', 'id', 'parentId']
    child = actionUtil.parseValues(req)

    if !child
      res.badRequest('You must specify the record to add (either the primary key of an existing record to link, or a new object without a primary key which will be used to create a record then link it.)');

    child = actionUtil.flattenAssociations(child, ChildModel)

  createdChild = false

  async.auto
    parent: (cb) ->
      Model.findOne(parentPk).exec (err, parentRecord)->
        if err
          return cb(err)
        if !parentRecord
          return cb( status: 404 )
        if !parentRecord[relation]
          return cb( status: 404 )

        cb null, parentRecord

    child: [
      'parent'
      (cb) ->
        createChild = ->
          ChildModel.create(child).exec (err, newChildRecord)->
            if err then return cb(err)
            if req._sails.hooks.pubsub
              if req.isSocket
                ChildModel.subscribe req, newChildRecord
                ChildModel.introduce newChildRecord
              ChildModel.publishCreate newChildRecord, !req.options.mirror && req

            createdChild = true
            cb null, newChildRecord

        if child[childPkAttr]
          ChildModel.findOne(child[childPkAttr]).exec (err, childRecord)->
            if err then cb(err)
            if !childRecord then return createChild()
            cb null, childRecord
        else
          createChild()
    ],

    add: [
      'parent'
      'child'
      (cb, data) ->
        try
          coll = data.parent[relation]
          coll.add data.child[childPkAttr]

          if (mirrorAlias = actionUtil.mirror(Model, relation))
            coll = data.parent[mirrorAlias]
            coll.add data.child[childPkAttr]

          return cb()
        catch err
          if (err) then return cb(err)
          return cb() # already added
    ]
  , (err, data)->
    if err then return res.negotiate err
    data.parent.save (err)->
      isDuplicateInsertError = (err?[0]?.type == 'insert')
      if err && !isDuplicateInsertError
        return res.negotiate err

      if !isDuplicateInsertError && req._sails.hooks.pubsub
        Model.publishAdd data.parent[Model.primaryKey], relation, data.child[childPkAttr], !req.options.mirror && req, noReverse: createdChild
        if (mirrorAlias = actionUtil.mirror(Model, relation))
          Model.publishAdd data.parent[Model.primaryKey], mirrorAlias, data.child[childPkAttr], !req.options.mirror && req, noReverse: createdChild

      query = Model.findOne(parentPk)
      query = actionUtil.populateEach query, req

      query.exec (err, parentRecord) ->
        if err then return res.serverError err
        if !parentRecord then return res.serverError()

        if req._sails.hooks.pubsub && req.isSocket
          Model.subscribe req, parentRecord
          actionUtil.subscribeDeep req, parentRecord

        if createdChild
          res.set "created", JSON.stringify data.child

        parentRecord = actionUtil.populateNull(parentRecord, req)

        res.ok parentRecord