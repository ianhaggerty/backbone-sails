###
  file: backbone.sails.coffee
  libary: Backbone.Sails

  copyright: Ian Haggerty
  author: Ian Haggerty
  created: 20/09/2014
  updated: 20/09/2014
  email: iahag001@yahoo.co.uk
  github: todo put github url here

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
	Backbone.Sails = _.extend {}, Backbone.Events

# Global Backbone.Sails.config configuration object
	Backbone.Sails.config =

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
	# coll.on "socket:created", (newModel)-> console.log "shweet! a new model instance"
		eventPrefix: ""

	# `interval` refer's to the time certain operations in the network code wait before
	# trying again. Increasing the value will mean a little less of a CPU hit client side,
	# but it will also mean longer times to resolve certain promises/requirements.
	# Defaults to 2 seconds.
		interval: 2000

	# `attempts` refer's to the number of times to try something before giving up.
	# By default it is undefined, which means indefinite polling for certain requirements
	# client side (promises try to resolve every `interval` milliseconds, and keep on trying
	# until they are resolved or the client leaves the webpage)
	#
	# Setting attempts to a finite number will protect against indefinite polling, but
	# it will also mean your app is viable to give up on certain requests & therefore,
	# possibly not achieve realtime commuinication, when it is available.
		attempts: undefined

	# `logLevel` refers to the level of logging to output. The options are
	# 0 = no logs, 1 = error logs, 2 = trace logs, 3 = debug logs, 4 = warn
	# 5 = info, 6 = log
	# The logging functionality is designed with debugging inside chrome in mind
	# (some logging functions may not work in other browsers).
	# Defaults to 1 (error logs only)
	# (// Note to library developers - keep all log requests on a single line //)
	# (// This will make them easy to remove for a production build           //)
		logLevel: 1

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
	# in the networking logic. No return necessary.
		findSocketClient: undefined

	# If defined, this should be a function which attempts to (re-) acquire a connnection
	# to a socket client instance. It will be passed the socket client as a first
	# argument. No return necessary.
		connectToSocket: undefined

	# A boolean indicating whether to delegate to jqXHR if socket is unavailable.
	# It is generally a good idea to leave this on, as sockets can take a number
	# of seconds to connect initially.
		delegateSync: true

# Internal log implementation
	log = (->
		verbMap =
			log: 6
			info: 5
			warn: 4
			debug: 3
			trace: 2
			error: 1

		logg = ->
			console.log arguments

		prelog = ->
			d = new Date()
			"#{d.getMinutes()}:#{d.getSeconds()}:#{d.getMilliseconds()}::Backbone::Sails::"

		API =
			log: ->
				if verbMap.log <= Backbone.Sails.config.logLevel
					for o in arguments
						console.log prelog(), o
			info: ->
				if verbMap.info <= Backbone.Sails.config.logLevel
					for o in arguments
						console.info prelog(), o
			warn: ->
				if verbMap.warn <= Backbone.Sails.config.logLevel
					for o in arguments
						console.warn prelog(), o
			debug: ->
				if verbMap.debug <= Backbone.Sails.config.logLevel
					for o in arguments
						console.debug prelog(), o
			trace: ->
				if verbMap.trace <= Backbone.Sails.config.logLevel
					for o in arguments
						console.trace
			error: ->
				if verbMap.error <= Backbone.Sails.config.logLevel
					for o in arguments
						console.error prelog(), o
	)()

# Make log publicly available for user's to log their own messages
	Backbone.Sails.log = log

# Generic logic used in the 'looping defer pattern' to ascertain whether
# the number of attempts for this particular promise has exceeded
	maxAttemptsExceeded = (defer) ->
		defer.attempts = if defer.attempts then defer.attempts + 1 else 1
		maxAttempts = Backbone.Sails.config.attempts
		if _.isUndefined maxAttempts
			return false
		if defer.attempts <= maxAttempts
			return false
		return true

# References the socket client, when it is found. The socket client is typically
# located at the io.socket global exposed by sails.io.js.
	socketClient = undefined

# Logic to find the socket client
	findSocketClient = ->
		log.log "findSocketClient::called : attempting to acquire client"
		if io.socket && io.socket.socket
			socketClient = io.socket
			log.info "findSocketClient:: socket client io.socket found"
		else if Backbone.Sails.config.findSocketClient?()
			socketClient = Backbone.Sails.config.findSocketClient()

# Conditional logic indicating a socketClient was found
	socketClientFound = ->
		socketClient && socketClient.socket

