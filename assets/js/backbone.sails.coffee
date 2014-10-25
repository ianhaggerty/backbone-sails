((Backbone, $, _)->

  socketClient = undefined # socketClient stored here when it is found
  Sails = {} # global to be exposed as `Backbone.Sails`
  Sails.Models = {} # keeps track of the event aggregator for records & Models

  Sails.config =
    eventPrefix: ""         # prefix to all events emitted on model & collection
    populate: false         # sails populate criteria, can be a string, array or object
    where: false            # waterline `where` criteria, can be an object
    limit: 30               # waterline `limit` criteria, default goes here
    sort: false             # waterline `sort` criteria, can be an object|number
    skip: false             # waterline `skip` criteria, can be a number
    watch: true             # similar to `autowatch`, but acts as a switch on or off
    prefix: ''              # blueprint `prefix` option
    sync: ['socket', 'ajax', 'subscribe'] # ['set'], configures how to sync model & collection
    timeout: false          # timeout for socket only request
    poll: 50                # how often to check for a boolean resolution
    client: -> io.socket    # where the socket client *should* be found
    promise: (promise)-> promise # wraps jQuery promises e.g. (p)-> Q(p); for Q promises
    log: true               # simple boolean to indicate whether to log socket requests or not

  keys =
    modelConfig: ['populate', 'sync']
    modelQuery: ['populate']
    collectionConfig: ['populate', 'sync', 'where', 'sort', 'skip', 'limit', 'watch']
    collectionQuery: ['populate', 'where', 'sort', 'skip', 'limit', 'watch']
    messageAction: '__action'
    configPrefix: '__config'

  Sails.configure = (key, config) ->
    if _.isObject key
      mapConfig(key)
    else
      (conf = {})[key] = config
      mapConfig(conf)

  mapConfig = (config) ->
    for key, val of config
      if parseConfig[key]?
        Sails.config[key] = parseConfig[key] val
      else
        Sails.config[key] = val
    Sails.config

  parseConfig =
    eventPrefix:  (prefix) ->
      if _.isString prefix
        # not empty and no double dot
        if prefix.length && _.last(prefix) != ':'
          prefix += ':' # then add one
        prefix
      else if !prefix then ''
      else throw new Error "config.eventPrefix should be a string"
    prefix: (prefix) ->
      if _.isString prefix
        # not empty and no forward slash
        if prefix.length && prefix[0] != '/'
          prefix = '/' + prefix # then add one
        return prefix
      else if !prefix then ''
      else throw new Error "config.prefix should be a string"

  getConfig = (key, options, instance) ->
    if options[key]?                            # request level
      options[key]
    else if instance[keys.configPrefix + key]?  # instance level
      instance[keys.configPrefix + key]
    else if instance.config?[key]?              # constructor level
      instance.config[key]
    else Sails.config[key]                      # global level

  modelNameError = ->
    throw new Error "A `modelName` is required"

  urlError = ->
    throw new Error 'A `url` property or function must be specified'

  idError = ->
    throw new Error 'An `id` property must be specified'

  clientNotFoundError = ->
    throw new Error 'A socket client could not be found. Consider revising `Sails.config.client`'

  timeoutError = (time)->
    throw new Error "Timed out after #{time}ms"

  associationError = (key)->
    throw new Error "No association found with key #{key}"

  # promise utility methods
  promise =
    chain: (from, to) ->
      from.then ->
        to.resolve.apply to, arguments
      from.fail ->
        to.reject.apply to, arguments

    timeout: (defer) ->
      timeout = Sails.config.timeout
      if timeout != false
        to = setTimeout ->
          defer.reject timeout
        , timeout
        defer.always ->
          clearTimeout to
      defer

    pollFor: (boolF, polling)->

      if polling # pollFor callback
        if boolF()
          boolF.polling = false
          return boolF.defer.resolve()
        else
          setTimeout ->
            promise.pollFor boolF, true
          , Sails.config.poll
          return boolF.defer
      else if boolF.polling # intermediate call, return deferred
        return boolF.defer
      else # first call, create defer, polling and recall with polling
        boolF.defer = $.Deferred()
        boolF.polling = true
        return promise.pollFor boolF, true

    wrap: (promise, internal)->
      if internal then promise else Sails.config.promise(promise)

  isModel = (instance) ->
    instance instanceof Backbone.Model

  isCollection = (instance) ->
    instance instanceof Backbone.Collection

  isModelConstructor = (ctor)->
    ctor.prototype instanceof Backbone.Model ||
      ctor == Backbone.Model

  getModelName = (instance) ->
    _.result(instance, 'modelName').toLowerCase()

  getHeader = (xhr, header)->
    if xhr.headers?
      xhr.headers[header]
    else
      xhr.getResponseHeader(header)

  clientFound = ->
    Sails.config.client().socket?

  # poll indefinitely for a (real) client
  promise.pollFor(clientFound).done ->
    socketClient = Sails.config.client()
  setTimeout -> # set a warning
    if !clientFound() then clientNotFoundError()
  , 5000

  socketConnected = ->
    socketClient?.socket?.connected

  # expose a public connected boolean
  Sails.connected = ->
    Boolean socketConnected()

  socketConnecting = ->
    promise.timeout(promise.pollFor(socketConnected))
    .fail(timeoutError)
    .promise()

  # expose a connecting promise
  Sails.connecting = ->
    promise.wrap(socketConnecting())

  methodMap =
    create: 'post'
    read: 'get'
    update: 'put'
    patch: 'put'
    delete: 'delete'

  sendSocketRequest = (method, instance, options)->
    defer = new $.Deferred()
    url = options.url || _.result(instance, 'url') || urlError
    method = options.method?.toLowerCase() || methodMap[method]

    payload = if options.payload
      options.payload
    else if isCollection instance
      undefined
    else
      payload = instance.attributes

    handler = (res, jwres)->
      if Sails.config.log then console.info "socket response:", jwres.statusCode, jwres.body, jwres.headers

      if jwres.statusCode >= 400

        options.error? jwres, jwres.statusCode, jwres.body # triggers 'error'
        defer.reject jwres, jwres.statusCode, jwres.body  # jqXHR convention

      else
        options.success? res, jwres.statusCode, jwres # triggers 'sync'
        defer.resolve res, jwres.statusCode, jwres # jqXHR convention

      instance.trigger "request", instance, promise.wrap(defer.promise()), options

    if Sails.config.log then console.info "socket request:", method, url, payload

    if payload
      socketClient[method] url, payload, handler
    else
      socketClient[method] url, handler

    defer.promise()


  sendingSocketRequest = (method, instance, options) ->
    result = $.Deferred()

    # check for connection
    socketConnecting().done ->

      # augment the url before request
      augmentUrl method, instance, options

      # make request
      promise.chain sendSocketRequest(method, instance, options), result

    .fail (timeout)->
      result.reject(timeout, method, instance, options)

    result

  sendingAjaxRequest = (method, instance, options)->

    # augment url before request
    augmentUrl method, instance, options

    # make the request
    result = instance.sync method, instance, options

    result

  augmentUrl = (method, instance, options) ->

    url = options.url || _.result(instance, 'url')

    if isCollection instance
      url += queryString instance, options, keys.collectionQuery
    else if method != 'delete'
      url += queryString instance, options, keys.modelQuery

    options.url = url

  queryString = (instance, options, keys) ->

    queries = []

    for key in keys
      query = getConfig key, options, instance
      if query != false # false nullifies the query param
        queries.push "#{key}=#{parseQuery[key](query)}"

    if queries.length
      '?' + queries.join '&'
    else ''

  parseQuery =
  # where is an object
  # where = { name: { contains: "abc" } }
    where: (criteria) ->
      if _.isObject criteria
        JSON.stringify criteria
      else
        criteria

  # sort is a string or an object
  # sort = "name ASC"; sort = { name: 1};
    sort: (criteria) ->
      if _.isObject criteria
        JSON.stringify criteria
      else
        criteria

  # skip is just a number
    skip: (criteria) -> criteria

  # limit is just a number
    limit: (criteria) -> criteria

  # Populate is an array, an object, a space delimited string or `true`
    populate: (criteria) ->
      if _.isObject criteria || criteria == true
        JSON.stringify criteria
      else if criteria == 'true' || criteria == 'false'
        criteria
      else if _.contains criteria, ' '
        # split by space, remove empties & stringify
        JSON.stringify _.filter(criteria.split(' '), Boolean)
      else
        criteria

  # watch is either `true` or `false`
    watch: (criteria) ->
      if criteria
        'true'
      else
        'false'

  register = (modelName, modelId) ->
    if !Sails.Models[modelName]
      Sails.Models[modelName] = _.extend {}, Backbone.Events

      Sails.Models[modelName].handler = (e) ->
        if e.verb == 'created' # collection
          Sails.Models[modelName].trigger e.verb, e
        else if Sails.Models[modelName][e.id] # model
          Sails.Models[modelName][e.id].trigger e.verb, e

      socketConnecting().done ->
        socketClient.on modelName, Sails.Models[modelName].handler

    if modelId?
      if !Sails.Models[modelName][modelId]
        Sails.Models[modelName][modelId] = _.extend {}, Backbone.Events

  wrapError = (instance, options) ->
    error = options.error
    options.error = (resp, options = options) ->
      if error
        error instance, resp, options
      instance.trigger 'error', instance, resp, options

  wrapPayload = (payload, options)->
    _.assign options,
      contentType: 'application/json'
      data: JSON.stringify(payload)
      payload: _.cloneDeep payload

  attemptRequest = (method, instance, options)->

    sync = getConfig 'sync', options, instance

    socketSync  = _.contains sync, 'socket'
    ajaxSync    = _.contains sync, 'ajax'
    subscribe   = _.contains sync, 'subscribe'
    set         = _.contains sync, 'set'

    opts = options
    options = _.cloneDeep opts

    if socketSync && socketConnected()
      # if socket available, go for it
      options.sync = "socket"
      result = sendingSocketRequest method, instance, options

    else if ajaxSync || method == 'delete'
      # else delegate to ajax
      options.sync = "ajax"
      result = sendingAjaxRequest method, instance, options

      if socketSync && method != 'delete' && subscribe
        # store populate configuration at time of ajaxRequest
        populateConfig = _.cloneDeep getConfig('populate', options, instance)

        # server-subscribe the instances fetched only
        result.done ->
          options = _.cloneDeep(opts)
          options.method = 'GET'
          options.sync = "subscribe"

          if set
            options.success = (resp)->
              # collection's `parse` is called from `set` for some reason...
              if isModel instance then resp = instance.parse(resp, options)
              if !instance.set resp, options
                return false
              instance.trigger 'sync', instance, resp, options
          else
            options.success = -> # if no set, then success is a no-op

              # rebind error to this contexts options object
          options.error = _.partialRight options.error, options

          if isCollection instance
            # store the id's fetched
            idAttr = instance.model.prototype.idAttribute
            ids = _.pluck instance.models, idAttr

            # nullify any other filter criteria (apart from populate)
            options.sort = false
            options.populate = populateConfig
            options.skip = false
            options.limit = false
            (options.where = {})[idAttr] = ids # set where to filter by the id's returned

          sendingSocketRequest method, instance, options
    else
      # else wait for socket connect by default
      options.sync = "socket"
      result = sendingSocketRequest method, instance, options

    result

  # utility method for model and collection
  configure = (key, val) ->
    # instance level config
    if _.isString key
      @[keys.configPrefix + key] = val
    else
      for k, v of key
        @[keys.configPrefix + k] = v
    @

  class Sails.Model extends Backbone.Model

    query: configure
    configure: configure
    populate: _.partial configure, 'populate'

    get: (key, wrap) ->
      if wrap && @assoc?[key]?
        attr = super
        if attr?
          new @assoc[key](attr)
        else
          attr
      else
        super

    set: (key, val, options) ->
      if _.isObject key
        for k, v of key
          if isModel(v)
            key[k] = v.attributes
          else if isCollection(v)
            key[k] = _.pluck v.models, 'attributes'
          else if _.isFunction(v)
            key[k] = v(@get(k))
      else
        if isModel(val)
          val = val.attributes
        else if isCollection(val)
          val = _.pluck val.models, 'attributes'
        else if _.isFunction(val)
          val = val(@get(key))
      super key, val, options

    message: (action, data = {}, options = {}, internal) ->
      if @isNew()
        idError()

      if _.isObject action
        options = data
        data = action
      else
        data[keys.messageAction] = action

      options.url = "#{Sails.config.prefix}/#{getModelName(@)}/message/#{@id}"
      options.sync = ['socket', 'ajax'] # no subscription - just get it done

      message = new FakeModel data
      promise.wrap message.save({}, options), internal # post a message

    addTo: (key, model, options = {}, internal)->
      if @isNew()
        idError()

      if !@assoc[key]?
        associationError(key)

      if isModelConstructor @assoc[key]
        throw new Error "Cannot `addTo` model associations, only collections."

      if !isModel model
        Model = @assoc[key].prototype.model
        if _.isString model
          id = model
          model = new Model()
          model.set(model.idAttribute, id)
        else if _.isObject(model)
          model = new Model model
        else
          throw new Error "Parameter `model` invalid. Should be an object of attributes, a model instance or an id string."

      if model.isNew()
        payload = model.attributes
        options.url = _.result(@, 'url') + "/#{key}"
      else
        payload = _.assign {}, model.attributes, { id: model.id }
        options.url = _.result(@, 'url') + "/#{key}/#{model.id}"

      options.method = 'POST'
      wrapPayload payload, options # sails should pick up id parameter

      result = @save({}, options, null, true)

      if model.isNew()
        result.done (resp, status, xhr)->
          # simulate a save on the new added instance
          json = getHeader(xhr, 'created')
          resp = JSON.parse(json)
          model.set(model.parse(resp, options))
          model.trigger 'sync', model, resp, options

      promise.wrap result, internal

    removeFrom: (key, model, options = {}, internal) ->
      if @isNew()
        idError()

      if !@assoc[key]?
        associationError(key)

      if isModelConstructor @assoc[key]
        throw new Error "Cannot `removeFrom` model associations, only collections."

      if !isModel model
        Model = @assoc[key].prototype.model
        if _.isString model
          id = model
          model = new Model()
          model.set(model.idAttribute, id)
        else if _.isObject(model)
          model = new Model model
        else
          throw new Error "Parameter `model` invalid. Should be an object of attributes, a model instance or an id string."

      if model.isNew()
        idError() # no id to remove with

      # todo - only the id is necessary, trim down packet data with testing
      payload = _.assign {}, model.attributes, { id: model.id }
      wrapPayload payload, options # sails should pick up id parameter

      options.method = 'DELETE'
      options.url = _.result(@, 'url') + "/#{key}/#{model.id}"

      promise.wrap @save({}, options, null, true), internal

    destroy: (options, internal) ->
      # from backbone
      if options
        options = _.cloneDeep(options)
      else
        options = {}

      model = this;
      success = options.success;

      destroy = ->
        model.trigger 'destroy', model, model.collection, options

      options.success = (resp) ->
        if (options.wait || model.isNew()) then destroy()
        if (success) then success(model, resp, options);
        if (!model.isNew()) then model.trigger('sync', model, resp, options)

      if (this.isNew())
        options.success()
        return false

      wrapError(this, options);

      result = attemptRequest 'delete', model, options

      if (!options.wait) then destroy()

      promise.wrap result, internal

    save: (key, val, options, internal) ->
      # from backbone
      attributes = @attributes
      if !key? || _.isObject key
        attrs = key
        options = val
      else if _.isString key
        (attrs = {})[key] = val

      options = _.extend {validate: true}, options

      if attrs && !options.wait
        if !this.set(attrs, options) then return false
      else
        if !this._validate(attrs, options) then return false

      if attrs && options.wait
        @attributes = _.extend {}, attributes, attrs

      if _.isUndefined(options.parse) then options.parse = true

      model = this;
      success = options.success;

      options.success = (resp) ->
        model.attributes = attributes
        serverAttrs = model.parse resp, options

        if options.wait
          serverAttrs = _.extend((attrs || {}), serverAttrs)
        if _.isObject(serverAttrs) && !model.set(serverAttrs, options)
          return false

        success? model, resp, options
        model.trigger 'sync', model, resp, options

      wrapError this, options

      method = if @isNew()
        'create'
      else if options.patch
        'patch'
      else
        'update'
      if method == 'patch' then options.attrs = attrs

      result = attemptRequest method, model, options

      if attrs && options.wait then @attributes = attributes

      promise.wrap result, internal

    fetch: (key, options, internal) ->

      if _.isString(key)
        if !@assoc[key]?
          associationError key

        else
          defer = $.Deferred()
          instance = new (@assoc[key])(@get(key))#, options)
          opts = (options && _.cloneDeep(options)) || {}
          opts.populate = false
          opts.url = @url() + "/#{key}"
          if instance.isNew?() == false then opts.url += "/#{instance.id}"
          instance.fetch(opts, true).done (resp, status, xhr)->
            defer.resolve(instance, resp, status, xhr)
          .fail (xhr, status, resp)->
            defer.reject(instance, xhr, status, resp)
          promise.wrap defer, internal
      else
        options = key
        internal = options

        # from backbone
        options = if options then _.cloneDeep(options) else {}

        if (!options.parse)
          options.parse = true

        model = this
        success = options.success

        options.success = (resp) ->
          if !model.set model.parse(resp, options), options
            return false
          if success
            success model, resp, options
          model.trigger 'sync', model, resp, options

        wrapError(this, options)

        result = attemptRequest 'read', model, options

        promise.wrap result, internal

    subscribe: ->
      if @isNew()
        self = @
        @once "change:#{@idAttribute}", -> self.subscribe()
        return false

      if @subscribed
        return true

      @subscribed = true

      modelName = getModelName @

      # first register
      register modelName, @id

      # then listen
      prefix = Sails.config.eventPrefix
      aggregator = Sails.Models[modelName][@id]

      @listenTo aggregator, "addedTo", (e)->
        @trigger "#{prefix}addedTo", @, e
        @trigger "#{prefix}addedTo:#{e.attribute}", @, e.addedId, e

      @listenTo aggregator, "removedFrom", (e)->
        @trigger "#{prefix}removedFrom", @, e
        @trigger "#{prefix}removedFrom:#{e.attribute}", @, e.removedId, e

      @listenTo aggregator, "destroyed", (e)->
        @trigger "#{prefix}destroyed", @, e

      @listenTo aggregator, "updated", (e)->
        changed = false
        for attribute, val of e.data
          if @get(attribute) != val
            @trigger "#{prefix}updated:#{attribute}", @, val, e
            changed = true
        if changed
          @trigger "#{prefix}updated", @, e

      @listenTo aggregator, "messaged", (e)->
        data = _.cloneDeep e.data
        action = e.data[keys.messageAction]
        if !action?
          @trigger "#{prefix}messaged", @, data, e
        else
          delete data[keys.messageAction]
          @trigger "#{prefix}#{action}", @, data, e

      return true

    constructor: (attrs, options)->
      super

      if !@modelName?
        if !(@modelName = @collection?.modelName)?
          modelNameError()

      @urlRoot = -> "#{Sails.config.prefix}/#{getModelName(@)}"

      # subscribe on create
      @subscribe()

      # copy instance config options
      if options?
        for key in keys.modelConfig
          if options[key]?
            @[keys.configPrefix + key] = options[key]

      # set up associations
      if @assoc? && !@assoc.__parsed
        for key, val of @assoc
          if _.isString val
            @assoc[key] = Sails.Model.extend( modelName: val )
          else if _.isArray val
            @assoc[key] = Sails.Collection.extend( modelName: val[0], model: Sails.Model.extend( modelName: val[0] ) )
          else # assumed function
            if @assoc[key].length == 0
              # no args expected, result of function should be a constructor
              @assoc[key] = @assoc[key]()
        # else already a constructor, no need to change

        @assoc.__parsed = true

  class FakeModel extends Sails.Model
    modelName: '__fake'

  class Sails.Collection extends Backbone.Collection

    query: configure
    configure: configure
    populate: _.partial configure, 'populate'

    model: Sails.Model

    message: (namespace, data, options, internal) ->
      coll = this
      url = "#{Sails.config.prefix}/#{getModelName(@)}/message"

      if _.isObject namespace
        # no name space specified, will fire 'messaged' events
        options = data
        data = namespace
      else
        # namespace is string, add to data
        data[keys.messageAction] = namespace

      options.sync = ['socket', 'ajax'] # don't subscribe, just get the message sent
      options.url = url

      wrapPayload data, options

      request = new FakeCollection()

      state = getConfig 'state', options, coll

      # message models on server
      if state == 'server'
        for key in keys.collectionQuery
          options[key] = getConfig key, options, @

        # message models in collection
      else # state == 'client'
        for key in keys.collectionQuery
          options[key] = false

        options.where = {} # send id's down as where clause
        idAttr = coll.at(0)?.idAttribute || 'id'
        options.where[idAttr] = []
        for model in coll.models
          if !model.isNew() # only message persisted models
            options.where[idAttr].push model.id
          else if Sails.config.log
            console.warn "Model has no `#{idAttr}`, so will not be messaged."

      result = request.fetch options, true

      promise.wrap result, internal

    fetch: (options, internal) ->
      options = if options then _.cloneDeep options else {}

      if !options.parse? then options.parse = true

      success = options.success
      collection = this

      options.success = (resp) ->
        method = if options.reset then 'reset' else 'set'
        collection[method](resp, options)

        if (success) then success collection, resp, options
        collection.trigger 'sync', collection, resp, options

      wrapError(@, options);

      result = attemptRequest 'read', collection, options

      promise.wrap result, internal

    subscribe: ->
      if @subscribed
        return

      @subscribed = true

      modelName = getModelName(@)

      # first register
      register modelName

      # then listen
      prefix = Sails.config.eventPrefix
      aggregator = Sails.Models[modelName]

      @listenTo aggregator, "created", (e) ->
        @trigger "#{prefix}created", e.data, e

    constructor: (models, options)->
      if !@modelName?
        modelNameError()

      @url = -> "#{Sails.config.prefix}/#{getModelName(@)}"

      # subscribe on create
      @subscribe()

      # copy instance config options
      if options?
        for key in keys.collectionConfig
          if options[key]?
            @[keys.configPrefix + key] = options[key]

      super

  class FakeCollection extends Sails.Collection
    modelName: '__fake__'

  Backbone.Sails = Sails

)(Backbone, $, _)