Sails = Backbone.Sails

Sails.configure
	promise: (promise)-> Promise.resolve(promise)

jasmine.DEFAULT_TIMEOUT_INTERVAL = 20000

class Model extends Sails.Model
	modelName: "testmodel"
class Collection extends Sails.Collection
	modelName: "testmodel"
	model: Model
AssociatedCollection = Sails.Associated Collection

socketConnected = ->
	io.socket?.socket?.connected
connect = ->
	io.socket.socket.connected = true
disconnect = ->
	io.socket.socket.connected = false
onConnect = (cb) ->
	handle = ->
		if socketConnected()
			cb()
		else
			setTimeout handle, 50
	handle()
wait = (delay)->
	new Promise (res) ->
		setTimeout res, delay

numbers =
	one: 1
	two: 2
	three: 3
	four: 4
	five: 5
	six: 6
	seven: 7
	eight: 8
	nine: 9
	ten: 10

models =
	deleteAll: ->
		coll = new Collection()
		coll.configure
			limit: 1000000
		coll.fetch().then ->
			copy = coll.models.slice()
			deleting = for m in copy
				m.destroy()
			Promise.all deleting
	populate: ->
		coll = new Collection()
		for key, num of numbers
			coll.push
				name: key
				value: num
		creating = for m in coll.models
			m.save()
		Promise.all creating
		.then ->
			addingTo = for m, i in coll.models
				# index = (i + 1) % (coll.models.length)
				m.addTo 'tests', m
			Promise.all addingTo
	associate: ->
		m = new Model name: "master"
		m.save().then ->
			addingTo = for key, val of numbers
				m.addTo 'tests',
					name: key
					value: val
			Promise.all addingTo
		.then ->
			m

getSpies = (number = 3)=>
	spies = {}
	for i in [0..number-1]
		spies[String.fromCharCode(i + 'a'.charCodeAt(0))] = ->
	for key of spies
		spyOn spies, key
	spies
socketOnly = =>
	beforeEach (done)->
		onConnect done
ajaxOnly = =>
	beforeEach (done)->
		onConnect ->
			disconnect()
			done()
	afterEach ->
		connect()
populate = =>
	beforeEach (done)->
		models.deleteAll().then ->
			models.populate()
		.then ->
			done()

describe "test utilities", ->

	socketOnly()

	deleteAll = =>
		it "should delete all model resources and resolve", (done)->
			coll = undefined
			populating = for i in [1..10]
				(new Model()).save()
			Promise.all(populating)
			.then ->
				models.deleteAll()
			.then ->
				coll = new Collection()
				coll.fetch()
			.then ->
				expect(coll.length).toEqual(0)
				done()

	describe "deleteAll", ->
		ajaxOnly()
		deleteAll()

	describe "deleteAll over socket", ->
		deleteAll()

	populate = =>
		it "should populate 10 models and add to 'tests'", (done)->
			coll = undefined
			models.deleteAll()
			.then ->
				models.populate()
			.then ->
				coll = new Collection [], { populate: 'tests' }
				coll.fetch()
			.then ->
				expect(coll.length).toEqual(10)
				for model in coll.models
					expect(model.get("tests")).toBeTruthy()
					expect(model.get("tests").length).toEqual(1)
				done()

	describe "populate", ->
		ajaxOnly()
		populate()

	describe "populate over socket", ->
		populate()

	associate = =>
		it "should associate ten models to master and resolve with master", (done)->
			models.associate().then (master)->
				expect(master).toBeTruthy()
				expect(master instanceof Backbone.Model).toEqual(true)
				expect(master.get("name")).toEqual("master")
				done()

	describe "associate", ->
		ajaxOnly()
		associate()

	describe "associate over socket", ->
		associate()