# Promises the socket client is available
	findingSocketClient = (defer = $.Deferred())->
		if socketClientFound()
			log.log "findingSocketClient:: socket client found - resolving promise"
			defer.resolve()
		else
			log.log "findingSocketClient:: socket client not found - attempting to acquire"
			findSocketClient()

			if socketClientFound()
				log.log "findingSocketClient:: socket client found - resolving promise"
				defer.resolve()
			else
				if maxAttemptsExceeded defer
					defer.reject()
					log.error "findingSocketClient::max attempts exceeded"
				else
					setTimeout ->
						log.info "findingSocketClient:: polling again"
						findingSocketClient(defer)
					, Backbone.Sails.config.interval
		defer.promise()

# Logic to attempt connect/reconnect to the socket
	connectSocket = ->
		log.log "connectSocket::called"
		Backbone.Sails.config.connectToSocket?(socketClient)

# Conditional logic for a 'connected' status
	socketConnected = ->
		socketClient?.socket?.connected

# Promises the socket is connected
	socketConnecting = (defer = $.Deferred())->
		# socket client must be available before attempting connect
		findingSocketClient().done ->
			if socketConnected()
				log.log "socketConnecting:: connected - resolving promise"
				defer.resolve()
			else
				connectSocket()
				if socketConnected()
					log.log "socketConnecting:: connected - resolving promise"
					defer.resolve()
				else
					if maxAttemptsExceeded defer
						defer.reject()
						log.error "socketConnecting:: max attempt exceeded"
					else
						log.warn "socketConnecting:: couldn't connect - setting timeout and a listener for 'connect' on socketClient"

						to = undefined

						# register a listener for a 'connect' event to resolve more immediately
						connectHandler = ->
							log.debug "socketConnecting:: connect fired, clearing timeout and should be resolving soon..."
							clearTimeout to
							socketConnecting(defer)

						#socketClient.socket.once "connect", connectHandler
						socketClient.once "connect", connectHandler

						# start polling for a connected status
						# in case 'connect' event missed
						to = setTimeout ->
							log.warn "socketConnecting:: connect event not fired on socketClient - polling again"
							_.remove socketClient.$events.connect, (h) -> h == connectHandler
							socketConnecting(defer)
						, Backbone.Sails.config.interval
		defer.promise()

# Simulates a jqXHR request through websockets
	sendSocketRequest = (method, instance, options) ->
		log.log "sendSocketRequest::called - method #{method}"
		log.trace() # trace the stack
		defer = new $.Deferred()
		prefix = Backbone.Sails.config.eventPrefix
		url = _.result instance, 'url'
		if !_.isString url
			log.error "sendSocketRequest:: no url property found - rejecting promise"
			defer.reject()
		else
			log.info "sendSocketRequest:: found url #{url}"
			instance.trigger "request", instance, defer.promise(), options
			instance.trigger "#{prefix}socketrequest", instance, defer.promise(), options

			if isCollection instance
				payload = undefined
				log.info "sendSocketRequest:: found collection, payload undefined"
			else
				payload = instance.attributes
				log.info "sendSocketRequest:: found model, payload:"
				log.info payload

			log.debug "sendSocketRequest:: attempting to send socket request"
			log.debug [method, url, payload]
			socketClient[method] url, payload, (res, jwr)->
				if res.error || jwr.statusCode != 200
					log.error "sendSocketRequest::failed"
					log.error [res, jwr, options]
					options.error? res, jwr, options
					defer.reject jwr, jwr.statusCode, res.error
				else
					log.debug "sendSocketRequest::successful"
					log.debug [res, jwr, options]
					options.success? res, jwr, options
					defer.resolve res, jwr.statusCode, jwr

					# register an event aggregator for the instance synced, if necessary
					defer.done ->
						log.log "sendSocketRequest::successful - attempting to register instance"
						registeringInstance instance
					instance.trigger "#{prefix}socketsync", instance, defer.promise(), options

		defer.promise()

