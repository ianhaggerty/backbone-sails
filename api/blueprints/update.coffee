actionUtil  = require './helpers/actionUtil'
_           = require 'lodash'
Promise     = require "bluebird"

module.exports = (req, res)->

  Model = actionUtil.parseModel(req)

  pk = actionUtil.requirePk(req)

  data = actionUtil.parseValues(req)
  
  if data[Model.primaryKey]?
    delete data[Model.primaryKey]

  parsedData = actionUtil.parseData data, Model

  promises = {}

  # TODO - roll back updated instances on error
  # TODO - optimise if no populate/addto requests
  
  
  # first, create any new associated records sent down within the body
  
  _.forOwn parsedData.associated, (relation, alias)->

    # if there are any associated records to be created...
    if relation.create.length

      # create them, callback with there id's
      promises[alias] = new Promise (resolve, reject)->
        
        relation.Model.create(relation.create)
        .exec (err, associatedRecordsCreated) ->
            
          if err
            reject(err)
          
          if !associatedRecordsCreated
            sails.log.warn 'No associated records were created for some reason...'


          if req._sails.hooks.pubsub

            # if this is a socket based request...
            if req.isSocket

              # 'introduce' the records so they emit socket events correctly
              for associatedRecord in associatedRecordsCreated
                relation.Model.introduce associatedRecord

            # publish the relevant 'created' events
            for associatedRecord in associatedRecordsCreated
              relation.Model.publishCreate associatedRecord,
                  !req.options.mirror && req

          # resolve with an array of id's that have been created
          # this will be just a single id if it is a 'to-one' association
          ids = _.pluck associatedRecordsCreated, relation.Model.primaryKey
          
          resolve(ids)
  
  # at the same time, query and populate the record
  promises._record = new Promise (resolve, reject)->

    query = Model.findOne(pk)

    # populate all models and the **collections to be added to**
    for alias, association of req.options.associations
      if parsedData.associated[association.alias] || association.type == 'model'
        query = query.populate association.alias

    query.exec (err, matchingRecord)->
      if (err) then return reject(err)

      resolve(matchingRecord)

  Promise.props(promises)
          
  .error (err) ->
    return res.negotiate(err)
          
  .then (asyncData)->
    
    # grab the record
    matchingRecord = asyncData._record
    previousRecord = matchingRecord
    
    # and delete so only created id arrays are present on data
    delete asyncData._record
    
    if !matchingRecord
      return res.notFound("Could not find record with the `id`: #{pk}")

    
    # add the created id's to the ids to be added
    for alias, ids of asyncData
      parsedData.associated[alias].add =
        _.uniq parsedData.associated[alias].add.concat(ids)


    # Carefully set up the relations
    for alias, relation of parsedData.associated
      
      mirrorAlias = actionUtil.mirror(Model, alias)
      
      
      # if an associated collection was passed in the body
      if relation.association.type == 'collection'
        
        # add any new records, and remove those not in the body presently
        if matchingRecord[alias]
          relation.remove = _.pluck matchingRecord[alias], relation.Model.primaryKey

          intersection = _.intersection relation.remove, relation.add

          # don't remove any to be added
          relation.remove = _.difference relation.remove, intersection
          
          # and don't add any to be removed
          relation.add = _.difference relation.add, intersection

          # remove those not to be persisted
          for id in relation.remove
            matchingRecord[alias].remove(id)

          if mirrorAlias
            for id in relation.remove
              matchingRecord[mirrorAlias].remove(id)

        # add those that are not currently added
        # try-catch shouldn't be necessary since there'll not be any duplicate
        # errors anymore
        #try
        for id in relation.add
          matchingRecord[alias].add(id)
        #catch e
        #  if e then return res.negotiate(e)

        if mirrorAlias
          for id in relation.add
            matchingRecord[mirrorAlias].add(id)
      
      
      # else if an associated model was passed
      else if relation.association.type == 'model' && relation.add.length
        
        # simply set the id on the record
        matchingRecord[alias] = relation.add[0]

    # and set the raw attributes passed as well
    for key, raw of parsedData.raw
      matchingRecord[key] = raw

    # follow all that up with a save
    matchingRecord.save (err)->
      if err then return res.negotiate err
      
      
      if req._sails.hooks.pubsub
        if req.isSocket
          Model.subscribe req, matchingRecord
          
        # publish update
        Model.publishUpdate matchingRecord[Model.primaryKey],
          _.cloneDeep(data), !req.options.mirror && req,
          previous: previousRecord
        
        
        # publish addition and removal
        for alias, relation of parsedData.associated

          mirrorAlias = actionUtil.mirror(Model, alias)

          if relation.association.type == 'collection'
            
            # removal
            if relation.remove
              for removedId in relation.remove
                Model.publishRemove matchingRecord[Model.primaryKey],
                  relation.association.alias, removedId,
                    !req.options.mirror && req
                
              if mirrorAlias
                for removedId in relation.remove
                  Model.publishRemove matchingRecord[Model.primaryKey],
                    mirrorAlias, removedId, !req.options.mirror && req

            # addition
            for addedId in relation.add
              Model.publishAdd matchingRecord[Model.primaryKey],
                relation.association.alias, addedId, !req.options.mirror && req
            
            if mirrorAlias
              for addedId in relation.add
                Model.publishAdd matchingRecord[Model.primaryKey],
                  mirrorAlias, addedId, !req.options.mirror && req
      
      
      # If there is no populate criteria specified & populate is false,
      # we can save another callback by simply returning the raw data here.

      populate = actionUtil.parsePopulate(req)
      if !populate || _.size(populate) == 0
        return res.ok(matchingRecord)
      
      
      # and then finally find and populate as requested by populate params/settings
      
      query = Model.findOne(matchingRecord[Model.primaryKey])
      query = actionUtil.populateEach query, req

      query.exec (err, populatedRecord) ->
        if err then return res.serverError(err)
        
        if !populatedRecord
          return res.notFound('Could not find record after updating...')

        if req._sails.hooks.pubsub
          if req.isSocket
            actionUtil.subscribeDeep req, populatedRecord

        populatedRecord = actionUtil.populateNull(populatedRecord, req)

        res.ok(populatedRecord)