describe "Model", ->

	socketOnly()

	constructor = =>
		it "should construct as usual", ->
			m = new Model { name: "Ian" }
			expect(m.get("name")).toEqual("Ian")

		it "should parse the populate config option", (done)->
			name = "Ian"
			m = new Model { name: name }, { populate: "tests test" }
			m.save().then ->
				m.addTo 'tests', m
			.then ->
				m.fetch()
			.then ->
				tests = m.get("tests")
				test = m.get("test")
				expect(tests).toBeTruthy()
				expect(test).toBeTruthy()
				expect(tests[0].name).toEqual(name)
				expect(test.id).toEqual(m.id)
				done()

		it "should register the correct url from the modelName", ->
			m = new Model id: "123"
			expect(m.isNew()).not.toBeTruthy()
			expect(m.url()).toEqual('/testmodel/123')

		it "should override the urlRoot", ->
			M = Model.extend modelName: "user", urlRoot: "/false"
			m = new M id: "123"
			expect(m.isNew()).not.toBeTruthy()
			expect(m.url()).toEqual('/user/123')
			expect(m.urlRoot()).toEqual('/user')

		it "should parse the populate config option from the prototype", (done)->
			name = "Ian"
			M = Model.extend config: populate: "tests test"
			m = new M { name: name }
			m.save().then ->
				m.addTo 'tests', m
			.then ->
				m.fetch()
			.then ->
				tests = m.get("tests")
				test = m.get("test")
				expect(tests).toBeTruthy()
				expect(test).toBeTruthy()
				expect(tests[0].name).toEqual(name)
				expect(test.id).toEqual(m.id)
				done()

	describe "constructor", ->
		ajaxOnly()
		constructor()

	describe "constructor over socket", ->
		constructor()

	save = =>
		it "should save as usual", (done)->
			m = new Model()

			m.save().then ->
				expect(m.isNew()).not.toBeTruthy()
				done()

		it "should save with an optional key-val", (done) ->
			m = new Model()
			spies = getSpies(1)
			m.on "change:name", spies.a

			m.save "name", "Ian"
			.then ->
				expect(spies.a).toHaveBeenCalled()
				expect(m.get("name")).toEqual("Ian")
				done()

		it "should save with a key-val object", (done) ->
			m = new Model()
			spies = getSpies(1)
			m.on "change:name", spies.a

			m.save name: "Ian", value: 1
			.then ->
				expect(spies.a).toHaveBeenCalled()
				expect(m.get("name")).toEqual("Ian")
				expect(m.get("value")).toEqual(1)
				done()

		it "should update as usual", (done)->
			m = new Model()
			m1 = undefined

			m.save().then ->
				m1 = new Model m.attributes
				m.set("name", "Ian")
				m.save()
			.then ->
				m1.fetch()
			.then ->
				expect(m1.get("name")).toEqual("Ian")
				done()

		it "should use sockets if configured", (done)->
			m = new Model {}

			spies = f: ->
			spyOn spies, 'f'
			m.on 'sync', spies.f

			disconnect()
			m.save({}, sync: 'socket')
			wait(Sails.config.poll * 2).then ->
				expect(spies.f).not.toHaveBeenCalled()
				connect()
				wait(Sails.config.poll * 2)
			.then ->
				expect(spies.f).toHaveBeenCalled()
				done()

		it "should use ajax if configured", (done)->
			m = new Model {}

			spies = f: ->
			spyOn spies, 'f'
			m.on 'sync', spies.f

			disconnect()
			m.save({}, sync: 'ajax')
			wait(Sails.config.poll * 2).then ->
				expect(spies.f).toHaveBeenCalled()
				connect()
				done()

		it "should delegate to ajax if configured", (done)->
			m = new Model {}

			spies = f: ->
			spyOn spies, 'f'
			m.on 'sync', spies.f

			disconnect()
			m.save({}, sync: 'socket ajax')
			wait(Sails.config.poll * 2).then ->
				expect(spies.f).toHaveBeenCalled()
				connect()
				done()

		it "should parse the populate config option", (done)->
			model = undefined
			coll = undefined
			models.deleteAll().then ->
				models.populate()
			.then ->
				coll = new Collection()
				coll.fetch()
			.then ->
				model = coll.at(0)
				model = new Model model.attributes
				expect(model.get("tests")).not.toBeTruthy()
				model.save({}, populate: "tests")
			.then ->
				expect(model.get("tests")).toBeTruthy()
				done()

	describe "save", ->
		ajaxOnly()
		save()

	describe "save over socket", ->
		save()

	fetch = =>
		it "should fetch as usual", (done)->
			m = new Model name: "monica"
			m1 = undefined
			m.save().then ->
				m1 = new Model id: m.id
				m1.fetch()
			.then ->
				expect(m1.isNew()).not.toBeTruthy()
				expect(m1.get("name")).toEqual("monica")
				done()

		it "should parse the populate option", (done)->
			m = new Model name: "monica"
			m1 = undefined
			m.save().then ->
				m.addTo('tests', m)
			.then ->
				m1 = new Model id: m.id
				m1.fetch( populate: 'test' )
			.then ->
				expect(m1.isNew()).not.toBeTruthy()
				expect(m1.get("name")).toEqual("monica")
				expect(_.isObject m1.get("test")).toBeTruthy()
				expect(m1.get("test").name).toEqual("monica")
				done()

		it "should parse the sync option", (done)->
			m = new Model name: "Fred"
			spies = getSpies()
			m.save().then ->
				disconnect()
				m.on "sync", spies.a
				m.fetch( sync: "socket" )
				wait(Sails.config.poll * 2)
			.then ->
				expect(spies.a).not.toHaveBeenCalled()
				connect()
				wait(Sails.config.poll * 2)
			.then ->
				expect(spies.a).toHaveBeenCalled()
				done()
			.finally ->
				connect()

	describe "fetch", ->
		ajaxOnly()
		fetch()
	describe "fetch over socket", ->
		fetch()

	configure = =>
		it "should parse the populate option", (done) ->
			m = new Model()
			m.save().then ->
				m.addTo 'tests', m
			.then ->
				m.configure
					populate: 'test'
				m.fetch()
			.then ->
				expect(_.isObject m.get('test')).toBeTruthy()
				expect(m.get('test').id).toEqual(m.id)
				done()

		it "should parse the sync option", (done) ->
			m = new Model name: "Fred"
			spies = getSpies()
			m.save().then ->
				disconnect()
				m.on "sync", spies.a
				m.configure( sync: "socket" )
				m.fetch()
				wait(Sails.config.poll * 2)
			.then ->
				expect(spies.a).not.toHaveBeenCalled()
				connect()
				wait(Sails.config.poll * 2)
			.then ->
				expect(spies.a).toHaveBeenCalled()
				done()
			.finally ->
				connect()

		it "should nullify any inherited options with false", (done) ->
			M = Model.extend config: populate: "test"
			m = new M name: "Fred"
			m.save().then ->
				m.addTo 'tests', m
			.then ->
				m.fetch()
			.then ->
				expect(_.isObject m.get("test")).toEqual(true)
				m.configure "populate", false
				m.fetch()
			.then ->
				expect(_.isObject m.get("test")).toEqual(false)
				done()

	describe "configure", ->
		ajaxOnly()
		configure()

	describe "configure over socket", ->
		configure()

	addTo = =>
		it "should add a new record", (done)->
			m = new Model( name: "addToMe"); added = undefined;
			m.save().then ->
				added = new Model( name: "added" )
				m.addTo 'tests', added
			.then ->
				added.fetch populate: 'test'
			.then ->
				expect(_.isObject added.get("test")).toBeTruthy()
				expect(added.get("test").name).toEqual("addToMe")
				done()

		it "should add a pojo", (done)->
			m = new Model( name: "addToMe"); added = undefined
			m.save().then ->
				added = name: "addMeTo"
				m.addTo 'tests', added
			.then (res)->
				added = new Model res
				added.fetch populate: 'test'
			.then ->
				expect(added.get("name")).toEqual("addMeTo")
				expect(_.isObject added.get("test")).toEqual(true)
				expect(added.get("test").name).toEqual("addToMe")
				done()

		it "should add an existing record", (done) ->
			m = new Model name: "existing"
			m1 = undefined
			m.save().then ->
				m1 = new Model "addToMe"
				m1.save()
			.then ->
				m1.addTo 'tests', m
			.then ->
				m1.fetch populate: 'tests'
			.then ->
				expect(_.isArray (m1.get('tests'))).toBeTruthy()
				expect(m1.get('tests').length).toBeTruthy()
				expect(m1.get('tests')[0].name).toEqual('existing')
				done()

	describe "addTo", ->
		ajaxOnly()
		addTo()
	describe "addTo over socket", ->
		addTo()

	removeFrom = =>
		it "should remove an existing record", (done)->
			m = new Model name: "removeFromMe"
			m1 = undefined
			m.save().then ->
				m1 = new Model name: "removeMeFrom"
				m.addTo 'tests', m1
			.then ->
				m.removeFrom 'tests', m1
			.then ->
				m.fetch populate: 'tests'
			.then ->
				expect(m.get('tests')).toBeTruthy()
				expect(m.get('tests').length).not.toBeTruthy()
				done()

		it "should remove an existing record whilst maintaining its state", (done)->
			m = new Model name: "removeFromMe"
			m1 = undefined
			m.save().then ->
				m1 = new Model name: "removeMeFrom"
				m.addTo 'tests', m1
			.then ->
				m.removeFrom 'tests', m1
			.then ->
				m.fetch populate: 'tests'
			.then ->
				expect(m.get('tests')).toBeTruthy()
				expect(m.get('tests').length).not.toBeTruthy()
				expect(m1.get('name')).toEqual('removeMeFrom')
				done()

		it "should remove a pojo with an id", (done)->
			m = new Model name: "removeFromMe"
			m1 = undefined
			m.save().then ->
				m1 = new Model "removeMeFrom"
				m.addTo 'tests', m1
			.then ->
				m.removeFrom 'tests', m1.attributes
			.then ->
				m.fetch populate: 'tests'
			.then ->
				expect(m.get('tests')).toBeTruthy()
				expect(m.get('tests').length).not.toBeTruthy()
				done()

	describe "removeFrom", ->
		ajaxOnly()
		removeFrom()
	describe "removeFrom over socket", ->
		removeFrom()

	describe "events", ->

		describe "addedTo", ->

			it "should fire when a record is added to", (done)->
				m = new Model()
				m1 = undefined
				spies = undefined
				addMe = undefined
				m.save().then ->
					m1 = new Model m.attributes # should subscribe on construct
					spies = getSpies()
					m1.on "addedTo", spies.a
					m1.on "addedTo:tests", spies.b
					addMe = new Model name: 'added'
					m.addTo 'tests', addMe
				.then ->
					expect(spies.a).toHaveBeenCalled()
					expect(spies.b).toHaveBeenCalled()
					addedToArgs = spies.a.calls.argsFor(0)
					expect(addedToArgs[0]).toEqual(m1)
					expect(addedToArgs[1]).toBeTruthy() # socket event
					addedToTestsArgs = addedToArgs = spies.b.calls.argsFor(0)
					expect(addedToTestsArgs[0]).toEqual(m1)
					expect(addedToTestsArgs[1]).toEqual(addMe.id)
					expect(addedToTestsArgs[2]).toBeTruthy() # socket event
					done()

			# TODO - sails doesn't like this
			xit "should fire when a record is addedTo via a save request", (done)->
				m = new Model()
				m1 = undefined
				spies = undefined
				addMe = undefined
				m.save().then ->
					m1 = new Model m.attributes # should subscribe on construct
					spies = getSpies()
					m1.on "addedTo", spies.a
					m1.on "addedTo:tests", spies.b
					m.set 'tests', [{ name: 'added' }]
					m.save()
				.then ->
					expect(spies.a).toHaveBeenCalled()
					expect(spies.b).toHaveBeenCalled()
					addedToArgs = spies.a.calls.argsFor(0)
					expect(addedToArgs[0]).toEqual(m1)
					expect(addedToArgs[1]).toBeTruthy() # socket event
					addedToTestsArgs = addedToArgs = spies.b.calls.argsFor(0)
					expect(addedToTestsArgs[0]).toEqual(m1)
					expect(addedToTestsArgs[1]).toBeTruthy() # id of added
					expect(addedToTestsArgs[2]).toBeTruthy() # socket event
					expect(addedToTestsArgs[1]).toEqual(addedToTestsArgs[2].addedId)
					done()

		describe "removedFrom", ->
			
			it "should fire when a record is removed from", (done)->
				m = new Model()
				m1 = undefined
				spies = undefined
				removeMe = undefined
				m.save().then ->
					m1 = new Model m.attributes # should subscribe on construct
					spies = getSpies()
					m1.on "removedFrom", spies.a
					m1.on "removedFrom:tests", spies.b
					removeMe = new Model name: 'added'
					m.addTo 'tests', removeMe
				.then ->
					m.removeFrom 'tests', removeMe
				.then ->
					expect(spies.a).toHaveBeenCalled()
					expect(spies.b).toHaveBeenCalled()
					removedFromArgs = spies.a.calls.argsFor(0)
					expect(removedFromArgs[0]).toEqual(m1)
					expect(removedFromArgs[1]).toBeTruthy() # socket event
					removedFromTestsArgs = removedFromArgs = spies.b.calls.argsFor(0)
					expect(removedFromTestsArgs[0]).toEqual(m1)
					expect(removedFromTestsArgs[1]).toEqual(removeMe.id)
					expect(removedFromTestsArgs[2]).toBeTruthy() # socket event
					done()

			# TODO sails doesn't like this
			xit "should fire when a record is removed from via a save request", (done)->
				m = new Model()
				m1 = undefined
				spies = undefined
				removeMe = undefined
				m.save().then ->
					m1 = new Model m.attributes # should subscribe on construct
					spies = getSpies()
					m1.on "removedFrom", spies.a
					m1.on "removedFrom:tests", spies.b
					removeMe = new Model name: 'added'
					m.addTo 'tests', removeMe
				.then ->
					m.set 'tests', []
					m.save()
				.then ->
					expect(spies.a).toHaveBeenCalled()
					expect(spies.b).toHaveBeenCalled()
					removedFromArgs = spies.a.calls.argsFor(0)
					expect(removedFromArgs[0]).toEqual(m1)
					expect(removedFromArgs[1]).toBeTruthy() # socket event
					removedFromTestsArgs = removedFromArgs = spies.b.calls.argsFor(0)
					expect(removedFromTestsArgs[0]).toEqual(m1)
					expect(removedFromTestsArgs[1]).toEqual(removeMe.id)
					expect(removedFromTestsArgs[2]).toBeTruthy() # socket event
					done()

		describe "destroyed", ->

			it "should fire when a record is deleted", (done)->
				model = new Model()
				spies = getSpies()
				model.on "destroyed", spies.a
				model.save().then ->
					m = model.clone()
					m.destroy()
				.then ->
					expect(spies.a).toHaveBeenCalled()
					args = spies.a.calls.argsFor(0)
					expect(args[0]).toEqual(model)
					expect(args[1]).toBeTruthy()
					expect(args[1].id).toEqual(model.id)
					done()

		describe "updated", ->
			it "should fire when a record is updated", (done)->
				model = new Model()
				spies = getSpies()
				model.save().then ->
					m = new Model model.attributes
					model.on "updated", spies.a
					model.on "updated:name", spies.b
					m.set "name", "something"
					m.save()
				.then ->
					expect(spies.a).toHaveBeenCalled()
					expect(spies.b).toHaveBeenCalled()
					updatedArgs = spies.a.calls.argsFor(0)
					expect(updatedArgs[0]).toEqual(model)
					expect(updatedArgs[1]).toBeTruthy()
					expect(updatedArgs[1].id).toEqual(model.id)
					updatedNameArgs = spies.b.calls.argsFor(0)
					expect(updatedNameArgs[0]).toEqual(model)
					expect(updatedNameArgs[1]).toEqual('something')
					expect(updatedNameArgs[2]).toBeTruthy()
					expect(updatedNameArgs[2].id).toEqual(model.id)
					done()

			it "shouldn't fire if the attribute is the same on the client side", (done)->
				model = new Model name: "something"
				spies = getSpies()
				model.save().then ->
					m = new Model model.attributes
					model.on "updated:name", spies.b
					m.set "name", "something"
					m.save()
				.then ->
					expect(spies.b).not.toHaveBeenCalled()
					done()

		describe "messaged", (done) ->

			it "should fire on a model that is messaged serverside", (done) ->
				model = new Model()
				m = undefined
				spies = getSpies()
				model.save().then ->
					m = new Model model.attributes
					m.on "messaged", spies.a
					model.on "messaged", spies.b
					model.message
						some: "data"
				.then ->
					expect(spies.a).toHaveBeenCalled()
					expect(spies.b).toHaveBeenCalled()
					args = spies.a.calls.argsFor(0)
					expect(args[0]).toEqual(m)
					expect(args[1]).toBeTruthy()
					expect(args[1].some).toEqual("data")
					expect(args[2]).toBeTruthy()
					expect(args[2].id).toEqual(m.id)
					done()

			it "should fire a custom event string, if passed", (done) ->
				model = new Model()
				m = undefined
				spies = getSpies()
				model.save().then ->
					m = new Model model.attributes
					m.on "custom", spies.a
					model.on "custom", spies.b
					model.message "custom",
						some: "data"
				.then ->
					expect(spies.a).toHaveBeenCalled()
					expect(spies.b).toHaveBeenCalled()
					args = spies.a.calls.argsFor(0)
					expect(args[0]).toEqual(m)
					expect(args[1]).toBeTruthy()
					expect(args[1].some).toEqual("data")
					expect(args[2]).toBeTruthy()
					expect(args[2].id).toEqual(m.id)
					done()