# Promises a simulated jqXHR socket request (depends on sendSocketRequest)
	sendingSocketRequest = (method, instance, options) ->
		defer = $.Deferred()

		log.log "sendSocketRequest::called - waiting for socketConnecting resolution"
		# check for connection
		socketConnecting().done ->
			log.log "sendSocketRequest:: connection resolved, augmenting url"
			# augment url before sync - at the moment, this just add's the filter queries
			# parameters, though it can very well do other things in the future
			previousUrl = augmentUrl method, instance
			log.info "sendSocketRequest::augmented url"
			log.info _.result(instance, 'url')
			# map from backbone verbs to sails.io.js verbs
			defer = switch method
				when 'create'  then sendSocketRequest 'post',   instance, options
				when 'read'    then sendSocketRequest 'get',    instance, options
				when 'update'  then sendSocketRequest 'put',    instance, options
				when 'delete'  then sendSocketRequest 'delete', instance, options
				else
					log.error "sendSocketRequest:: method #{method} not found - rejecting promise"
					$.Deferred((d)->d.reject()) # return a rejected promise, just in case someone is listening
			# restore the original url immediately
			instance.url = previousUrl

		defer.promise()

# Grab a reference to the original Backbone.sync (assuming it's not been tampered with)
	originalSync = Backbone.sync

# Promises a request over jqXHR, this delegates to Backbone.sync
	sendingAjaxRequest = (method, instance, options)->
		log.log "sendAjaxRequest::called - augmenting url"
		# augment url as required
		previousUrl = augmentUrl method, instance
		log.info "sendAjaxRequest::url augmented"
		log.info _.result(instance, 'url')
		# sync
		log.debug "sendAjaxRequest::attempting to send ajax request"
		log.debug [method, instance, options]
		result = originalSync.apply instance, arguments
		# restore url immediately
		instance.url = previousUrl

		result.promise()

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
		url = _.result(instance, 'url')
		if !url
			log.error "getModelName:: could not find a url for a instance:"
			log.error instance
		_.remove(url.split('/'), (c)->c)[0].split('?')[0]

# Tests whether an instance is a collection
	isCollection = (instance) ->
		_.isUndefined instance.cid

# Tests whether instance is a Backbone.Sails.Collection or a Backbone.Sails.Model
	isSails = (instance) ->
		instance._sails

# Forwards the socket event e to the aggregator specified
	forwardSocketEvent = (e, aggregator) ->
		aggregator.trigger "#{e.verb}", e

# Register's an event aggregator for a collection instance, if necessary
	registerCollection = (coll)->
		log.info "registerCollection:: called - attempting to register collection"
		modelname = getModelName coll
		collections = Backbone.Sails.Collections

		# set up modelname namespace if not exist
		# register a socket-collection handler for this modelname
		if  !collections[modelname]
			log.debug "registerCollection:: no aggregator found for collection #{modelname}, creating one now..."
			collections[modelname] = _.extend {}, Backbone.Events

			log.debug "registerCollection:: creating socket to aggregator handler for collection #{modelname}"
			# keep reference to handler
			collections[modelname]._sails =
				handler: (e) ->
					forwardSocketEvent(e, collections[modelname])

			log.debug "registerCollection:: registering socket to aggregator handler for collection #{modelname}"
			io.socket.on modelname, collections[modelname]._sails.handler

			# Tell Backbone.Sails this collection has been registered
			Backbone.Sails.trigger "register:collection", modelname

# Conditional logic indicating a collection has been registered
	collectionRegistered = (coll) ->
		modelName = getModelName coll
		coll && modelName &&
		(handler = Backbone.Sails.Collections[modelName]?._sails?.handler) &&
		(handlers = socketClient.$events[modelName]) &&
		(if _.isArray(handlers) then _.contains handlers, handler else handler == handlers)

# Promises registering a collection
	registeringCollection = (coll, defer = $.Deferred())->
		log.log "registeringCollection::called"
		socketConnecting().done ->
			if collectionRegistered(coll)
				log.log "registeringCollection:: collection registered - resolving"
				defer.resolve()
			else
				log.debug "registeringCollection:: collection not registered - calling registerCollection"
				registerCollection(coll)
				if collectionRegistered(coll)
					defer.resolve()
				else
					if maxAttemptsExceeded defer
						defer.reject()
						log.error "registeringCollection:: max attempts exceeded"
					else
						log.warn "registeringCollection:: collection registration failed - setting timeout for polling"

						to = undefined

						socketSyncHandler = ->
							if collectionRegistered(coll)
								clearTimeout to
								defer.resolve()

						# listen for a socketsync to resolve more immediately
						coll.once "#{Backbone.Sails.config.eventPrefix}socketsync", socketSyncHandler

						to = setTimeout ->
							log.warn "registeringCollection:: polling again"
							coll.off "#{Backbone.Sails.config.eventPrefix}socketsync", socketSyncHandler
							registeringCollection(coll, defer)
						, Backbone.Sails.config.interval

		defer.promise()

