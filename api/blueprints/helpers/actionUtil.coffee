_ = require 'lodash'
JSONP_CALLBACK_PARAM = 'callback'


module.exports =

  
  ## populateEach(query, req)
  # 
  # Given a Waterline query, populate the appropriate/specified
  # association attributes and return it so it can be chained
  # further ( i.e. so you can .exec() it )

  populateEach: (query, req) ->
    DEFAULT_POPULATE_LIMIT = sails.config.blueprints.defaultLimit || 30

    options = req.options

    populate =
        options.parsed_populate ||
        (options.parsed_populate = module.exports.parsePopulate(req))


    # if populate is true and there is no populate criteria
    if (populate == true) || (!populate? && options.populate)

      # then populate all with default populate limit
      for alias, association of options.associations
        query = query.populate association.alias, limit: DEFAULT_POPULATE_LIMIT

      # else if there **is** populate criteria
    else if _.isObject(populate)

      # filter the criteria against the associations actually established
      aliasFilter = _.pluck options.associations, 'alias'

      # populate according to criteria
      for alias, criteria of populate
        if _.contains aliasFilter, alias
          query = if _.isObject criteria
            query.populate alias, criteria
          else
            query.populate alias

    # return the query to be executed
    query



  ## populateNull(records, req) 
  #
  # Assigns a `null` value to any **populated** model associations which have no
  # i.d. This useful for interfacing with client side models (Backbone) which
  # would have not been updated if the association is destroyed during the course
  # of the session.

  populateNull: (records, req) ->

    if !_.isArray records
      records = [records]
      result = records[0] # `result` is to be returned
    else
      result = records

    options = req.options

    populate =
        options.parsed_populate ||
        (options.parsed_populate = module.exports.parsePopulate(req))

    # if there is no populate criteria, nullify **all** relevant associations
    if (populate == true) || (!populate? && options.populate)
      for alias, association of options.associations
        for record in records
          if !record[alias]?
            record[alias] = null

    # if there is populate criteria, only nullify those
    else if _.isObject(populate)
      aliasFilter = _.pluck options.associations, 'alias'
      for alias, criteria of populate
        for record in records
          if _.contains(aliasFilter, alias) && !record[alias]?
            record[alias] = null

    result



  ## populateAll(query, req)
  #
  # Blindly populate all associations, with no limit whatsoever.

  populateAll: (query, req)->
    associations = req.options.associations

    for alias, association of associations
      query = query.populate association.alias

    query



  ## flattenAssociations(records, Model)
  #
  # This method is used from the 'parseData' method, to strip out any
  # associated models that would otherwise be created.

  flattenAssociations: (records, Model)->

    if !_.isArray records
      records = [records]
      result = records[0] # `result` is to be returned
    else
      result = records

    # aliases = _.pluck Model.associations, 'alias'

    for association in Model.associations

      nestedModel = sails.models[association[association.type]]

      for record in records
        # if is an associated collection
        if _.isArray record[association.alias]

          # for each associated model
          for nested, i in record[association.alias]

            # if key is present
            if nested[nestedModel.primaryKey]?

              # strip out the model, and replace with just the i.d.
              record[association.alias][i] = nested[nestedModel.primaryKey]

              # otherwise, double nest create not allowed! nullified.
            else
              record[association.alias][i] = null

          # if is associated model
        else if _.isObject record[association.alias]

          # if key is present
          if record[association.alias][nestedModel.primaryKey]?

            # strip out the model, and replace with just the i.d.
            record[association.alias] = nested[nestedModel.primaryKey]

            # otherwise, double nest create not allowed! nullified.
          else
            record[association.alias] = null

    result



  ## subscribeDeep(req, record)
  #
  # This method is used for socket based requests. It subscribes the client
  # to all associated models the the `record` currently has populated.

  subscribeDeep: (req, record) ->
    _.each req.options.associations, (assoc)->

      # identity of associated model
      ident = assoc[assoc.type]
      AssociatedModel = sails.models[ident]

      if assoc.type == 'collection' && record[assoc.alias]
        for record in record[assoc.alias]
          if record[AssociatedModel.primaryKey]?
            AssociatedModel.subscribe req, record

      else if assoc.type == 'model' &&
          record[assoc.alias]?[AssociatedModel.primaryKey]?

        AssociatedModel.subscribe req, record[assoc.alias]



  ## parsePk(req)
  # 
  # Parse primary key value for use in a Waterline criteria
  # (e.g. for `find`, `update`, or `destroy`)

  parsePk: (req) ->
    pk = req.options.id || req.param('id')

    # exclude criteria on id field
    pk = if _.isPlainObject(pk) then undefined else pk
  
  
  
  ## requirePk(req)
  # 
  # Parse primary key value from parameters.
  # Throw an error if it cannot be retrieved.

  requirePk: (req) ->
    pk = module.exports.parsePk(req)

    if !pk
      err = new Error 'No `id` parameter provided. (Note: even if the models primary key is not named `id` - `id` should be used as the name of the parameter - it will be mapped to the proper primary key name)'
      err.status = 400
      throw err

    pk
  
  
  
  ## parseCriteria(req)
  # 
  # This method will take the `where` criteria string (JSON), which will be
  # specified as a query parameter, and parse it, returning a criteria object
  # which can be passed straight into waterline.
  
  parseCriteria: (req) ->

    where = req.query.where || getHeader(req, 'where')

    if _.isString(where)
      where = tryToParseJSON(where)

    _.merge {}, req.options.where, where
  
  
  
  ## parseValues(req)
  # 
  # This method is intended to parse the 'values' as part of a request. These
  # are typically values to be persisted to the database as part of a POST or
  # PUT request. They are all declared within the html body (nothing else).
  
  parseValues: (req)->
    values = req.body # _.defaults req.body, req.params

    values = _.omit values, (v)-> _.isUndefined(v) # allow null to be persisted

    values
  
  
  
  ## parseData(data, Model)
  # 
  # This is a complicated function intended to organise the values and
  # associated models coming down as part of a request. The end result is an
  # object which has 'raw' values and associated models separated.
  #
  # The return object will have this form:
  #
  # {
  #   raw: {
  #     attr: value
  #     ...
  #   },
  #   associated: {
  #     attr: {
  #       add: an array of id's to be added to attr
  #       create: an array of models to first be created, and then added to attr
  #     }
  #     ...
  #   }
  # }
  #
  # This utilized heavily, to make sure the `addedTo` and `removedFrom` socket
  # events actually fire properly, amongst other things.
  
  parseData: (data, Model)->
    aliases = _.pluck Model.associations, 'alias'

    # `result` is to be returned
    result =
      raw: {}
      associated: {}

    
    parseRecord = (aliasData, AssociatedModel)->
      if _.isObject(aliasData) && !aliasData[AssociatedModel.primaryKey]?
        
        # is pojo without a key, flatten associated attributes before persisting
        aliasData = module.exports.flattenAssociations aliasData, AssociatedModel

        # schedule a create operation
        result.associated[alias].create.push aliasData
      
      else
        # if object with a key, or a key itself, schedule to be added
        result.associated[alias].add
          .push aliasData[AssociatedModel.primaryKey] || aliasData


    for alias, aliasData of data

      # if attribute is an association
      if aliasData? && _.contains(aliases, alias)
      
        result.associated[alias] = { create:[], add: [] }
        
        association = result.associated[alias].association =
          _.findWhere Model.associations, alias: alias

        AssociatedModel = result.associated[alias].Model =
          sails.models[association[association.type]]

        if _.isArray aliasData
          if association.type == 'collection'
            for record in aliasData
              parseRecord(record, AssociatedModel)
        
        else if association.type == 'model'
          parseRecord(aliasData, AssociatedModel)
        
        else
          sails.log.warn "Could not parse attribute #{alias}:#{aliasData}.\
          Type collection expects an array."

      # else it is considered 'raw' information
      else
        result.raw[alias] = aliasData

    result
  
  
  
  ## parseModel(req)
  # 
  # Determine the model class to use w/ this blueprint action.
  
  parseModel: (req)->
    model = req.options.model || req.options.controller
    if !model
      throw new Error('No "model" specified in route options.')

    Model = req._sails.models[model]
    
    if !Model
      throw new Error("Invalid route option, `model`.\n \
      I don't know about any models named: #{model}")

    Model



  ## parseSort(req)
  # 
  # Parse the sort criteria from a query string.

  parseSort: (req)->
    query = req.query.sort
      # || getHeader(req, 'sort')  || req.options.sort|| undefined

    if _.isString(query)
      sort = tryToParseJSON(query)

    # sort will be undefined if it was already parsed
    if !sort
      sort = query

    sort



  ## parsePopulate(req)
  # 
  # Parse the populate criteria from a query string.

  parsePopulate: (req)->
    
    query = req.query.populate
      # || getHeader(req, 'populate') || req.options.populate || undefined

    if !query?
      return query

    if _.isString(query)
      populate = tryToParseJSON(query)
      
      if _.isArray populate
        keys = populate
        
      else if !populate?
        keys = query.split(',')
        
      if keys
        populate = {}
        for key in keys
          populate[key] = null

    if !populate?
      populate = query

    populate # true|false|object|undefined
  
  
  
  ## parseLimit(req)
  # 
  # Parse the limit criteria from a query string.
  
  parseLimit: (req)->
    DEFAULT_LIMIT = sails.config.blueprints.defaultLimit || 30
    
    limit = req.query.limit || DEFAULT_LIMIT
      # || getHeader(req, 'limit') || (if req.options.limit? then req.options.limit else DEFAULT_LIMIT)
    
    if limit then limit = +limit
    
    limit
  
  
  
  ## parseLimit(req)
  # 
  # Parse the skip criteria from a query string.
  
  parseSkip: (req)->
    DEFAULT_SKIP = 0
    
    skip = req.query.skip || DEFAULT_SKIP
      # || getHeader(req, 'skip') || (if req.options.skip? then req.options.skip else DEFAULT_SKIP)
    
    if skip then skip = +skip
    
    skip
  
  
  
  ## mirror: (Model, alias)
  #
  # This function returns the mirror alias, if it exists and is configured
  # properly. This is used to maintain self referencing many to many associations
  # with the waterline API.

  mirror: (Model, alias)->
    if Model._attributes[alias]?.via == (mirrorAlias = '_' + alias) &&
        Model._attributes[mirrorAlias]?.via == alias
      mirrorAlias
    else
      false

tryToParseJSON = (json)->
  if !_.isString(json) then return null
  try
    JSON.parse(json)
  catch e
    null


# TODO remove with testing
defaultHeaderPrefix = 'sails-'
getHeader = (req, key, prefix)->
  if prefix? then key = prefix + key
  header = req.header?(key) || (req.headers?[key]? && req.headers[key]) || req.get?(key)
  if !header? && !prefix? then getHeader(req, key, defaultHeaderPrefix) else header