describe "Collection", ->

	socketOnly()

	constructor = =>
		it "should construct as usual", ->
			coll = new Collection()
			expect(coll.size()).toEqual(0)
			coll = new Collection [{}]
			expect(coll.size()).toEqual(1)

		it "should construct from a set of pojos, coercing to a model", ->
			coll = new Collection [
				{ name: "Fred" }
				{ name: "Jack" }
				{ name: "Bob" }
			]
			expect(coll.size()).toEqual(3)
			m0 = coll.at(0)
			expect(m0 instanceof Sails.Model).toEqual(true)
			expect(m0.get("name")).toEqual("Fred")

		it "should construct from a set of models", ->
			coll = new Collection [
				new Backbone.Model { name: "Fred" }
				new Backbone.Model { name: "Jack" }
				new Backbone.Model { name: "Bob" }
			]
			expect(coll.size()).toEqual(3)
			m0 = coll.at(0)
			expect(m0 instanceof Sails.Model).toEqual(false)
			expect(m0.get("name")).toEqual("Fred")

		it "should parse config options from the options object", (done)->
			coll = new Collection [], { populate: 'tests' }
			coll.fetch().then ->
				coll.forEach (m)->
					expect(m.get('tests')).toBeTruthy()
					done()

		it "should parse config options from the config prototype object", (done)->
			Coll = Collection.extend
				config: populate: 'tests'
			coll = new Coll()
			coll.fetch().then ->
				coll.forEach (m)->
					expect(m.get('tests')).toBeTruthy()
					done()

	describe "constructor", ->
		ajaxOnly()
		constructor()

	describe "constructor over socket", ->
		constructor()


	fetch = =>
		it "should fetch as usual", (done) ->
			coll = new Collection()
			coll.fetch().then ->
				expect(coll.size()).toEqual(10)
				done()

		it "should fetch according to instance limit criteria", (done) ->
			coll = new Collection()
			coll.query limit: 5
			coll.fetch().then ->
				expect(coll.size()).toEqual(5)
				done()

		it "should fetch according to option limit criteria", (done) ->
			coll = new Collection [], limit: 5
			coll.fetch().then ->
				expect(coll.size()).toEqual(5)
				done()

		it "should fetch according to constructor limit criteria", (done) ->
			Coll = Collection.extend config: limit: 5
			coll = new Coll()
			coll.fetch().then ->
				expect(coll.size()).toEqual(5)
				done()

	describe "fetch", ->
		ajaxOnly()
		populate()
		fetch()

	describe "fetch over socket", ->
		populate()
		fetch()

	query = =>
		it "should limit results", (done)->
			coll = new Collection()
			coll.query limit: 5
			coll.fetch().then ->
				expect(coll.size()).toEqual(5)
				coll.query "limit", 3
				coll.fetch()
			.then ->
				expect(coll.size()).toEqual(3)
				done()

		it "should sort results", (done)->
			coll = new Collection()
			coll.query sort: "name ASC"
			coll.fetch().then ->
				for i in [0..(coll.models.length - 2)]
					expect(coll.models[i].get("name")).toBeLessThan(coll.models[i+1].get("name"))
				coll.query "sort", "name DESC"
				coll.fetch()
			.then ->
				for i in [0..(coll.models.length - 2)]
					expect(coll.models[i+1].get("name")).toBeLessThan(coll.models[i].get("name"))
				coll.query sort: value: 1 # value ascending
				coll.fetch()
			.then ->
				for i in [0..(coll.models.length - 2)]
					expect(coll.models[i].get("value")).toBeLessThan(coll.models[i+1].get("value"))
				done()

		it "should skip results", (done)->
			coll = new Collection();
			m1 = undefined; m2 = undefined;
			coll.query "sort", "createdAt ASC"
			coll.query "skip", 0
			coll.fetch().then ->
				m1 = coll.at(1)
				coll.query "skip", 1
				coll.fetch().then ->
					m2 = coll.at(0)
					expect(m1.id).toEqual(m2.id)
					done()

		describe "where", ->
			it "should filter by contains", (done)->
				coll = new Collection()
				coll.query where: name: contains: 'on'
				coll.fetch().then ->
					coll.forEach (m)->
						expect(_.contains m.get("name"), 'on').toEqual(true)
					done()

			it "should filter by startsWith", (done)->
				Coll = Collection.extend  config: where: name: startsWith: 'o'
				coll = new Coll()
				coll.fetch().then ->
					coll.forEach (m)->
						expect(_.first m.get("name")).toEqual('o')
					done()

			it "should filter by a literal", (done)->
				coll = new Collection [], where: name: 'one'
				coll.fetch().then ->
					coll.forEach (m)->
						expect(m.get("name")).toEqual('one')
					done()

			it "should filter an array as an OR clause", (done)->
				coll = new Collection()
				coll.query "where", name: ['one', 'two']
				coll.fetch().then ->
					coll.forEach (m)->
						name = m.get("name")
						test = (name == 'one' || name == 'two')
						expect(test).toEqual(true)
					done()

			it "should filter by the less than or equal clause", (done)->
				coll = new Collection()
				coll.fetch where: value: '<=': 6
				.then ->
					coll.forEach (m)->
						expect(m.get('value')).toBeLessThan(7)
					done()

		describe "populate", ->

			it "should populate according to a string", (done)->
				Sails.configure
					populate: "tests"
				coll = new Collection()
				coll.fetch().then ->
					coll.forEach (m)->
						expect(m.get("tests")).toBeTruthy()
					coll.query populate: "test"
					coll.fetch()
				.then ->
					coll.forEach (m)->
						expect(_.isObject m.get("test")).toEqual(true)
						expect(m.get("test").id).toBeTruthy()
					done()
				.finally ->
					Sails.configure
						populate: false

			it "should populate according to an array", (done)->
				Coll = Collection.extend
					config:
						populate: ['tests', 'test']
				coll = new Coll()
				coll.fetch().then ->
					coll.forEach (m)->
						expect(_.isArray m.get("tests")).toEqual(true)
						expect(m.get("tests").length).toEqual(1)
						expect(_.isObject m.get("test")).toEqual(true)
					coll.query populate: ['test']
					coll.fetch()
				.then ->
					coll.forEach (m)->
						if _.isArray m.get("tests")
							expect(m.get("tests").length).toEqual(0)
						expect(_.isObject m.get("test")).toEqual(true)
					done()

	describe "query", ->
		ajaxOnly()
		populate()
		query()

	describe "query over socket", ->
		populate()
		query()

	describe "message", ->
		socketOnly()
		populate()

		it "should send and receive a message on the records referenced", (done)->
			coll = new Collection()
			spies = getSpies()
			coll.fetch( limit: 3, sort: "createdAt ASC" ).then ->
				coll.at(0).on "messaged", spies.a
				coll.at(1).on "messaged", spies.b
				coll.at(2).on "messaged", spies.c
				coll.message({ some: "data" })
				.done ->
					expect(spies.a).toHaveBeenCalled()
					expect(spies.b).toHaveBeenCalled()
					expect(spies.c).toHaveBeenCalled()
					args = spies.a.calls.argsFor(0)
					expect(args[0]).toEqual(coll.at(0))
					expect(args[1]).toBeTruthy()
					expect(args[1].some).toEqual("data")
					done()

		it "should only send to the models specified by the query clauses", (done)->
			coll = new Collection()
			coll.query limit: 1000000
			spies = getSpies()
			coll.fetch().then ->
				coll.on "messaged", spies.a
				collection = new Collection()
				collection.query where: name: 'one'
				collection.message { some: 'data'}, { state: 'server' } # no need to fetch
			.then ->
				expect(spies.a).toHaveBeenCalled()
				argsArray = spies.a.calls.allArgs()
				for args in argsArray
					expect(args[0].get("name")).toEqual('one')
				done()
			.error ->
				console.log arguments

	describe "events", ->

		describe "created", ->

			it "should fire when a model is created", (done)->
				coll = new Collection()
				spies = getSpies()
				m = undefined
				coll.fetch().then ->
					coll.on "created", spies.a
					m = new Model()
					m.save()
				.then ->
					expect(spies.a).toHaveBeenCalled()
					args = spies.a.calls.argsFor(0)
					expect(args[0].id).toEqual(m.id)
					expect(args[1].data.id).toEqual(m.id)
					done()

			it "should fire when a new record is added to a record", (done)->
				coll = new Collection()
				spies = getSpies()
				m = new Model()
				m.save().then ->
					coll.fetch()
				.then ->
					coll.on "created", spies.a
					m.addTo 'tests', { name: "a pojo" }
				.then ->
					expect(spies.a).toHaveBeenCalled()
					done()