# Register's an event aggregator for a model instance, if necessary
	registerModel = (model) ->
		log.log "registerModel:: called - attempting to register model"
		if _.isUndefined model.id # not yet synced, cannot register without id
			log.warn "registerModel:: no model.id found, exiting function"
			return
		modelName = getModelName model
		models = Backbone.Sails.Models

	# set up modelname namespace if not exist
		if !models[modelName]
			log.debug "registerModel:: creating model namespace for #{modelName}"
			models[modelName] = {}

	# create an aggregator for this specific model instance
		if !models[modelName][model.id]
			log.debug "registerModel:: no aggregator found - creating model aggregator for #{modelName}:#{model.id}"
			models[modelName][model.id] = _.extend {}, Backbone.Events

	# register a socket-model handler if not exist
		if !models[modelName]._sails?.handler
			log.debug "registerModel:: no handler found - creating a socket to model aggregator for #{modelName}"
			# keep reference to handler
			models[modelName]._sails =
				handler: (e) ->
					if models[modelName][e.id]
						forwardSocketEvent(e, models[modelName][e.id])

			log.debug "registerModel:: registering the socket to model aggregator for #{modelName}"
			io.socket.on modelName, models[modelName]._sails.handler
			Backbone.Sails.trigger "register:model", modelName, model.id, models[modelName]

# Conditional logic indicating model has had an event aggregator created and subscribed
	modelRegistered = (model)->
		modelName = getModelName model
		model && model.id && modelName &&
		Backbone.Sails.Models[modelName]?[model.id]? &&
		(handler = Backbone.Sails.Models[modelName]._sails?.handler) &&
		(handlers = socketClient.$events[modelName]) &&
		(if _.isArray(handlers) then _.contains handlers, handler else handler == handlers)

# Promises registering an event aggregator for a model
	registeringModel = (model, defer = $.Deferred())->
		log.log "registeringModel:: called"
		socketConnecting().done ->
			if modelRegistered(model)
				log.log "registeringModel:: model already registered  - resolving"
				defer.resolve()
			else
				log.log "registeringModel:: model not already registered - attempting to register"
				registerModel(model)
				if modelRegistered(model)
					log.log "registeringModel:: model registered  - resolving"
					defer.resolve()
				else
					if maxAttemptsExceeded defer
						defer.reject()
						log.error "registeringModel:: max attempts exceeded"
					else
						log.warn "registeringModel:: model registration failed for:", model

						to = undefined

						socketSyncHandler = ->
							if modelRegistered(model)
								clearTimeout to
								defer.resolve()

						# listen for a socketsync to resolve more immediately
						model.once "#{Backbone.Sails.config.eventPrefix}socketsync", socketSyncHandler

						log.warn "registeringModel:: setting timeout for polling"
						to = setTimeout ->
							log.warn "registeringModel:: polling again"
							model.off "#{Backbone.Sails.config.eventPrefix}socketsync", socketSyncHandler
							registeringModel(model, defer)
						, Backbone.Sails.config.interval
		defer.promise()

# Promises registering an event aggregator for a generic instance (a collection or model)
# If instance is a collection, event aggregators will be created and registered for it's current models
	registeringInstance = (instance) ->
		log.log "registeringInstance::called"
		if isCollection instance
			log.log "registeringInstance::collection found attempting to register the collection and all of its models"
			promises = []
			promises.push registeringCollection(instance)
			for model in instance.models
				promises.push registeringModel(model)
			# return aggregate promise
			$.when(promises)
		else
			log.log "registeringInstance::model found - attempting to register"
			registeringModel instance

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
			log.error "Backbone.Sails: property _sails not found on collection"
			""

# Augments the url for sync requests - according to the instance type
	augmentUrl = (method, instance) ->
		previousUrl = instance.url

		if isCollection(instance) && isSails(instance) && method == "read"
			url = _.result instance, 'url'

			url += filterQuery(instance) || ""

			instance.url = url

		# return the previous url
		previousUrl

# Promises resolving a request through the socket
# Request is object of form { method: "get", instance: aModelOrColl, options{ // success callbacks, etc } }
	resolvingRequest = (request, defer = $.Deferred())->
		log.info "resolvingRequest::called - sending a socket request to resolve"
		request = sendingSocketRequest request.method, request.instance, request.options
		request.done ->
			log.debug "resolvingRequest:: socket request successful, request is now resolved"
			defer.resolve()
		request.fail ->
			if maxAttemptsExceeded defer
				defer.reject()
				log.error "resolvingRequest:: max attempts exceeded"
			else
				log.warn "resolvingRequest:: socket request failed, setting timeout for polling"
				setTimeout ->
					log.warn "resolvingRequest::polling again"
					resolvingRequest(request, defer)
				, Backbone.Sails.config.interval
		defer.promise()

