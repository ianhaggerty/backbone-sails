###
  file: backbone.sails.coffee
  libary: Backbone.Sails

  copyright: Ian Haggerty
  author: Ian Haggerty
  email: iahag001@yahoo.co.uk
  github: https://github.com/iahag001/Backbone.Sails

  dependencies: [
    Backbone: https://github.com/jashkenas/backbone
    jQuery: https://github.com/jquery/jquery
    underscore: https://github.com/lodash/lodash/
    sails.io.js: https://github.com/balderdashy/sails.io.js
  ]
###


((Backbone, $, _)->

# Global Backbone.Sails object extends Backbone.Events
	Sails = _.extend {}, Backbone.Events

	# Event aggregators for 'model' resources will be populated here as they come in.
	# e.g. model({ urlRoot: "/users", id: "1" }) will, upon subscription, register an
	# event aggregator at Backbone.Sails.Models.users[1]
	Sails.Models = {}

	# Event aggregators for 'collection' resources will be populated here as they come in
	# e.g. coll({ url: "/users" }) will, upon subscription, register an evbent aggregator
	# at Backbone.Sails.Collections.users.
	Sails.Collections = {}

	# Event aggregators act to forward events from the socket, making using of the 'event identity'
	# (the respective model name) to the aggregator. Models and collection then `listenTo` that
	# aggregator for events.

	# Helper function for setting up configuration
	Sails.configure = (config) ->
		_.assign Sails.config.query, parseQueryObj config.query
		delete config.query

		if config.eventPrefix?
			if _.last config.eventPrefix != ':'
				config.eventPrefix += ':'

		_.assign Sails.config, config

# Configuration object
	Sails.config =

		eventPrefix: ""

		timeout: (defer) ->
			if !defer.attempts
				defer.attempts = 1
			else
				defer.attempts += 1

			if defer.attempts <= 5
				return 150
			else if defer.attempts <= 10
				return 500
			else if defer.attempts <= 50
				return 1000
			else if defer.attempts <= 100
				return 4000
			else
				return false

		query:
			where: ''
			limit: 30
			sort: ''
			skip: 0

	# If defined, this should be a function which attempts to acquire the socket client
	# from sails.io.js and return's it. It will be invoked as part of the application
	# in the networking 
		findSocketClient: ->

	# If defined, this should be a function which attempts to (re-) acquire a connnection
	# to a socket client instance. It will be passed the socket client as a first
	# argument. No return necessary.
		connectToSocket: (socketClient)->

	# A boolean indicating whether to subscribe instances synced over jqXHR, when available
		subscribe: true

	# A boolean indicating whether to send all requests over web sockets.
		socketSync: false

# Generic function used to ascertian whether the the number of attempts for this particular
# promise has exceeded. Used frequently in the 'looping defer pattern'.
	maxAttemptsExceeded = (defer) ->
		defer.attempts = if defer.attempts then defer.attempts + 1 else 1
		maxAttempts = Sails.config.attempts
		if _.isUndefined maxAttempts
			return false
		if defer.attempts <= maxAttempts
			return false
		return true
# Utility method to map the result of one promise onto another
	chainPromise = (from, to) ->
		from.done ->
			to.resolve.apply to, arguments
		.fail ->
			to.reject.apply to, arguments

# References the socket client, when it is found. The socket client is typically
# located at the io.socket global exposed by sails.io.js.
	socketClient = undefined

# Logic to attempt to find the socket
	findSocketClient = ->
		
		if io.socket && io.socket.socket
			socketClient = io.socket
			
		else
			socketClient = Sails.config.findSocketClient()

# Conditional logic to determine if the socket client has been found
	socketClientFound = ->
		socketClient && socketClient.socket

# Promises the socket client is available
	findingSocketClient = (defer = $.Deferred())->
		if socketClientFound()
			defer.resolve()

		else
			findSocketClient()

			if socketClientFound()
				defer.resolve()

			else
				delay = Sails.config.timeout defer
				if delay
					setTimeout ->
						findingSocketClient(defer)
					, delay

		defer.promise()

# Logic to attempt connect/reconnect to socket
	connectSocket = ->
		Sails.config.connectToSocket(socketClient)

# Conditional logic to determine whether the socketClient has connected
	socketConnected = ->
		socketClient?.socket?.connected

# Promises the socket is connected
	socketConnecting = (defer = $.Deferred())->
		# socket client must be available before attempting connect
		findingSocketClient().done ->
			if socketConnected()
				defer.resolve()

			else
				connectSocket()

				if socketConnected()
					defer.resolve()

				else
					if maxAttemptsExceeded defer
						defer.reject()
						
					else
						to = undefined

						# register a listener for a 'connect' event to resolve more immediately
						connectHandler = ->
							clearTimeout to
							socketConnecting(defer)

						socketClient.once "connect", connectHandler

						delay = Sails.config.timeout defer
						if delay
							# start polling for a connected status
							to = setTimeout ->
								_.remove socketClient.$events.connect, (h) -> h == connectHandler
								socketConnecting(defer)
							, delay

		defer.promise()

# Forward 'connect' and 'disconnect' events to Backbone.Sails
	findingSocketClient().done ->
		socketClient.on "connect", ->
			Sails.trigger "connect", arguments
		socketClient.on "disconnect", ->
			Sails.trigger "disconnect", arguments

# Throws a url related error
	urlError = ->
		throw new Error 'A "url" property or function must be specified'

# Throws an id related error
	idError = ->
		throw new Error 'An "id" property could not be found for a model'

# Used to map from Backbone to sails.io.js methods
	methodMap =
		create: 'post'
		read: 'get'
		update: 'put'
		patch: 'put'
		delete: 'delete'

# Simulates a jqXHR request through websockets
	sendSocketRequest = (method, instance, options) ->

		defer = new $.Deferred()

		prefix = Sails.config.eventPrefix

		url = options.url || _.result instance, 'url' || urlError

		if isCollection instance
			payload = undefined # all info in filter query parameters
		else
			payload = instance.attributes


		socketClient[methodMap[method]] url, payload, (res, jwres)->
			if res.error || jwres.statusCode != 200

				options.error? jwres, jwres.statusCode, jwres.body # triggers 'error'

				instance.trigger "#{prefix}socketError", jwres, jwres.statusCode, jwres.body

				defer.reject jwres, jwres.statusCode, jwres.body
			else
				options.success? res, jwres.statusCode, jwres # triggers 'sync'

				instance.trigger "#{prefix}socketSync", instance, res, options

				defer.resolve res, jwres.statusCode, jwres

				# register & subscribe instances
				if isCollection instance
					registeringCollection(instance).done ->
						subscribingCollection(instance)

					for model in instance.models
						registeringModel(model).done ->
							subscribingModel(model)

				else
					registeringModel(instance).done ->
						subscribingModel(instance)


		instance.trigger "request", instance, defer.promise(), options
		instance.trigger "#{prefix}socketRequest", instance, defer.promise(), options

		defer.promise()

# Promises a simulated jqXHR socket request
	sendingSocketRequest = (method, instance, options) ->
		result = $.Deferred()
		
		# check for connection
		socketConnecting().done ->
			
			# augment url before sync (add's filter queries)
			previousUrl = augmentUrl method, instance
			
			# map from backbone verbs to sails.io.js verbs
			chainPromise sendSocketRequest(method, instance, options), result

			# restore the original url immediately
			instance.url = previousUrl

		result

# Promises a request over jqXHR, this delegates to Backbone.sync
	sendingAjaxRequest = (method, instance, options)->
		
		# augment url as required
		previousUrl = augmentUrl method, instance

		# sync
		result = instance.sync method, instance, options

		# restore url immediately
		instance.url = previousUrl

		result

	parseQuery =
		where: (criteria) ->
			if _.isObject criteria
				JSON.stringify criteria
			else if _.isString criteria
				criteria
			else
				throw new Error "query.where expects a string or an object"
		sort: (criteria) ->
			if _.isObject criteria
				JSON.stringify criteria
			else if _.isString criteria
				criteria
			else
				throw new Error "query.sort expects a string or an object"
		limit: (criteria) ->
			if _.isNumber criteria
				criteria
			else
				throw new Error "query.limit expects a number"
		skip: (criteria) ->
			if _.isNumber criteria
				criteria
			else
				throw new Error "Backbone.Sails: skip expects a number"
		populate: (criteria) ->
			args = _(arguments)
			if args.length > 1
				args.join ','
			else if _.isArray criteria
				criteria.join ','
			else if _.isString criteria
				criteria
			else
				throw new Error "query.populate expects a string"

	parseQueryObj = (query) ->
		for key, val of query
			query[key] = parseQuery[key] val
		query

# Returns the query string for an instance
	queryString = (instance) ->
		queries = []

		query = _.defaults {}, instance._sails.query, Sails.config.query

		for key, val of query
			queries.push "#{key}=#{val}"

		"?" + queries.join("&")

# Augments the url for sync requests - according to the instance type
	augmentUrl = (method, instance, options) ->
		# previousUrl = _.result instance, 'url'

		previousUrl = instance.url

		if method == "read"
			url = _.result instance, 'url'

			url += queryString instance

			instance.url = url

		# return the previous url
		previousUrl

# Promises resolving a request through the socket
	resolvingRequest = (request, defer = $.Deferred())->

		request = sendingSocketRequest request.method, request.instance, request.options

		request.done ->
			defer.resolve()

		request.fail ->
			if maxAttemptsExceeded defer
				defer.reject()

			else
				delay = Sails.config.timeout defer
				if delay
					setTimeout ->
						resolvingRequest(request, defer)
					, delay

		defer.promise()

# Returns the 'model name' for a model or collection. This is assumed to be the first set of
# characters between the leading slash on a url and the second slash or question mark.
# e.g.
# '/user/' has modelname 'user'
# '/tags/1' has modelname 'tags'
# '/user?sort=name ASC' has model name 'user'
# This model name is used as the *event identity* for resourceful pub/sub events on the server side
# It is utterly critical this correct - in line with the sails conventions.
# See http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub
	getModelName = (instance) ->
		if instance._sails.modelName
			return instance._sails.modelName

		url = _.result(instance, 'url')

		if !url
			urlError()

		instance._sails.modelName = _.remove(url.split('/'), (c)->c)[0].split('?')[0]

# Tests whether an instance is a collection
	isCollection = (instance) ->
		instance instanceof Backbone.Collection

# Test whether an instance is a model
	isModel = (instance) ->
		instance instanceof Backbone.Model

# Tests whether instance is a Backbone.Sails.Collection or a Backbone.Sails.Model
	isSails = (instance) ->
		instance._sails

# Forwards the socket event e to the aggregator specified
	forwardSocketEvent = (e, aggregator) ->
		aggregator.trigger "#{e.verb}", e

# Register's an event aggregator for a collection instance, if necessary
	registerCollection = (coll)->
		
		modelName = getModelName coll
		collections = Sails.Collections

		# set up modelname namespace if not exist
		# register a socket-collection handler for this modelname
		if  !collections[modelName]
			
			collections[modelName] = _.extend {}, Backbone.Events

			# keep reference to handler
			collections[modelName]._sails =
				handler: (e) ->
					forwardSocketEvent(e, collections[modelName])

			socketClient.on modelName, collections[modelName]._sails.handler

			# Tell Backbone.Sails this collection has been registered
			Backbone.Sails.trigger "registered:collection", modelName, collections[modelName]

		coll._sails.registered = true

# Conditional logic indicating this collection has been registered
# Note: 'collection' in this context refer's to an individual collection resource
# on the server side, NOT an individual collection object
	collectionRegistered = (coll) ->
		if coll._sails.registered
			return true

		modelName = getModelName coll

		coll && modelName &&
		(handler = Sails.Collections[modelName]?._sails?.handler) &&
		(handlers = socketClient.$events[modelName]) &&
		(if _.isArray(handlers) then _.contains handlers, handler else handler == handlers) &&

		# if we got all the way here, the collection was registered through another object
		(coll._sails.registered = true)

# Promises registering a collection resource
	registeringCollection = (coll, defer = $.Deferred())->

		if collectionRegistered(coll)
			defer.resolve()
		else
			socketConnecting().done ->
				registerCollection(coll)
				defer.resolve()

		defer.promise()

# Register's an event aggregator for a model resource, if necessary
	registerModel = (model) ->
		
		if _.isUndefined model.id # not yet synced, cannot register without id
			idError()

		modelName = getModelName model
		models = Sails.Models

	# set up modelname namespace if not exist
		if !models[modelName]
			
			models[modelName] = {}

	# register a socket-model handler if not exist
		if !models[modelName]._sails?.handler
			
			# keep reference to handler
			models[modelName]._sails =
				handler: (e) ->
					if models[modelName][e.id]
						forwardSocketEvent(e, models[modelName][e.id])


			socketClient.on modelName, models[modelName]._sails.handler

			Backbone.Sails.trigger "registered:model", modelName, models[modelName]

		model._sails.registered = true

# Conditional logic to indicate whether a model has been registered
# Note: 'model' in this context refer's to an individual model resource
# on the server side, NOT an individual model object
	modelRegistered = (model)->
		if model._sails.registered
			return true

		modelName = getModelName model

		model && model.id && modelName &&
		Sails.Models[modelName]?[model.id]? &&
		(handler = Sails.Models[modelName]._sails?.handler) &&
		(handlers = socketClient.$events[modelName]) &&
		(if _.isArray(handlers) then _.contains handlers, handler else handler == handlers) &&

		# if we got all the way here, the model was registered through another object
		(model._sails.registered = true)

# Promises registering an event aggregator for a model
	registeringModel = (model, defer = $.Deferred())->

		if modelRegistered(model)
			defer.resolve()
		else
			socketConnecting().done ->
				registerModel(model)
				defer.resolve()

		defer.promise()

# Conditional logic indicating the collection has been subscribed
	collectionSubscribed = (coll)->
		if coll._sails.subscribed
			return true

		coll._listeningTo &&
			_.toArray(coll._listeningTo).indexOf(Sails.Collections[getModelName(coll)]) != -1 &&
		(coll._sails.subscribed = true)

# Promises subscribing a collection to it's relevant aggregator
	subscribingCollection = (coll) ->
		
		defer = $.Deferred()

		if collectionSubscribed(coll)
			defer.resolve()

		else
			registeringCollection(coll).done ->
				modelName = getModelName(coll)
				aggregator = Sails.Collections[modelName]
				prefix = Sails.config.eventPrefix

				coll.listenTo aggregator, "created", (e) ->
					coll.trigger "#{prefix}created", e.data, e

				coll.trigger "#{Sails.config.eventPrefix}subscribed", coll, modelName
				coll._sails.subscribed = true
				defer.resolve()
		defer.promise()

# Conditional logic indicating the model has been subscribed
	modelSubscribed = (model)->
		if model._sails.subscribed
			return true

		model._listeningTo &&
		_.toArray(model._listeningTo).indexOf(Sails.Models[getModelName(model)][model.id]) != -1 && (model._sails.subscribed = true)

# Promises a subscribing a model to it's relevant aggregator
	subscribingModel = (model) ->

		defer = $.Deferred()

		if modelSubscribed(model)
			defer.resolve()

		else
			registeringModel(model).done ->
				models = Sails.Models
				modelName = getModelName(model)

				# create an aggregator for this specific model instance
				if !models[modelName][model.id]
					models[modelName][model.id] = _.extend {}, Backbone.Events

				aggregator = models[modelName][model.id]
				prefix = Sails.config.eventPrefix

				model.listenTo aggregator, "addedTo", (e)->
					model.trigger "#{prefix}addedTo", model, e
					model.trigger "#{prefix}addedTo:#{e.attribute}", model, e.addedId, e

				model.listenTo aggregator, "removedFrom", (e)->
					model.trigger "#{prefix}removedFrom", model, e
					model.trigger "#{prefix}removedFrom:#{e.attribute}", model, e.removedId, e

				model.listenTo aggregator, "destroyed", (e)->
					model.trigger "#{prefix}destroyed", model, e

				model.listenTo aggregator, "updated", (e)->
					# do some dirty checking
					changed = false
					for attribute, val of e.data
						if model.get(attribute) != val
							model.trigger "#{prefix}updated:#{attribute}", model, val, e
							changed = true
					if changed
						model.trigger "#{prefix}updated", model, e

				model.listenTo aggregator, "messaged", (e)->
					model.trigger "#{prefix}messaged", model, e

				model.trigger "#{Sails.config.eventPrefix}subscribed", model, modelName
				model._sails.subscribed = true
				defer.resolve()

		defer.promise()

# from Backbone
	wrapError = (instance, options) ->
		error = options.error
		options.error = (resp) ->
			if error
				error instance, resp, options
				instance.trigger 'error', instance, resp, options

# Used internally from model and collection class to attempt a request
# over sockets, delegating to jqXHR and resyncing over sockets as
# configured through `socketSync` and `subscribe`
	attemptRequest = (request)->
		method =          request.method
		instance =        request.instance
		options =         request.options
		delegateSuccess = request.delegateSuccess

		socketSync =
			if !_.isUndefined request.instance._sails.socketSync then request.instance._sails.socketSync
			else if !_.isUndefined request.options?.socketSync then request.options.socketSync
			else Sails.config.socketSync

		if socketConnected()
			# send over sockets
			result = sendingSocketRequest method, instance, options
		else if !socketSync
			# delegate to jqXHR
			result = sendingAjaxRequest method, instance, options
			.done ->
				subscribe =
					if !_.isUndefined request.instance._sails.subscribe then request.instance._sails.subscribe
					else if !_.isUndefined request.options?.subscribe then request.options.subscribe
					else Sails.config.subscribe

				# queue up a read socket request to subscribe the model server side
				if subscribe
					options = _.clone(options)

					options.success = delegateSuccess

				resolvingRequest
					method: 'read'
					instance: instance
					options: options

		else
			# wait for socket connect
			result = $.Deferred()
			socketConnecting().done ->
				chainPromise sendingSocketRequest(method, instance, options), result

		result

# $.ajax expects the model resource to be located by id in url
# however delete requests to associations require an id parameter
# in the body, this function wraps the options to do just that
	wrapDelete = (model, options)->
		payload = {}
		payload[model.idAttribute || "id"] = model.id
		_.assign options,
			# necessary for Ajax delegation
			contentType: 'application/json'
			data: JSON.stringify(payload)

# The all important Model class
	class Sails.Model extends Backbone.Model

		# 'adds to' an association collection
		addTo: (key, model, options)->
			if !isModel model
				model = new Backbone.Model model

			options = _.assign {}, options, { url: _.result(@, 'url') + '/' + key }

			if model.isNew()
				result = model.save {}, options
				if options.update
					that = @
					result.done ->
						if _.isArray that.attributes[key]
							that.attributes[key].push model.attributes
						else
							that.attributes[key] = [model.attributes]
						that.trigger "change", that, options
						that.trigger "change:#{key}", that, that.attributes[key], options
			else
				result = (new $.Deferred()).reject("model is not new, cannot 'add to'").promise()
			result

		# 'removes from' an association collection
		removeFrom: (key, model, options = {})->
			if !isModel model
				model = new Backbone.Model model

			options = _.assign {}, options, { url: _.result(@, 'url') + '/' + key }

			idAttribute = options.idAttribute || "id"

			wrapDelete model, options

			result = undefined
			if !model.isNew()
				result = model.destroy options
				if options.update
					that = @
					result.done ->
						if _.isArray (that.attributes[key])
							changed = undefined
							_.remove that.attributes[key], (m) ->
								if m[idAttribute] ==  model[idAttribute]
									changed = true
									true
								else
									false
							if changed
								that.trigger "change", that, options
								that.trigger "change:#{key}", that, that.attributes[key], options
			else
				result = (new $.Deferred()).reject("model is new, cannot 'remove from'").promise()

			result

		subscribe: ->
			subscribingModel @

		fetch: (options) ->
			options = if options then _.clone(options) else {}

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

			delegateSuccess = (resp) ->
				if !model.set model.parse(resp, options), options
					return false
				model.trigger 'sync', model, resp, options

			attemptRequest
				method: 'read'
				instance: model
				options: options
				delegateSuccess: delegateSuccess

		save: (key, val, options) ->
			attributes = @attributes
			if key == null || typeof key == 'object'
				attrs = key
				options = val
			else
				(attrs = {})[key] = val

			options = _.extend {validate: true}, options

			# If we're not waiting and attributes exist, save acts as
			# `set(attr).save(null, opts)` with validation. Otherwise,
			# check if the model will be valid when the attributes, if
			# any, are set.
			if attrs && !options.wait
				if !this.set(attrs, options) then return false
			else
				if !this._validate(attrs, options) then return false

			# Set temporary attributes if `{wait: true}`
			if attrs && options.wait
				@attributes = _.extend {}, attributes, attrs

			# After a successful server-side save, the client is (optionally)
			# updated with the server-side state.
			if _.isUndefined options.parse then options.parse = true
			model = this;
			success = options.success;
			options.success = (resp) ->
				# ensure the attributes are restored during synchronous saves
				model.attributes = attributes
				serverAttrs = model.parse resp, options
				if options.wait then serverAttrs = _.extend attrs || {}, serverAttrs
				if _.isObject serverAttrs && !model.set serverAttrs, options
					return false
				success? model, resp, options
				model.trigger 'sync', model, resp, options

			wrapError this, options

			method = if @isNew() then 'create' else (if options.patch then 'patch' else 'update')
			if method == 'patch' then options.attrs = attrs

			delegateSuccess = (resp) ->
				# same as above, but no callback to user supplied 'success'
				model.attributes = attributes
				serverAttrs = model.parse resp, options
				if options.wait then serverAttrs = _.extend attrs || {}, serverAttrs
				if _.isObject serverAttrs && !model.set serverAttrs, options
					return false
				model.trigger 'sync', model, resp, options

			result = attemptRequest
				method: method
				instance: model
				options: options
				delegateSuccess: delegateSuccess

			# restore attributes
			if attrs && options.wait then @attributes = attributes

			result

	# Destroy this model on the server if it was already persisted.
	#	Optimistically removes the model from its collection, if it has one.
	#	If `wait: true` is passed, waits for the server to respond before removal.
		destroy: (options) ->
			options = if options then _.clone(options) else {}
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

			# don't subscribe
			options.subscribe = false

			result = attemptRequest
				method: 'delete'
				instance: this
				options: options

			if (!options.wait) then destroy()

			return result

		query: (criteria) ->
			model = this
			if criteria
				model._sails.query = parseQueryObj criteria
				return

			api =
				populate: (criteria) ->
					model._sails.query.populate = parseQuery.populate.apply {}, arguments
					api
			api

		constructor: (attrs, options)->
			super

			@_sails =
				subscribed: false
				registered: false
				query: {}

			if options
				if !_.isUndefined options.socketSync
					@_sails.socketSync = options.socketSync
				if !_.isUndefined options.subscribe
					@_sails.subscribe = options.subscribe

# The all important collection class
	class Sails.Collection extends Backbone.Collection

		fetch: (options) ->
			options = if options then _.clone(options) else {}
			if _.isUndefined options.parse then options.parse = true
			success = options.success
			collection = this

			options.success = (resp) ->
				method = if options.reset then 'reset' else 'set'
				collection[method](resp, options)

				if (success) then success collection, resp, options
				collection.trigger 'sync', collection, resp, options

			wrapError(@, options);

			delegateSuccess = (resp) ->
				collection.set(resp, options)
				collection.trigger 'sync', collection, resp, options

			attemptRequest
				method: 'read'
				instance: this
				options: options
				delegateSuccess: delegateSuccess

		subscribe: ->
			subscribingCollection @

		query: (criteria) ->
			coll = this
			if criteria
				coll._sails.query = parseQueryObj criteria

			api =
				where: (criteria) ->
					coll._sails.query.where = parseQuery.where criteria
					api

				skip: (criteria) ->
					coll._sails.query.skip = parseQuery.skip criteria
					api

				sort: (criteria) ->
					coll._sails.query.sort = parseQuery.sort criteria
					api

				limit: (criteria) ->
					coll._sails.query.limit = parseQuery.limit criteria
					api

				populate: () ->
					coll._sails.query.populate = parseQuery.populate.apply {}, arguments
					api

				paginate: (page, limit) ->
					api.skip page * limit
					api.limit limit
					api
			api

		model: Sails.Model

		constructor: (models, options)->
			super

			@_sails =
				subscribed: false
				registered: false
				query: {}

			if options
				if !_.isUndefined options.socketSync
					@_sails.socketSync = options.socketSync
				if !_.isUndefined options.subscribe
					@_sails.subscribe = options.subscribe

# A very special function. This wraps an existing Collection constructor
# and returns a corresponding 'associated' collection constructor. The
# associated collection is constructed with a model instance and a key.
# POST, DELETES and GETS all then go to the backend via the associated
# collection resource. PUT goes to the associated model resource.
	Sails.associated = (Collection)->
		PUT = Collection.prototype.url

		class AssociatedModel extends Collection.prototype.model
			save: (key, val, options)->
				if @isNew() # POST /model/id/assoc
					super
				else
					url = PUT + '/' + @id
					# glue code from backbone
					if _.isNull key || _.isObject key
						options = _.assign {}, val, { url: url }
						super key, options
					else
						options = _.assign {}, options, { url: url }
						# PUT /associatedmodel/associd
						super key, val, options

			destroy: (options= {}) ->
				# DELETE to /model/id/assoc
				wrapDelete @, options
				super options

		class AssociatedCollection extends Collection
			model: AssociatedModel

			constructor: (key, model, options) ->
				@url = _.result(model, 'url') + '/' + key

				# forward addedTo and removedFrom events
				prefix = Sails.config.eventPrefix
				model.on "#{prefix}addedTo:#{key}", ->
					@trigger "#{prefix}addedTo", arguments
				model.on "#{prefix}removedFrom:#{key}", ->
					@trigger "#{prefix}removedFrom", arguments

				super model.attributes[key], options

		AssociatedCollection

	Backbone.Sails = Sails
)(Backbone, $, _)