describe "Associated", ->

	socketOnly()

	describe "wrapper function", ->

		it "should return collection constructor", ->
			assoc = Sails.Associated(Collection)

			expect(assoc.prototype instanceof Backbone.Collection).toEqual(true)
			expect(assoc.prototype.model.prototype instanceof Backbone.Model).toEqual(true)

	constructor = =>
		it "should parse out query parameters and adhere to them", (done)->
			coll = undefined; assoc = undefined; master = undefined;
			models.deleteAll().then ->
				models.associate()
			.then ->
				coll = new Collection()
				coll.fetch()
			.then ->
				master = coll.where( name: "master" )[0]
				assoc = new AssociatedCollection master, 'tests',
					where: value: '<': 4
				assoc.fetch()
			.then ->
				assoc.forEach (m)->
					expect(m.get('value')).toBeLessThan(4)
					expect(m.get('test')).toEqual(master.id)
				done()

		it "should use a populated attribute to initially populate itself", (done)->
			models.associate().then (master)->
				master.query populate: 'tests'
				master.fetch()
				.then ->
					assoc = new AssociatedCollection master, 'tests'
					expect(assoc.size()).toEqual(10)
					assoc.forEach (m)->
						expect(m instanceof assoc.model).toEqual(true)
					done()

	describe "constructor", ->
		ajaxOnly()
		constructor()

		it "should construct from a model instance which is not new, and a key", (done)->
			model = new Model()
			model.save().then ->

				assoc = new AssociatedCollection model, 'tests'

				expect(assoc instanceof Backbone.Collection).toEqual(true)

				done()

	describe "constructor over socket", ->
		constructor()

	fetch = =>
		it "should fetch records from the associated model only", (done)->
			models.associate().then (master)->
				assoc = new AssociatedCollection master, 'tests'
				assoc.fetch()
				.then ->
					assoc.forEach (m)->
						expect(m.get('test')).toEqual(master.id)
					done()

		it "should parse where query param and adhere to them", (done)->
			models.associate().then (master)->
				assoc = new AssociatedCollection master, 'tests'
				assoc.fetch where: value: '>=': 5
				.then ->
					assoc.forEach (m)->
						expect(m.get('test')).toEqual(master.id)
						expect(m.get('value')).toBeGreaterThan(4)
					done()

		it "should parse sort query param and adhere to them", (done)->
			models.associate().then (master)->
				assoc = new AssociatedCollection master, 'tests', sort: name: 1
				assoc.fetch()
				.then ->
					for i in [0..(assoc.models.length - 2)]
						expect(assoc.models[i].get("name")).toBeLessThan(assoc.models[i+1].get("name"))
					done()

		it "should not populate any requested keys", (done)->
			models.associate().then (master)->
				assoc = new AssociatedCollection master, 'tests'
				assoc.query "populate", "test"
				assoc.fetch()
				.then ->
					assoc.forEach (m)->
						expect(_.isObject m.get('test')).toEqual(false)
					done()

	describe "fetch", ->
		ajaxOnly()
		fetch()

	describe "fetch over socket", ->
		fetch()

	save = =>
		it "should add a new record", (done)->
			spies = getSpies()
			models.associate().then (master)->
				master.on "addedTo:tests", spies.a
				assoc = new AssociatedCollection master, 'tests'
				assoc.on "addedTo", spies.b
				addMe = assoc.push name: "something"
				addMe.save()
				.then ->
					if socketConnected()
						expect(spies.a).toHaveBeenCalled()
						expect(spies.b).toHaveBeenCalled()
					expect(assoc.where( name: "something" )).toBeTruthy()
					done()

		it "should add an existing record", (done)->
			spies = getSpies()
			models.associate().then (master)->
				assoc = new AssociatedCollection master, 'tests'
				assoc.on "addedTo", spies.a
				master.on "addedTo", spies.b
				added = assoc.push master
				added.save()
				.then ->
					if socketConnected()
						expect(spies.a).toHaveBeenCalled()
						expect(spies.b).toHaveBeenCalled()
					expect(assoc.where( name: "master" )).toBeTruthy()
					expect(added.get("test")).toEqual(master.id)
					done()

		it "should update an existing record", (done)->
			spies = getSpies()
			models.associate().then (master)->
				assoc = new AssociatedCollection master, 'tests'
				assoc.fetch()
				.then ->
					m = assoc.at(0)
					clone = new Model m.attributes
					clone.set "name", "updated"
					m.on "updated:name", spies.a
					assoc.on "updated:name", spies.b
					clone.save()
					.then ->
						if socketConnected()
							expect(spies.a).toHaveBeenCalled()
							expect(spies.b).toHaveBeenCalled()
						expect(clone.get("name")).toEqual("updated")
						done()

	describe "save", ->
		ajaxOnly()
		save()

	describe "save over socket", ->
		save()

	destroy = =>
		it "should remove from an associated collection, when called", (done)->
			spies = getSpies()
			models.associate().then (master)->
				assoc = new AssociatedCollection master, 'tests'
				assoc.fetch().then ->
					model = assoc.at(0)
					assoc.on "removedFrom", spies.a
					model.destroy()
					.then ->
						if socketConnected()
							expect(spies.a).toHaveBeenCalled()
							argsA = spies.a.calls.argsFor(0)
							expect(argsA[0]).toEqual(model.id)
						expect(assoc.size()).toEqual(9)
						done()

	describe "destroy", ->
		ajaxOnly()
		destroy()
	describe "destroy over socket", ->
		destroy()

	fetchModel = =>
		it "should be able to fetch the state of an added model", (done)->
			models.associate().then (master)->
				assoc = new AssociatedCollection master, 'tests'
				assoc.fetch().then ->
					model = assoc.at(0)
					model.fetch()
					.then ->
						model.fetch()
					.then ->
						expect(model.hasChanged()).toEqual(false)
						done()

	describe "fetch model", ->
		ajaxOnly()
		fetchModel()
	describe "fetch model over socket", ->
		fetchModel()

	addPushUnshift = =>
		it "should coerce to the internal model and add to the collection", (done)->
			models.associate().then (master)->
				assoc = new AssociatedCollection master, 'tests'
				assoc.fetch()
				.then ->
					mPush = new Model name: "push"
					mAdd = new Model name: "add"
					mUnshift = new Model name: "unshift"
					mPush = assoc.push mPush
					mAdd = assoc.add mAdd
					mUnshift = assoc.unshift mUnshift
					saving = for model in assoc.models
						if model.isNew()
							model.save()
						else
							true
					Promise.all(saving).then ->
						assoc.fetch()
					.then ->
						expect(assoc.size()).toEqual(13)
						expect(mPush instanceof assoc.model).toEqual(true)
						expect(mAdd instanceof assoc.model).toEqual(true)
						expect(mUnshift instanceof assoc.model).toEqual(true)
						done()

	describe "add, push and unshift", ->
		ajaxOnly()
		addPushUnshift()
	describe "add, push and unshift over socket", ->
		addPushUnshift()

	describe "message", ->
		it "should still work for an associated collection", (done)->
			assoc = null; spies = getSpies();
			models.associate().then (master)->
				assoc = new AssociatedCollection master, 'tests', sort: createdAt: 1
				assoc.fetch()
			.then ->
				model = assoc.at(0)
				model.on "fire", spies.a
				assoc.on "fire", spies.b
				another = assoc.at(0)
				another.message "fire", { welcome: "to hell" }
				.then ->
					expect(spies.a).toHaveBeenCalled()
					expect(spies.b).toHaveBeenCalled()
					args = spies.a.calls.argsFor(0)
					expect(args[0]).toEqual(model)
					expect(args[1]).toBeTruthy()
					expect(args[1].welcome).toEqual('to hell')

					assoc.message("fire", { say: "hi" })
				.then ->
					expect(spies.b.calls.count()).toEqual(11)
					done()


#stressTest = =>
#	it "creating and deleting models", (done)->
#		start = Date.now()
#		number = 100
#		creating = for i in [1..number]
#			(new Model()).save()
#		Promise.all(creating).then ->
#			end = Date.now()
#			console.info "creating a record took #{Math.round((end - start)/number)}ms"
#
#			coll = new Collection [], limit: 1000000
#			coll.fetch().then ->
#				size = coll.size()
#				start = Date.now()
#				deleting = for m in coll.models.slice()
#					m.destroy()
#				Promise.all(deleting).then ->
#					end = Date.now()
#					console.info "deleting a record took #{Math.round((end - start)/size)}ms"
#					done()
#
#describe "stress test", ->
#	ajaxOnly()
#	stressTest()
#
#describe "stress test over socket", ->
#	socketOnly()
#	stressTest()

