###
  file: backbone.sails.coffee
  libary: Backbone.Sails

  copyright: Ian Haggerty
  author: Ian Haggerty
  created: 20/09/2014
  updated: 20/09/2014
  email: iahag001@yahoo.co.uk
  github: https://github.com/iahag001/Backbone.Sails

  dependencies: [
    Backbone: https://github.com/jashkenas/backbone
    jQuery: https://github.com/jquery/jquery
    underscore: https://github.com/lodash/lodash/
    sails.io.js: https://github.com/balderdashy/sails.io.js
  ]

  Backbone.Sails is a library for negotiating 'resourceful' socket events
  from a SailsJS backend into the Backbone ecosystem. It has it's own
  Backbone.Sails.Model class, as well as a Backbone.Sails.Collection class

  It also has a sync method you can leverage, at Backbone.Sails.sync. This sync
  method will attempt to sync over sockets (assuming default sailsJs routing
  conventions for models), and will delegate to jQuery.Ajax (Backbone.sync)
  if socket's aren't available.

  Syncing over Ajax doesn't subscribe the client socket to that Model or the
  instances synced. Backbone.Sails.sync has an intelligent delegation method which
  make's sure all Ajax requests are followed up the corresponding socket
  request, so that the socket is registered to the Model/instances synced
  over Ajax. This ensures your app stay's realtime whenever possible.
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
		_.extend Sails.config, config

# Global Backbone.Sails.config configuration object
	Sails.config =

	## Prefix for socket based events on (and only on) Backbone.Sails.Model
	# and Backbone.Sails.Collection.
	#
	# For example, a collection instance will emit a "created" event, when the
	# model resource referenced through it's url property has an instance created
	# server side through *another* client socket provided this client socket is
	# subscribed to that resource (read that last sentence again).
	#
	# Collection instances emit many other events (updated, removedFrom, addedTo...)
	# that names of which may collude with other events registed on a collection.
	# Setting an event prefix can offset the namespace damage:
	#
	# coll.on "created", (newModel)-> @add(newModel)
	# Backbone.Sails.config.eventPrefix = "socket:"
	# coll.on "socket:created", (newModel)-> console.
		eventPrefix: ""

	# `interval` refer's to the time certain operations in the network code wait before
	# trying again. Increasing the value will mean a little less of a CPU hit client side,
	# but it will also mean longer times to resolve certain promises/requirements.
	# Defaults to 2 seconds.
		interval: 500

	# `attempts` refer's to the number of times to try something before giving up.
	# By default it is undefined, which means indefinite polling for certain requirements
	# client side (promises try to resolve every `interval` milliseconds, and keep on trying
	# until they are resolved or the client leaves the webpage)
	#
	# Setting attempts to a finite number will protect against indefinite polling, but
	# it will also mean your app is viable to give up on certain requests & therefore,
	# possibly not achieve realtime commuinication, when it is available.
		attempts: 20

	# `defaults` configures the default values for certain options available to
	# the public API of Backbone.Sails. At the moment, it only set's the default filter
	# queries for Backbone.Sails.Collection. These options are easily overridden with
	# the chainable collection methods `coll.where({ name: { contains: "I" } })`,
	# `coll.sort("name ASC")`, `coll.limit(5)`, `coll.skip(10)` and finally
	# `coll.paginate(pageNo, limit)`
		defaults:
			where: {}
			limit: 30
			sort: {}
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
				if maxAttemptsExceeded defer
					defer.reject()
					
				else
					setTimeout ->
						findingSocketClient(defer)
					, Sails.config.interval

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

						# start polling for a connected status
						to = setTimeout ->
							_.remove socketClient.$events.connect, (h) -> h == connectHandler
							socketConnecting(defer)
						, Sails.config.interval

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
		if !options.url
			url = _.result instance, 'url' || urlError


		if isCollection instance
			payload = undefined
		else
			payload = instance.attributes


		socketClient[methodMap[method]] url, payload, (res, jwres)->
			if res.error || jwres.statusCode != 200

				# todo - possible revision of 2nd argument, see http://api.jquery.com/jQuery.ajax/
				options.error? jwres, jwres.statusCode, jwres.body # triggers 'error'
				defer.reject jwres, jwres.statusCode, jwres.body

				instance.trigger "#{prefix}socketerror", jwres, jwres.statusCode, jwres.body
			else
				options.success? res, jwres.statusCode, jwres # triggers 'sync'
				defer.resolve res, jwres.statusCode, jwres

				instance.trigger "#{prefix}socketsync", instance, res, options

				# register & subscribe instances before triggering socketsync
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
		instance.trigger "#{prefix}socketrequest", instance, defer.promise(), options

		defer.promise()


# Promises a simulated jqXHR socket request
	sendingSocketRequest = (method, instance, options) ->
		result = $.Deferred()
		
		# check for connection
		socketConnecting().done ->
			
			# augment url before sync (add's filter queries)
			previousUrl = augmentUrl method, instance
			
			# map from backbone verbs to sails.io.js verbs
			sendSocketRequest(method, instance, options).done (res, statusCode, jwres)->
				result.resolve res, statusCode, jwres

			# restore the original url immediately
			instance.url = previousUrl

		result

# Grab a reference to the original Backbone.sync (assuming it's not been tampered with)
	originalSync = Backbone.sync

# Promises a request over jqXHR, this delegates to Backbone.sync
	sendingAjaxRequest = (method, instance, options)->
		
		# augment url as required
		previousUrl = augmentUrl method, instance

		# sync
		result = originalSync.apply instance, arguments

		# restore url immediately
		instance.url = previousUrl

		result

