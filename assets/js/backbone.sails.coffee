((Backbone, $, _)->

	socketClient = undefined

	Sails = {}

	Sails.Models = {}

	Sails.config =
		eventPrefix: ""
		populate: false
		where: false
		limit: 30
		sort: false
		skip: 0
		sync: ['socket', 'ajax']
		mutate: false
		timeout: false
		poll: 50
		client: -> io.socket
		promise: (promise)-> promise

	keys =
		filter: ['where', 'sort', 'skip', 'limit']
		model: ['populate', 'sync']
		collection: ['populate', 'sync', 'where', 'sort', 'skip', 'limit']
		messageAction: '_action'

	Sails.configure = (config) ->
		mapConfig(config)

	mapConfig = (config) ->
		for key, val of config
			if parseConfig[key]?
				Sails.config[key] = parseConfig[key] val
			else
				Sails.config[key] = val

	parseConfig =
		eventPrefix:  (prefix) ->
			if _.isString prefix
				# not empty and no double dot
				if prefix.length && _.last prefix != ':'
					prefix += ':' # then add one
				return prefix
			else
				throw new Error "config.eventPrefix should be a string"

	modelNameError = ->
		throw new Error "A model name is required"

	urlError = ->
		throw new Error 'A "url" property or function must be specified'

	idError = ->
		throw new Error 'An "id" property must be specified'

	clientNotFoundError = ->
		throw new Error 'A socket client could not be found. Consider revising Sails.config.client'

	timeoutError = (msg)->
		throw new Error msg

	# promise utility
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
					defer.reject "Timed out after #{timeout}ms"
				, timeout
				defer.always ->
					clearTimeout to
			defer
		pollFor: (boolF, defer = $.Deferred())->
			if boolF()
				return defer.resolve()

			if !boolF.polling?
				boolF.polling = defer
				defer.always ->
					boolF.polling = null

			setTimeout ->
				promise.pollFor boolF, boolF.polling
			, Sails.config.poll

			return boolF.polling
		wrap: (promise, internal)-> if internal then promise else Sails.config.promise(promise)

	configPrefix = '_config_'
	getConfig = (key, options, instance) ->
		if options[key]?                      # request level
			options[key]
		else if instance[configPrefix + key]? # instance level
			instance[configPrefix + key]
		else if instance.config?[key]?        # constructor level
			instance.config[key]
		else Sails.config[key]                # global level

	isModel = (instance) ->
		instance instanceof Backbone.Model

	isCollection = (instance) ->
		instance instanceof Backbone.Collection

	isAssociated = (instance) ->
		Boolean instance.associated

	modelName = (instance) ->
		instance.result(instance, 'modelName')

	clientFound = ->
		Sails.config.client().socket?

	# poll indefinitely for a (real) client
	promise.pollFor(clientFound).done ->
		socketClient = Sails.config.client()
	setTimeout ->
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

	methodMap =
		create: 'post'
		read: 'get'
		update: 'put'
		patch: 'put'
		delete: 'delete'

	sendSocketRequest = (method, instance, options)->
		defer = new $.Deferred()
		url = options.url || _.result instance, 'url' || urlError
		method = options.method?.toLowerCase() || methodMap[method]

		payload = if options.payload
			options.payload
		else if isCollection instance
			undefined
		else
			payload = instance.attributes

		socketClient[method] url, payload, (res, jwres)->
			if jwres.statusCode >= 400

				options.error? jwres, jwres.statusCode, jwres.body # triggers 'error'
				defer.reject jwres, jwres.statusCode, jwres.body

			else
				options.success? res, jwres.statusCode, jwres # triggers 'sync'
				defer.resolve res, jwres.statusCode, jwres

		instance.trigger "request", instance, defer.promise(), options

		defer.promise()

	sendingSocketRequest = (method, instance, options) ->
		result = $.Deferred()

		# check for connection
		socketConnecting().done ->

			# augment the url before request
			augmentUrl method, instance, options

			# make request
			promise.chain sendSocketRequest(method, instance, options), result

		.fail ->
			result.reject.apply result, arguments

		result

	sendingAjaxRequest = (method, instance, options)->

		# augment url before request
		augmentUrl method, instance, options

		# make the request
		result = instance.sync method, instance, options

		result

	augmentUrl = (method, instance, options) ->

		url = options.url || _.result instance, 'url'

		if isCollection instance
			url += queryString instance, options, ['where', 'sort', 'skip', 'limit', 'populate']
		else if method != 'delete'
			url += queryString instance, options, ['populate']

		options.url = url

	parseQuery =
		where: (criteria) ->
			if _.isObject criteria
				JSON.stringify criteria
			else
				criteria
		sort: (criteria) ->
			if _.isObject criteria
				JSON.stringify criteria
			else
				criteria
		skip: (criteria) -> criteria
		limit: (criteria) -> criteria
		populate: (criteria) ->
			if _.isArray criteria
				criteria.join ','
			else
				# split by space, remove empties and join
				_.filter(criteria.split(' '), Boolean).join(',')

	queryString = (instance, options, keys) ->

		queries = []
		parseQuery = parseQuery

		for key in keys
			query = getConfig key, options, instance
			if query != false
				queries.push "#{key}=#{parseQuery[key](query)}"

		if queries.length
			'?' + queries.join '&'
		else ''

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
		options.error = (resp) ->
			if error
				error instance, resp, options
			instance.trigger 'error', instance, resp, options

	wrapId = (model, options)->
		payload = {}
		payload[model.idAttribute || "id"] = model.id
		_.assign options,
			# necessary for Ajax delegation
			contentType: 'application/json'
			data: JSON.stringify(payload)

	wrapPayload = (payload, options)->
		_.assign options,
			contentType: 'application/json'
			data: JSON.stringify(payload)
			payload: _.clone payload

	attemptRequest = (request)->
		method          = request.method
		instance        = request.instance
		options         = request.options
		delegateSuccess = request.delegateSuccess

		sync = getConfig 'sync', options, instance
		socketSync = _.contains sync, 'socket'
		ajaxSync = _.contains sync, 'ajax'

		options = _.clone options

		if isAssociated instance
			# don't populate associated instances
			options.populate = false

		if socketSync && socketConnected()
			# if socket available, go for it
			options.sync = "socket"
			result = sendingSocketRequest method, instance, options

		else if ajaxSync || method == 'delete'
			# delegate to ajax
			options.sync = "ajax"
			result = sendingAjaxRequest method, instance, options

			if socketSync && method != 'delete'
				# TODO 'fireback' only on instances persisted
				# TODO deal with 'suppress' option
				# server-subscribe the instance
				result.done ->
					options = _.clone(options)
					fireback = getConfig 'fireback', options, instance
					options.suppress = if fireback==false then true else false
					options.success = delegateSuccess || ->
					options.method = 'GET'
					options.sync = "socket"
					sendingSocketRequest method, instance, options

		else
			# wait for socket connect
			options.sync = "socket"
			result = sendingSocketRequest method, instance, options

		result

	# utility method for model and collection
	configure = (key, val) ->
		# instance level config
		if _.isString key
			@[configPrefix + key] = val
		else
			for k, v of key
				@[configPrefix + k] = v
		@

	class Sails.Model extends Backbone.Model

		query: configure
		configure: configure

		message: (action, data = {}, options = {}) ->
			if _.isObject action
				options = data
				data = action
			else
				data[keys.messageAction] = action

			options.url = "/#{@modelName}/message/#{@id}"

			message = new FakeModel data
			message.save {}, options # post a message

		addTo: (key, model, options = {}, internal = false)->
			if @isNew()
				idError()

			if !isModel model
				model = new FakeModel model

			options.url = _.result(@, 'url') + '/' + key

			if !model.isNew()
				wrapId model, options
				options.method = 'POST' # POST a new association

			promise.wrap model.save({}, options), internal

		removeFrom: (key, model, options = {}, internal = false) ->
			if @isNew()
				idError()

			if !isModel model
				model = new FakeModel model

			if model.isNew()
				idError()

			options.url = _.result(@, 'url') + '/' + key

			wrapId model, options

			promise.wrap model.destroy(options), internal

		destroy: (options, internal = false) ->
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

			result = attemptRequest
				method: 'delete'
				instance: this
				options: options

			if (!options.wait) then destroy()

			promise.wrap result, internal

		save: (key, val, options, internal = false) ->
			# this is mostly backbone, except for 'delegateSuccess'
			attributes = @attributes
			if key == null || typeof key == 'object'
				attrs = key
				options = val
			else
				(attrs = {})[key] = val

			options = _.extend {validate: true}, options

			if attrs && !options.wait
				if !this.set(attrs, options) then return false
			else
				if !this._validate(attrs, options) then return false

			if attrs && options.wait
				@attributes = _.extend {}, attributes, attrs

			if _.isUndefined options.parse then options.parse = true
			model = this;
			success = options.success;
			options.success = (resp) ->
				model.attributes = attributes
				serverAttrs = model.parse resp, options
				if options.wait then serverAttrs = _.extend attrs || {}, serverAttrs
				if _.isObject serverAttrs && !options.suppress && !model.set serverAttrs, options
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

			delegateSuccess = (resp) ->
				model.attributes = attributes
				serverAttrs = model.parse resp, options
				if options.wait then serverAttrs = _.extend attrs || {}, serverAttrs
				if _.isObject serverAttrs && !options.suppress && !model.set serverAttrs, options
					return false
				model.trigger 'sync', model, resp, options

			result = attemptRequest
				method: method
				instance: model
				options: options
				delegateSuccess: delegateSuccess

			if attrs && options.wait then @attributes = attributes

			promise.wrap result, internal

		fetch: (options, internal = false) ->
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
				# update state on delegate
				if !model.set model.parse(resp, options), options
					return false
				model.trigger 'sync', model, resp, options

			result = attemptRequest
				method: 'read'
				instance: model
				options: options
				delegateSuccess: delegateSuccess

			promise.wrap result, internal

		subscribe: ->
			if @isNew()
				self = @
				@once "change:#{@idAttribute}", -> self.subscribe()
				return

			if @subscribed
				return
			
			@subscribed = true

			modelName = _.result @, 'modelName'

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
				e = _.clone e
				action = e.data[keys.messageAction]
				if !action?
					@trigger "#{prefix}messaged", @, e.data, e
				else
					@trigger "#{prefix}#{action}", @, e.data, e

		constructor: (attrs, options)->
			super

			if !@modelName?
				if !(@modelName = @collection.modelName)?
					modelNameError()
			@modelName = @modelName.toLowerCase()
			@urlRoot = -> "/#{_.result(@, 'modelName')}"

			# subscribe on create
			@subscribe()

			# copy instance config options
			if options?
				for key in keys.model
					if options[key]?
						@[configPrefix + key] = options[key]

	class FakeModel extends Sails.Model
		modelName: '/fake'

	messageCollection = (coll, url, namespace, data = {}, options = {}, internal = false)->
		if _.isObject namespace
			options = data
			data = namespace
		else
			data[keys.messageAction] = namespace

		options.method = "POST"
		options.url = url
		wrapPayload data, options

		request = null
		if isAssociated coll # associated collection constructs with a model and a key
			request = new (coll.constructor)(coll.associated.model, coll.associated.key)
		else request = new (coll.constructor)()

		state = getConfig 'state', options, coll
		## server state will message models specified by filter clauses on the server side
		if state == 'server'
			# copy instance level config
			for key in keys.filter
				request[configPrefix + key] = coll[configPrefix + key]
			# guarantee a where clause to make sails happy
			options.where = getConfig('where', options, coll) || {}
			# send up the request
			return request.fetch options

		## client state will message model instances currently in the collection
		else if state == 'client' || true
			if !coll.size()
				return promise.wrap($.Deferred().resolve(), internal)
			else
				options.where = {}

				# to keep as single request, send id's down as where clause
				idAttr = coll.at(0).idAttribute
				options.where[idAttr] = []
				for m in coll.models
					if !m.isNew() # only message persisted models
						options.where[idAttr].push m.id

				return request.fetch options

	class Sails.Collection extends Backbone.Collection

		# default model
		model: Sails.Model

		query: configure
		configure: configure

		message: (namespace, data, options) ->
			messageCollection(@, "/#{@modelName}/message", namespace, data, options)

		fetch: (options, internal = false) ->
			options = if options then _.clone(options) else {}
			if !options.parse? then options.parse = true
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

			result = attemptRequest
				method: 'read'
				instance: this
				options: options
				delegateSuccess: delegateSuccess

			promise.wrap result, internal

		subscribe: ->
			if @subscribed
				return
				
			@subscribed = true
			
			modelName = _.result @, 'modelName'
			
			# first register
			register modelName
			
			# then listen
			prefix = Sails.config.eventPrefix
			aggregator = Sails.Models[modelName]

			@listenTo aggregator, "created", (e) ->
				@trigger "#{prefix}created", e.data, e
		
		constructor: (models, options)->
			super

			if !@modelName?
				modelNameError()
			@modelName = @modelName.toLowerCase()
			@url = -> "/#{_.result(@, 'modelName')}"

			# subscribe on create
			@subscribe()

			# copy instance config options
			if options?
				for key in keys.collection
					if options[key]?
						@[configPrefix + key] = options[key]

	Sails.Associated = (Collection)->

		coll = new Collection()

		if !coll.modelName?
			modelNameError()

		previousModelName = coll.modelName
		PreviousModel = _.result(coll, 'model') || Sails.Model

		class AssociatedModel extends PreviousModel

			save: (key, val = {}, options = {}, internal = false)->
				defer = $.Deferred()
				self = @
				twoArgs = _.isNull key || _.isObject key
				opts = if twoArgs then val else options

				if @isNew()
					# POST /model/id/assoc = create & addTo
					opts.url = @collection.url()
					createAndAddTo = super(key, val, options, true)
					createAndAddTo.done ->
						self.associated.added = true
					promise.chain createAndAddTo, defer
				else
					# PUT /associatedmodel/associd = update
					if twoArgs then update = super(key, _.clone(val), options, true)   # val is options
					else update = super(key, val, _.clone(options), true)              # options is options

					if !@associated.added
						opts.url = @collection.url()
						opts.method = "POST"

						# after update
						# POST /model/id/assoc = addTo
						add = ->
							addTo = super(key, val, options, true)
							addTo.done ->
								self.associated.added = true
								defer.resolve.apply defer, arguments
								#promise.chain update, defer
							addTo.fail ->
								defer.reject.apply defer, arguments

						update.done ->
							add.call(self)
						update.fail ->
							defer.reject.apply defer, arguments
					else
						promise.chain update, defer

				promise.wrap defer.promise(), internal

			destroy: (options = {}, internal = false) ->
				# DELETE /model/id/assoc = removeFrom
				wrapId @, options
				promise.wrap super(options, true), internal

			constructor: ->
				@modelName = previousModelName

				super

				@associated = @collection.associated

		class AssociatedCollection extends Collection

			# these are here to coerce to the internal model
			add: (model, options)->
				if _.isArray model
					array = _.map model, (m)->
						m.attributes || m
					super array, options
				else
					m = model.attributes || model
					super m, options
			push: (model, options)->
				m = model.attributes || model
				super m, options
			unshift: (model, options)->
				m = model.attributes || model
				super m, options

			message: (namespace, data, options)->
				messageCollection(@, "/#{previousModelName}/message", namespace, data, options)

			subscribe: ->
				if @subscribed
					return

				@subscribed = true

				model = @associated.model
				key = @associated.key
				prefix = Sails.config.eventPrefix

				# no need to register, will have been done
				# in  model constructor

				aggregator = Sails.Models[model.modelName][model.id]

				@listenTo aggregator, "addedTo", (e) ->
					if e.id = model.id && e.attribute == key
						@trigger "#{prefix}addedTo", e.addedId, e

				@listenTo aggregator, "removedFrom", (e) ->
					if e.id = model.id && e.attribute == key
						@trigger "#{prefix}removedFrom", e.removedId, e

			constructor: (model, key, options) ->
				if model.isNew()
					idError()

				if !model.modelName?
					modelNameError()

				@modelName = "#{model.modelName}/#{model.id}/#{key}"

				# override the model name if there is one
				@model  = AssociatedModel.extend modelName: @modelName

				@associated =
					model: model
					key: key

				# subscribe on create, will suppress any super subscriptions
				@subscribe()

				# attempt to instantiate via populated attribute
				super model.attributes[key], options

				for model in @models
					# if populated, assume 'added'
					model.associated.added = true

		AssociatedCollection

	Backbone.Sails = Sails

)(Backbone, $, _)