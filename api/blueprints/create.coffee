actionUtil  = require './helpers/actionUtil'
_           = require 'lodash'
Promise     = require "bluebird"

module.exports = (req, res)->
  
  Model = actionUtil.parseModel(req)
  
  data = actionUtil.parseValues(req)
  
  parsedData = actionUtil.parseData data, Model
  
  promises = {}
  aliases = _.keys parsedData.associated
  
  
  # TODO - roll back created instances on error
  
  
  # first, create any new associated records sent down within the body
  
  _.forOwn parsedData.associated, (relation, alias)->
    
    # if there are any associated records to be created...
    if relation.create.length
      
      # create them, callback with there id's
      promises[alias] = new Promise (resolve, reject)->
        
        relation.Model.create(relation.create)
        .exec (err, associatedRecordsCreated) ->
          
          if err then return reject(err)
          
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

  
  # run those create callbacks in parallel...
  Promise.props(promises)
  
  .error (err)->
    if error then return res.negotiate(err)
  
  .then (data)->
    
    # if no errors, then created records need to be added, as well as
    # existing records (records with i.d's)
    
    for alias, relation of parsedData.associated
      
      # created i.d's to add
      ids = data?[alias] || []
      
      parsedData.associated[alias].idsToAdd =
        _.uniq parsedData.associated[alias].add.concat(ids)

      # if it is an associated model, simply assign attr to the i.d.
      # this will be persisted when the 'raw' record is created
      if relation.association.type == 'model' && relation.idsToAdd.length
        
        parsedData.raw[relation.association.alias] = relation.idsToAdd[0]

    # create the new instance
    Model.create(parsedData.raw).exec (err, newInstance) ->
      if err then return res.negotiate err

      res.status(201)

      
      # subscribe to instance created & publish created event
      
      if req._sails.hooks.pubsub
        if req.isSocket
          Model.subscribe req, newInstance
          Model.introduce newInstance
        Model.publishCreate newInstance, !req.options.mirror && req
      
        
      # if there are no associated models created, just return the instance with
      # populate requests as null, no more callbacks are needed
      
      if !aliases.length
        newInstance = actionUtil.populateNull(newInstance, req)
        return res.ok(newInstance)
      
      
      # once the instance is created, the models within the associated
      # collections need to be added, and then the instance needs to be .save()
      
      for alias, relation of parsedData.associated
        if relation.association.type == 'collection'
          
          for id in relation.idsToAdd
            try
              newInstance[relation.association.alias].add(id)

              # mirrored collection, for many to many self reference
              if (mirrorAlias = actionUtil.mirror(Model, alias))
                newInstance[mirrorAlias].add(id)

            catch err
              if err then return res.negotiate(err)

      
      # save the instance & trigger all those 'addedTo' events
      newInstance.save (err)->
        if err then return res.negotiate err
        # there should be no duplicate errors owing to the _.uniq above
        
        
        
        # publish add for all associated collection instances
        # this is only necessary for the 'reverse' publishing
        # no one will be subscribed to the created model yet
        
        if req._sails.hooks.pubsub
          for alias, relation of parsedData.associated
            
            if relation.association.type == 'collection'
              for id in relation.add
                Model.publishAdd newInstance[Model.primaryKey],
                  relation.association.alias, id, !req.options.mirror && req

              # mirrored collection, for many to many self reference
              if (mirrorAlias = actionUtil.mirror(Model, alias))
                for id in relation.add
                  Model.publishAdd newInstance[Model.primaryKey],
                    mirrorAlias, id, !req.options.mirror && req
        
        
        # If there is no populate criteria specified & populate is false,
        # we can save another callback by simply returning the raw data here.
        
        populate = actionUtil.parsePopulate(req)
        if !populate || _.size(populate) == 0
          return res.ok(newInstance)
        
        
        # Finally, run a final request to get the instance, along with any
        # requested attributes populated. This is necessary as the associated
        # models may have had model i.d's updated.
        #
        # Also the attributes need to be populated as specified in the populate
        # criteria.
        
        query = Model.findOne(newInstance[Model.primaryKey])
        query = actionUtil.populateEach query, req # populate attributes requested

        query.exec (err, populatedRecord) ->
          if err then return res.serverError(err)

          # subscribe to all populated instances
          if req._sails.hooks.pubsub && req.isSocket
            actionUtil.subscribeDeep req, populatedRecord

          populatedRecord = actionUtil.populateNull(populatedRecord, req)

          res.ok populatedRecord # .toJSON()