# Custom Backbone.sync to use sockets when available, delegating to jQuery.ajax if delegateSync is true
	sync = (method, instance, options) ->
		log.log "sync::called"
		if socketConnected()
			log.log "sync:: socket connected, delegating to sendingSocketRequest"
			result = sendingSocketRequest(method, instance, options)
		else if Backbone.Sails.config.delegateSync
			log.log "sync:: socket not connected, delegating to sendingAjaxRequest"
			# delegate to http for now
			result = sendingAjaxRequest(method, instance, options)

			if isSails instance
				# push a subscribe request to the resource
				# this should subscribe this socket to the model(s) requested
				#
				# delete the success callback to avoid a double callback
				delete options.success if options.success
				# note - backbone will simulate a success callback anyway, and
				# the instance will be synced again at a later time as well
				log.info "sync:: request was delegated to Ajax, attempting to resolve request through sockets"
				resolvingRequest { method: "read", instance: instance, options: options }
		else
			# socket not available and delegateSync is false
			# wait for a socket connect
			log.info "sync:: socket not available at the moment, waiting for a socket connect before sync"
			result = $.Deferred()
			socketConnecting().done ->
				log.info "sync:: socket connected"
				sync(method, instance, options).promise().done ->
					log.info "sync:: socket sync successful, resolving..."
					result.resolve arguments
			.fail ->
				log.error "sync:: socket connecting failed"
				result.reject()

		result.promise()

# Place sync on global namespace for users to take advantage of
	Backbone.Sails.sync = sync

# Conditional logic indicating that a collection is already subscribed
	collectionSubscribed = (coll)->
		coll._listeningTo &&
			_.toArray(coll._listeningTo).indexOf(Backbone.Sails.Collections[getModelName(coll)]) != -1

# Promises subscribing a collection to it's relevant aggregator
	subscribingCollection = (coll) ->
		log.log "subscribingCollection::called - attempting to register collection beforehand, if necessary"
		defer = $.Deferred()
		registeringCollection(coll).done ->
			log.log "subscribingCollection:: collection (already) registered"
			if collectionSubscribed(coll)
				log.log "subscribingCollection:: collection already subscribed - resolving"
				defer.resolve()
			else
				log.info "subscribingCollection:: collection not subscribed - attempting to subscribe to aggregator"
				modelName = getModelName(coll)
				aggregator = Backbone.Sails.Collections[modelName]
				prefix = Backbone.Sails.config.eventPrefix

				coll.listenTo aggregator, "created", (e) ->
					Model = coll.model
					model = new Model(e.data)
					coll.trigger "#{prefix}created", model, e

				log.info "subscribingCollection:: collection subscribed to aggregator - resolving"

				defer.resolve()
		defer.promise()

# Promises unsubscribing a collection
# Not currently used - todo remove for production
	unsubscribingCollection = (coll) ->
		defer = $.Deferred()
		registeringCollection(coll).done ->
			modelName = getModelName(coll)
			aggregator = Backbone.Sails.Collections[modelName]
			coll.stopListening aggregator
			defer.resolve()
		defer.promise()

# Conditional logic indicating that a model is subscribed
	modelSubscribed = (model)->
		model._listeningTo &&
		_.toArray(model._listeningTo).indexOf(Backbone.Sails.Models[getModelName(model)][model.id]) != -1

# Promises a subscribing a model to it's relevant aggregator
	subscribingModel = (model) ->
		log.log "subscribingModel:: called - attempting to register model beforehand, if necessary"
		defer = $.Deferred()
		registeringModel(model).done ->
			log.log "subscribingModel:: model (already) registered"
			if modelSubscribed(model)
				log.log "subscribingModel:: model already subscribed - resolving"
				defer.resolve()
			else
				log.info "subscribingModel:: model not subscribed - attempting to subscribe"
				modelName = getModelName(model)
				aggregator = Backbone.Sails.Models[modelName][model.id]
				prefix = Backbone.Sails.config.eventPrefix

				log.info "subscribingModel:: setting up listeners for", model
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
					changed = false
					for attribute, val of e.data
						if model.get(attribute) != val
							model.trigger "#{prefix}updated:#{attribute}", model, val, e
							changed = true
					if changed
						model.trigger "#{prefix}updated", model, e

				model.listenTo aggregator, "messaged", (e)->
					model.trigger "#{prefix}messaged", model, e

				log.info "subscribingModel:: listeners setup, model subscribed - resolving"

				defer.resolve()
		defer.promise()

