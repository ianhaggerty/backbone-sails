_ = require 'lodash'

JSONP_CALLBACK_PARAM = 'callback'

module.exports =
	## Given a Waterline query, populate the appropriate/specified
	# association attributes and return it so it can be chained
	# further ( i.e. so you can .exec() it )
	#
	# @param  {Query} query         [waterline query object]
	# @param  {Request} req
	# @return {Query}
	populateEach: (query, req) ->
		DEFAULT_POPULATE_LIMIT = sails.config.blueprints.defaultLimit || 30

		options = req.options
		populate = options.parsed_populate || (options.parsed_populate = module.exports.parsePopulate(req))

		if (populate == true) || (!populate? && options.populate)
			# populate all with default populate limit
			for alias, association of options.associations
				query = query.populate association.alias, limit: DEFAULT_POPULATE_LIMIT

		else if _.isObject(populate)
			aliasFilter = _.pluck options.associations, 'alias'
			# populate according to criteria, if exists at all
			for alias, criteria of populate
				if _.contains aliasFilter, alias
					query = if _.isObject criteria
						query.populate alias, criteria
					else
						query.populate alias

		query

	populateNull: (records, req) ->
		if !_.isArray records
			records = [records]
			result = records[0]
		else
			result = records

		options = req.options

		populate = options.parsed_populate || (options.parsed_populate = module.exports.parsePopulate(req))

		if (populate == true) || (!populate? && options.populate)
			for alias, association of options.associations
				for record in records
					if !record[alias]?
						record[alias] = null

		else if _.isObject(populate)
			aliasFilter = _.pluck options.associations, 'alias'
			for alias, criteria of populate
				for record in records
					if _.contains(aliasFilter, alias) && !record[alias]?
						record[alias] = null

		result

	populateAll: (query, req)->
		associations = req.options.associations

		for alias, association of associations
			query = query.populate association.alias

		query

	flattenAssociations: (records, Model)->
		if !_.isArray records
			records = [records]
			result = records[0]
		else
			result = records

		aliases = _.pluck Model.associations, 'alias'

		for association in Model.associations
			nestedModel = sails.models[association[association.type]]
			for record in records
				if _.isArray record[association.alias]
					for nested, i in record[association.alias]
						if nested[nestedModel.primaryKey]?
							record[association.alias][i] = nested[nestedModel.primaryKey]
						else
							# don't allow create
							record[association.alias][i] = null
				else if _.isObject record[association.alias]
					if record[association.alias][nestedModel.primaryKey]?
						record[association.alias] = nested[nestedModel.primaryKey]
					else
						# don't allow to create
						record[association.alias] = null

		result


  ## Subscribe deep (associations)
	subscribeDeep: (req, record) ->
		_.each req.options.associations, (assoc)->

			# Identity of associated model
			ident = assoc[assoc.type]
			AssociatedModel = sails.models[ident]

			if assoc.type == 'collection' && record[assoc.alias]
				for record in record[assoc.alias]
					if record[AssociatedModel.primaryKey]?
						AssociatedModel.subscribe req, record

			else if assoc.type == 'model' && record[assoc.alias]?[AssociatedModel.primaryKey]?
				AssociatedModel.subscribe req, record[assoc.alias]

	## Parse primary key value for use in a Waterline criteria
	# (e.g. for `find`, `update`, or `destroy`)
	#
	# @param  {Request} req
	# @return {Integer|String}
	parsePk: (req) ->
		pk = req.options.id || req.param('id')

		# exclude criteria on id field
		pk = if _.isPlainObject(pk) then undefined else pk

	## Parse primary key value from parameters.
	# Throw an error if it cannot be retrieved.
	#
	# @param  {Request} req
	# @return {Integer|String}

	requirePk: (req) ->
		pk = module.exports.parsePk(req)

		if !pk
			err = new Error 'No `id` parameter provided. (Note: even if the models primary key is not named `id` - `id` should be used as the name of the parameter - it will be mapped to the proper primary key name)'
			err.status = 400
			throw err

		pk

	## Parse `criteria` for a Waterline `find` or `update` from all request parameters.
	#
	# @param {Request} req
	# @return {Object} The WHERE criteria object
	parseCriteria: (req) ->

		where = req.query.where || getHeader(req, 'where')

		if _.isString(where)
			where = tryToParseJSON(where)

		_.merge {}, req.options.where, where

	## Parse `values` for a Waterline `create` or `update` from all
	# request parameters.
	#
	# @param  {Request} req
	# @return {Object}
	parseValues: (req)->
		values = _.defaults req.body, req.params

		values = _.omit values, (v)-> _.isUndefined(v) # allow null to be persisted

		values

	parseData: (data, Model)->
		aliases = _.pluck Model.associations, 'alias'

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
				result.associated[alias].add.push aliasData[AssociatedModel.primaryKey] || aliasData


		for alias, aliasData of data

			if aliasData? && _.contains(aliases, alias)
				# associated data
				result.associated[alias] = { create:[], add: [] }
				association = result.associated[alias].association = _.findWhere Model.associations, alias: alias

				AssociatedModel = result.associated[alias].Model = sails.models[association[association.type]]

				if _.isArray aliasData
					if association.type == 'collection'
						for record in aliasData
							parseRecord(record, AssociatedModel)
				else if association.type == 'model'
					parseRecord(aliasData, AssociatedModel)
				else
					sails.log.warn "Could not parse attribute #{alias}:#{aliasData}. Type collection expects an array."

			else
				# raw
				result.raw[alias] = aliasData

		result

	## Determine the model class to use w/ this blueprint action.
	#
	# @param  {Request} req
	# @return {WLCollection}
	parseModel: (req)->
		model = req.options.model || req.options.controller
		if !model
			throw new Error('No "model" specified in route options.')

		Model = req._sails.models[model]
		if !Model
			throw new Error("Invalid route option, `model`.\n I don't know about any models named: #{model}")

		Model

	parseSort: (req)->
		query = req.query.sort || getHeader(req, 'sort')  || req.options.sort|| undefined

		if _.isString(query)
			sort = tryToParseJSON(query)

		if !sort
			sort = query

		sort
		
	parsePopulate: (req)->
		query = req.query.populate || getHeader(req, 'populate') || req.options.populate || undefined

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

	parseLimit: (req)->
		DEFAULT_LIMIT = sails.config.blueprints.defaultLimit || 30
		limit = req.query.limit || getHeader(req, 'limit') || (if req.options.limit? then req.options.limit else DEFAULT_LIMIT)
		if limit then limit = +limit
		limit

	parseSkip: (req)->
		DEFAULT_SKIP = 0
		skip = req.query.skip || getHeader(req, 'skip') || (if req.options.skip? then req.options.skip else DEFAULT_SKIP)
		if skip then skip = +skip
		skip

	mirror: (Model, alias)->
		if Model._attributes[alias]?.via == (mirrorAlias = '_' + alias) && Model._attributes[mirrorAlias]?.via == alias
			mirrorAlias
		else
			false

tryToParseJSON = (json)->
	if !_.isString(json) then return null
	try
		JSON.parse(json)
	catch e
		null

defaultHeaderPrefix = 'sails-'
getHeader = (req, key, prefix)->
	if prefix? then key = prefix + key
	header = req.header?(key) || (req.headers?[key]? && req.headers[key]) || req.get?(key)
	if !header? && !prefix? then getHeader(req, key, defaultHeaderPrefix) else header