# Returns the filter query for a Backbone.Sails.Collection
	filterQuery = (coll) ->
		query = []
		if sails = coll._sails
			if _.isObject sails.where
				query.push "where=#{JSON.stringify sails.where}"
			else if _.isString sails.where
				query.push "where=#{sails.where}"
			else
				throw new Error "Backbone.Sails: where expects a string or an object"

			if _.isObject sails.sort
				query.push "sort=#{JSON.stringify sails.sort}"
			else if _.isString sails.sort
				query.push "sort=#{sails.sort}"
			else
				throw new Error "Backbone.Sails: sort expects a string or an object"

			if _.isNumber sails.limit
				query.push "limit=#{sails.limit}"
			else
				throw new Error "Backbone.Sails: limit expects a number"

			if _.isNumber sails.skip
				query.push "skip=#{sails.skip}"
			else
				throw new Error "Backbone.Sails: skip expects a number"

			"?" + query.join("&")
		else
			""

# Augments the url for sync requests - according to the instance type
	augmentUrl = (method, instance) ->
		previousUrl = _.result instance, 'url'

		if isCollection(instance) && isSails(instance) && method == "read"
			url = _.result instance, 'url'

			url += filterQuery(instance) || ""

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
				setTimeout ->
					resolvingRequest(request, defer)
				, Sails.config.interval

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
		typeof instance.cid == "undefined"

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
			Backbone.Sails.trigger "register:collection", modelName, collections[modelName]

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

# Promises registering a collection
	registeringCollection = (coll, defer = $.Deferred())->

		if collectionRegistered(coll)
			defer.resolve()
		else
			socketConnecting().done ->
				registerCollection(coll)
				defer.resolve()

		defer.promise()

# Register's an event aggregator for a model instance, if necessary
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

			Backbone.Sails.trigger "register:model", modelName, models[modelName]

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
					Model = coll.model
					model = new Model(e.data)
					coll.trigger "#{prefix}created", model, e

				coll.trigger "#{Sails.config.eventPrefix}subscribed:collection", modelName, coll
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
					model.trigger "#{prefix}addedTo:#{e.attribute}", model, e.id, e

				model.listenTo aggregator, "removedFrom", (e)->
					model.trigger "#{prefix}removedFrom", model, e
					model.trigger "#{prefix}removedFrom:#{e.attribute}", model, e.id, e

				model.listenTo aggregator, "destroyed", (e)->
					model.trigger "#{prefix}destroyed", model, e

				model.listenTo aggregator, "updated", (e)->
					# do some dirty checking
					# todo associations-collection support?
					changed = false
					for attribute, val of e.data
						if model.get(attribute) != val
							model.trigger "#{prefix}updated:#{attribute}", model, val, e
							changed = true
					if changed
						model.trigger "#{prefix}updated", model, e

				model.listenTo aggregator, "messaged", (e)->
					model.trigger "#{prefix}messaged", model, e

				model.trigger "#{Sails.config.eventPrefix}subscribed:model", modelName, model
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

# The all important Model class
	class Sails.Model extends Backbone.Model
		_sails:
			synced: false

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

			if socketConnected()
				# fetch via sockets
				result = sendingSocketRequest 'read', model, options
			else
				result = sendingAjaxRequest 'read', model, options # fetch via jqXHR

				# queue up a read socket request to subscribe server side
				if (options.subscribe == true) || (options.subscribe != false && Sails.config.subscribe == true)
					options = _.clone(options)

					options.success = (resp) ->
						if !model.set model.parse(resp, options), options
							return false

					resolvingRequest
						method: 'read'
						instance: model
						options: options

			result

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

			if socketConnected()
				result = sendingSocketRequest method, this, options
			else
				# delegate to jqXHR
				result = sendingAjaxRequest method, this, options

				# queue up a read socket request to subscribe the model server side
				if options.subscribe == true || (options.subscribe != false && Sails.config.subscribe == true)
					options = _.clone(options)

					options.success = (resp) ->
						# ensure the attributes are restored during synchronous saves
						model.attributes = attributes
						serverAttrs = model.parse resp, options
						if options.wait then serverAttrs = _.extend attrs || {}, serverAttrs
						if _.isObject serverAttrs && !model.set serverAttrs, options
							return false
						model.trigger 'sync', model, resp, options

					resolvingRequest
						method: 'read'
						instance: model
						options: options

			# restore attributes
			if attrs && options.wait then @attributes = attributes

			result

		constructor: ->
			super

			@_sails =
				subscribed: false
				registered: false

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

			if socketConnected()
				result = sendingSocketRequest 'read', @, options
			else
				result = sendingAjaxRequest 'read', @, options

				# queue up a socket request to subscribe the collection server side
				if options.subscribe == true || (options.subscribe != false && Sails.config.subscribe == true)
					options = _.clone(options)

					options.success = (resp) ->
						collection.set(resp, options)
						collection.trigger 'sync', collection, resp, options

					resolvingRequest
						method: 'read'
						instance: this
						options: options

			result

		where: (criteria) ->
			@_sails.where = criteria
			@

		skip: (skip) ->
			@_sails.skip = skip
			@

		sort: (sort) ->
			@_sails.sort = sort
			@

		limit: (limit) ->
			@_sails.limit = limit
			@

		paginate: (page = 0, limit = Sails.config.defaultLimit) ->
			@_sails.skip = page * limit
			@_sails.limit = limit
			@

		constructor: ->
			super

			@_sails =
				where : Sails.config.defaults.where
				skip  : Sails.config.defaults.skip
				sort  : Sails.config.defaults.sort
				limit : Sails.config.defaults.limit
				subscribed: false
				registered: false

			# Needs a url
			url = _.result(this, 'url')
			if _.isUndefined(url) then urlError()

			# Setup an intelligent default model
			@model = Sails.Model.extend
				urlRoot: url

	Backbone.Sails = Sails
)(Backbone, $, _)