# Promises unsubscribing a model
# Not currently used - todo remove for production
	unsubscribingModel = (model) ->
		defer = $.Deferred()
		registeringModel(model).done ->
			modelName = getModelName(model)
			aggregator = Backbone.Sails.Models[modelName][model.id]
			model.stopListening aggregator
			defer.resolve()
		defer.promise()

# Promises subscribing a generic instance to it's relevant aggregator
	subscribingInstance = (instance) ->
		if isCollection instance
			subscribingCollection instance
		else
			subscribingModel instance

# This function works just like fetch, except it will only callback/resolve
# when the instance is both persisted and subscribed. This guarantees the
# subscription of all model(s) currently referenced by the instance.
# If the autoWatch setting is true (default) and this is a collection, new
# instances can be listened for via 'created' events. These new instances
# are automatically subscribed to, so no need to call .subscribe on them
# when they come in. If autowatch is false, you'll need to call .subscribe
# to fetch the state of the instance and subscribe to any models.
# see http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/watch.html
	subscribe = (options)->
		log.debug "subscribe::called on instance", this
		log.debug "subscribe::attempting to subscribe..."
		self = this
		defer = $.Deferred()
		clone = $.extend true, {}, options

		clone.success = ->
			log.debug "subscribe::fetch succeed...", arguments
			self.once "#{Backbone.Sails.config.eventPrefix}socketsync", ->
				log.debug "subscribe::socketsync fired...", arguments
				subscribingInstance(self).done ->
					success = ->
						log.debug "subscribe::instance subscribed - handling success callback"
						options?.success?.apply self, arguments
						defer.resolve.apply self, arguments

					error = ->
						log.error "subscribe::an error occurred whilst trying to subscribe models of collection", arguments
						options?.error?.apply self, arguments
						defer.reject.apply self, arguments

					log.debug "subscribe:: instance subscribed, checking if collection"
					# if collection subscribe the models fetched as well
					if isCollection self
						log.debug "subscribe::collection found, subscribing models"
						promises = []
						for model in self.models
							promises.push subscribingModel model
						$.when(promises).done ->
							log.debug "subscribe::models subscribed"
							success()
						.fail ->
							error()
					else
						log.debug "subscribe::model found, calling success"
						success()

		clone.error = ->
			log.error "subscribe::an error occurred whilst trying to fetch", arguments
			options?.error?.apply self, arguments
			defer.reject.apply self, arguments

		self.fetch.apply self, [clone].concat(_(arguments).slice(1))

		defer.promise()

	class Backbone.Sails.Model extends Backbone.Model

		sync: sync

		subscribe: -> subscribe.apply this, arguments

		constructor: ->
			super
			self = this

	class Backbone.Sails.Collection extends Backbone.Collection
		_sails:
			where : Backbone.Sails.config.defaults.where
			skip  : Backbone.Sails.config.defaults.skip
			sort  : Backbone.Sails.config.defaults.sort
			limit : Backbone.Sails.config.defaults.limit

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

		paginate: (page = 0, limit = Backbone.Sails.config.defaultLimit) ->
			@_sails.skip = page * limit
			@_sails.limit = limit
			@

		sync: sync

		subscribe: -> subscribe.apply this, arguments

		constructor: ->
			super

			# needs a url
			url = _.result(this, 'url')
			if _.isUndefined(url)
				throw new Error "Backbone.Sails.Collection could not find a url"

			# Setup an intelligent default model
			self = this;
			self.model = Backbone.Sails.Model.extend
				urlRoot: url

# Event aggregators for 'model' resources will be populated here as they come in.
# e.g. model({ urlRoot: "/users", id: "1" }) will, upon subscription, register an
# event aggregator at Backbone.Sails.Models.users[1]
	Backbone.Sails.Models = {}

# Event aggregators for 'collection' resources will be populated here as they come in
# e.g. coll({ url: "/users" }) will, upon subscription, register an evbent aggregator
# at Backbone.Sails.Collections.users.
	Backbone.Sails.Collections = {}

# Event aggregators act to forward events from the socket, making using of the 'event identity'
# (the respective model name) to the aggregator. Models and collection then `listenTo` that
# aggregator for events.

# Helper function for setting up configuration
	Backbone.Sails.configure = (config) ->
		_.extend Backbone.Sails.config, config
)(Backbone, $, _)
