###

  FYI: These are no ordinary jasmine specs. In order to run successfully, open up the tests page in two different browser windows. Both pages are designed to 'communicate' with each other.

  It things get messy/ go wrong, fire up sails console and run `TestCommunicay.destroy({}).exec(function(){})`. Try again.

  Open up console to see some helpful tips.

###

## Jasmine Config

jasmine.DEFAULT_TIMEOUT_INTERVAL = 15000

## Globals
Sails = Backbone.Sails

## Classes
class TestModel extends Sails.Model
	urlRoot: "/testmodel"

class TestCollection extends Sails.Collection
	url: "/testmodel"
	model: TestModel

class TestCommunicay extends Sails.Model
	urlRoot: "/testcommunicay"

class TestCommunicayCollection extends Sails.Collection
	url: "/testcommunicay"
	model: TestCommunicay

AssociatedTestCollection = Sails.Associated TestCollection

## Collection Instances
testColl = new TestCollection()
testCommColl = new TestCommunicayCollection()

## Utility

MAX_INT = 9007199254740992

chainPromise = (from, to) ->
	from.done ->
		to.resolve.apply to, arguments
	.fail ->
		to.reject.apply to, arguments

connect = ->
	io.socket.socket.connected = true

disconnect = ->
	io.socket.socket.connected = false

socketConnected = ->
	io.socket.socket.connected

deferDelay = 100
socketConnecting = (defer = $.Deferred())->
	if socketConnected()
		defer.resolve()
	else
		setTimeout ->
			socketConnecting(defer)
		, deferDelay

	defer.promise()

deleteAll = (coll) ->
	defer = $.Deferred()
	coll.query().limit(MAX_INT)
	coll.fetch().done ->
		promises = []
		models = coll.models.slice() # keep an external reference since deleting models
		for model in models
			promises.push model.destroy()
		chainPromise $.when(promises), defer
	defer.promise()

fail = ->
	console.error "fail...", arguments

wait = (time) ->
	defer = $.Deferred()
	setTimeout ->
		defer.resolve()
	, time
	defer.promise()

populateTestModels = ->
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

	promises = []

	for key, val of numbers
		m = testColl.push
			name: key
			value: val

		promises.push m.save()

	$.when(promises).promise()

first = undefined   # race condition indicating first window to the punch
delay = 50          # delay between first and last window for same spec
lastspec = false    # set to true for last spec
start = false       # boolean indicating to start

deleteAll(testColl)
.done ->
	populateTestModels()
	.done ->
		populateTestModels()
		.done ->
			start = true

okToStart = (defer = $.Deferred())->
	if start
		defer.resolve()
	else
		setTimeout ->
			okToStart(defer)
		, deferDelay

	defer.promise()

## The tests
describe "Backbone.Sails", ->
	beforeEach (done)->

		Sails.configure
			socketSync: true
			subscribe: false
			timeout: -> deferDelay

		okToStart().done ->

			testCommColl.fetch().done ->
				created = testCommColl.findWhere({ method: "start" })
				if !created
					console.warn "Open another freaking browser window to start the tests!", "Ya got fifteen seconds sonny, otherwise things 'll go real sour"
				else
					console.info "Starting next test... hold onto your hats"
				if !created
					creating = testCommColl.push method: "start"
					creating.save().done ->
						creating.once "updated:method", (creating, val) ->
							if val == "startok"
								creating.set "method", "starting"
								creating.save().done ->
									first = true
									done()
				else
					created.set "method", "startok"
					created.save().done ->
						created.once "updated:method", (m, val) ->
							if val == "starting"
								created.set "method", val
								created.destroy().then ->
									first = false
									setTimeout done, delay

	afterEach (done)->
		if first
			# wait for the destroy
			testCommColl.fetch().done ->
				if testCommColl.size() != 0
					testCommColl.once "destroyed", done
				else
					done()
		else
			if !lastspec
				# wait for the create
				testCommColl.fetch().done ->
					if testCommColl.size() == 0
						testCommColl.once "created", done
					else
						done()
			else
				done()

	describe "socket synced queries", ->

		describe "synced collection", ->

			it "should construct with an initial set of POJOS", ->
				models = [
					{ name: "Ian" }
					{ name: _.uniqueId() }
					{ name: _.uniqueId() }
				]

				newColl = new TestCollection(models)

				expect(newColl.size()).toEqual(3)
				expect(newColl.findWhere( name: "Ian" )).toBeTruthy()

			it "should construct with a set of models", ->
				models = [
					new Backbone.Model { name: "Ian" }
					new Backbone.Model { name: _.uniqueId() }
					new Backbone.Model { name: _.uniqueId() }
				]

				newColl = new TestCollection(models)

				expect(newColl.size()).toEqual(3)

				model = newColl.findWhere( name: "Ian" )

				expect(model).toBeTruthy()
				expect(model instanceof Backbone.Model).toBeTruthy()
				expect(model instanceof Sails.Model).not.toBeTruthy()

			it "should parse query parameters from contructor options", (done)->
				if !first

					models = []

					for i in [0..10]
						models.push
							value: i

					newColl = new TestCollection models,
						query:
							sort: "value ASC"
							limit: 5
							skip: 1

					expect(newColl.size()).toEqual(11)

					promises = []

					newColl.forEach (m) ->
						promises.push(m.save())

					$.when(promises).done ->
						newColl.fetch().done ->

							expect(newColl.at(0).get("value")).not.toEqual(0)
							expect(newColl.at(0).get("value")).toEqual(1)
							expect(newColl.size()).toEqual(5)

							done()

				else done()

			it "should parse socket options from the constructor options", (done)->
				newColl = new TestCollection [],
					socketSync: false
					subscribe: true

				expect(newColl._sails.subscribe).toEqual(true)
				expect(newColl._sails.socketSync).toEqual(false)

				spies =
					f: ->
					g: ->

				spyOn spies, 'f'
				spyOn spies, 'g'

				newColl.on "sync", spies.g
				newColl.on "socketSync", spies.f

				disconnect()

				newColl.fetch().done ->

					expect(spies.g).toHaveBeenCalled()
					expect(spies.f).not.toHaveBeenCalled()

					newColl.on "socketSync", ->
						expect(spies.f).toHaveBeenCalled()
						newColl.off "socketSync"
						newColl.off "sync"

						done()

					connect() # subscribe will resolve over sockets

			it "should parse socket options from the constructor options", (done)->
				newColl = new TestCollection [],
					socketSync: false
					subscribe: false # no resolution over sockets this time

				expect(newColl._sails.subscribe).toEqual(false)
				expect(newColl._sails.socketSync).toEqual(false)

				spies =
					f: ->
					g: ->

				spyOn spies, 'f'
				spyOn spies, 'g'

				newColl.on "sync", spies.g
				newColl.on "socketSync", spies.f

				disconnect()

				newColl.fetch().done ->

					expect(spies.g).toHaveBeenCalled()
					expect(spies.f).not.toHaveBeenCalled()

					connect()

					setTimeout ->
						expect(spies.f).not.toHaveBeenCalled()

						newColl.off "sync"
						newColl.off "socketSync"

						done()
					, deferDelay + delay

			it "should subscribe when requested", (done)->
				if !first

					newColl = new TestCollection()

					anotherColl = new TestCollection()

					spies =
						f: ->

					spyOn spies, 'f'

					newColl.on "created", spies.f

					newColl.subscribe().done ->

						m = anotherColl.push
							name: "something"

						m.save().done ->
							expect(spies.f).toHaveBeenCalled()

							done()

				else
					done()

			it "should parse socket options from the fetch options", (done)->
				if !first

					newColl = new TestCollection [],
						socketSync: true # fetch options should override these

					spies =
						f: ->
						g: ->
						h: ->
						i: ->

					spyOn spies, 'f'
					spyOn spies, 'g'
					spyOn spies, 'h'
					spyOn spies, 'i'

					newColl.on "sync", spies.f
					newColl.on "socketSync", spies.g
					newColl.on "error", spies.h
					newColl.on "socketError", spies.i

					disconnect()

					newColl.fetch
						socketSync: false
						subscribe: false
					.done ->
						expect(spies.f).toHaveBeenCalled()
						expect(spies.g).not.toHaveBeenCalled()
						expect(spies.h).not.toHaveBeenCalled()
						expect(spies.i).not.toHaveBeenCalled()

						newColl.fetch
							socketSync: false
							subscribe: true
						.done ->
							expect(spies.f.calls.count()).toEqual(2)
							expect(spies.g).not.toHaveBeenCalled()
							expect(spies.h).not.toHaveBeenCalled()
							expect(spies.i).not.toHaveBeenCalled()

							connect()

							newColl.once "subscribed", ->

								expect(spies.f.calls.count()).toEqual(3)
								expect(spies.g).toHaveBeenCalled()
								expect(spies.h).not.toHaveBeenCalled()
								expect(spies.i).not.toHaveBeenCalled()

								newColl.fetch
									url: "/fake"
								.always ->

									expect(spies.f.calls.count()).toEqual(3)
									expect(spies.g.calls.count()).toEqual(1)
									expect(spies.h).toHaveBeenCalled()
									expect(spies.i).toHaveBeenCalled()

									newColl.off "sync"
									newColl.off "socketSync"
									newColl.off "error"
									newColl.off "socketError"

									done()
				else
					done()

			it "should query according to limit criteria", (done) ->
				if !first

					newColl = new TestCollection [],
						query:
							sort: "value ASC"
							limit: 3

					newColl.fetch().done ->

						expect(newColl.size()).toEqual(3)

						newColl.query
							limit: 2
						.fetch().done ->

							expect(newColl.size()).toEqual(2)

							newColl.query().limit(3)

							newColl.fetch().done ->

								expect(newColl.size()).toEqual(3)

								done()
				else
					done()

			it "should query according to sort criteria", (done) ->

				if !first
					newColl = new TestCollection
						sort: "value ASC"
						where: value: '!': null

					newColl.fetch().done ->

						for i in [0..(newColl.size()-2)]
							expect(newColl.at(i).get("value")).not.toBeUndefined()
							expect(newColl.at(i).get("value") <= newColl.at(i+1).get("value")).toEqual(true)

						newColl.query
							sort: value : 1
							where: value: '!': null

						.fetch().done ->
							for i in [0..(newColl.size()-2)]
								expect(newColl.at(i).get("value") <= newColl.at(i+1).get("value")).toEqual(true)

							newColl.query().sort("value DESC")

							newColl.fetch().done ->
								for i in [0..(newColl.size()-2)]
									expect(newColl.at(i).get("value") >= newColl.at(i+1).get("value")).toEqual(true)

								done()
				else
					done()

			it "should query according to populate criteria", (done) ->
				if !first
					newColl = new TestCollection
						query: limit: 1000

					sup = newColl.push name: "super"
					sub = newColl.push name: "sub"

					sup.save().done ->
						sup.addTo('tests', sub).done ->

							newColl.query().where
								or: [
									{ name: "super" }
									{ name: "sub" }
								]
							.populate "tests"

							newColl.fetch().done ->
								sup = newColl.findWhere name: "super"
								sub = newColl.findWhere name: "sub"

								expect(sup).toBeTruthy()
								expect(sub).toBeTruthy()

								expect(sup.get("tests")).toBeTruthy()
								expect(sub.get("test")).toEqual(sup.id)

								done()
				else
					done()

			it "should query according to skip criteria", (done) ->
				if !first
					newColl = new TestCollection
						query:
							limit: 1000
							skip: 0
							sort: "createdAt"

					newColl.fetch().done ->
						m = newColl.at(1)

						newColl.query().skip 1

						newColl.fetch().done ->
							expect(newColl.at(0)).toEqual(m)

							done()

				else
					done()

			it "should query according to where criteria", (done)->
				if !first
					newColl = new TestCollection
						where: value: 1

					newColl.fetch().done ->
						for model in newColl.models
							expect(model.get("value")).toEqual(1)

						newColl.query().where
							name: startsWith: "o"

						newColl.fetch().done ->
							for model in newColl.models
								expect(model.get("name")[0]).toEqual("o")

						done()
				else
					done()

			it "should fire the created event", (done)->
				name = "Ian"

				newColl = new TestCollection()
				newColl.fetch().done ->

					if !first
						m = newColl.push name: name
						m.save().done ->
							expect(true).toBe(true)
							done()
					else
						newColl.once "created", (data, socketEvent)->
							expect(data.name).toEqual(name)
							expect(socketEvent).toBeTruthy()
							done()

			it "should fire the socketSync event", (done) ->

				if !first

					newColl = new TestCollection
						query: limit: 1000

					$.when([newColl.fetch(), wait(200)]).done ->

						value = "A unique string"
						newColl.on "socketSync", (coll, resp, options) ->
							if (coll == newColl)

								expect(options).toBeTruthy()

								newColl.off "socketSync"

								done()

						m = newColl.push name: value
						m.save().done ->
							newColl.fetch()
				else
					done()


			it "should fire the socketRequest event", (done) ->

				newColl = new TestCollection()

				newColl.on "socketRequest", (coll, promise, options) ->

					if coll instanceof Sails.Collection

						expect(coll).toEqual(newColl)
						expect(_.isFunction promise.done).toBeTruthy()
						expect(options).toBeTruthy()

						newColl.off "socketRequest"

						done()

				newColl.fetch() # triggers socketRequest

			it "should fire the socketError event", (done) ->

				newColl = new TestCollection()

				newColl.on "socketError", (coll, resp, options) ->

					if coll instanceof Sails.Collection

						expect(coll).toEqual(newColl)
						expect(resp.statusCode).toEqual(404) # not found
						expect(options).toBeTruthy()

						newColl.off "socketError"

						done()

				newColl.fetch({ url: "/fake" }) # should get a server error

			it "should fire the subscribed event", (done) ->
				newColl = new TestCollection()

				newColl.on "subscribed", (coll, modelName) ->
					if coll instanceof Sails.Collection

						expect(coll).toEqual(newColl)
						expect(modelName).toEqual("testmodel")

						newColl.off "subscribed"

						done()

				newColl.fetch()

		describe "synced model", ->

			it "should construct with a pojo of attributes", ->
				if !first
					m = new TestModel
						name: "Ian"

					expect(m.get("name")).toEqual("Ian")

			it "should be able to parse out the populate option from the constructor", ->
				if !first
					m = new TestModel
						name: "Ian"
					,
						populate: "test"

					expect(m._sails.query.populate).toBeTruthy()

			it "should populate if populated is true, and not populate undefined/false", (done)->
				if !first
					newColl = new TestCollection()

					m = newColl.push name: "super"

					m.save().done ->

						id = m.id

						m.addTo "tests",
							name: "sub"
							urlRoot: "/testmodel"
						.done (resp)->

							added = resp # should be an array

							expect(added.name).toEqual("sub")

							m = new TestModel
								id: id
							,
								populate: "tests"

							m.fetch().done ->

								expect(m.get("tests")).toBeTruthy()

								expect(m.get("tests").length).toEqual(1)

								m = new TestModel
									id: id

								m.fetch().done ->

									expect(m.get("tests")).not.toBeTruthy()

									done()

				else
					done()

			it "constructor should parse out socket configuration options", (done)->

				if !first

					delay = deferDelay * 2

					m = new TestModel
						name: "an object"
					,
						socketSync: true

					spies =
						f: ->
						g: ->

					spyOn spies, 'f'
					spyOn spies, 'g'

					disconnect()

					m.on "socketSync", spies.f

					m.save()

					wait(delay).done ->

						expect(spies.f).not.toHaveBeenCalled()

						connect()

						wait(delay).done ->

							expect(spies.f).toHaveBeenCalled()

							m = new TestModel
								name: "another object"
							,
								subscribe: true
								socketSync: false

							disconnect()

							m.on "socketSync", spies.f
							m.on "sync", spies.g

							m.save().done ->

								expect(spies.f.calls.count()).toEqual(1)
								expect(spies.g).toHaveBeenCalled()

								connect()

								wait(delay).done ->

									expect(spies.f.calls.count()).toEqual(2)
									expect(spies.g.calls.count()).toEqual(2)

									done()

				else
					done()

			it "should be able to save", (done)->
				if !first
					m = new TestModel name: "save me"

					m.save().done ->

						expect(m.id).toBeTruthy()

						done()
				else
					done()

			it "should be able to save over ajax", (done) ->
				if !first

					m = new TestModel
						name: "save me"
					,
						socketSync: false
						subscribe: false

					disconnect()

					spies =
						f: ->

					spyOn spies, 'f'

					m.on "socketSync", spies.f

					m.save().done ->

						expect(m.id).toBeTruthy()

						connect()

						wait(2 * deferDelay).done ->

							expect(spies.f).not.toHaveBeenCalled()

							done()

				else
					done()

			it "should delegate to ajax, subscribing over sockets", (done) ->

				if !first

					m = new TestModel
						name: "onetwothree"
					,
						socketSync: false

					spies =
						f: ->

					spyOn spies, 'f'

					m.on "subscribed", spies.f

					disconnect()

					m.save {},
						subscribe: true
					.done ->

						expect(spies.f).not.toHaveBeenCalled()

						connect()

						wait(deferDelay * 2).done ->

							expect(spies.f).toHaveBeenCalled()

							m.on "updated:value", (model, val) ->

								expect(val).toEqual(8)

								done()

				else
					newColl = new TestCollection()

					newColl.fetch
						socketSync: true
					.done ->

						newColl.on "created", (data)->

							if data.name == "onetwothree"

								expect(data.name).toEqual("onetwothree")

								wait(4 * deferDelay).done ->
									m = new TestModel(data)
									m.set "value", 8
									m.save {},
										socketSync: true
									.done ->
										done()

			it "should be able to fetch, given an id", (done)->
				if !first

					newColl = new TestCollection()

					newColl.fetch().done ->

						m = newColl.at(0)

						id = m.id

						m = new TestModel id: id

						m.fetch().done ->

							expect(m.id).toBeTruthy()

							done()
				else
					done()

			it "should parse socketSync and subscribe from fetch options", (done) ->

				if !first

					newColl = new TestCollection()

					newColl.fetch().done ->

						m = newColl.at(0)

						m = new TestModel id: m.id

						spies =
							f: ->

						spyOn spies, 'f'

						m.on "socketSync", spies.f

						disconnect()

						m.fetch
							socketSync: false
							subscribe: false
						.done ->
							expect(spies.f).not.toHaveBeenCalled()

							connect()

							wait(deferDelay * 2).done ->
								expect(spies.f).not.toHaveBeenCalled()

								done()
				else
					done()

			it "should be able to destroy", (done)->
				if !first
					newColl = new TestCollection()

					newColl.fetch( socketSync: true ).done ->

						m = newColl.at(0)

						# create a new collection
						# destroy won't be called on first collection created
						# since the model instance will be removed by backbone
						newColl = new TestCollection()

						newColl.fetch().done ->

							spies =
								f: ->

							spyOn spies, 'f'

							newColl.on "destroyed", spies.f

							m.destroy().done ->

								wait(deferDelay).done ->
									expect(spies.f).toHaveBeenCalled()
									done()

				else
					done()

			it "should be able to destroy over ajax, regardless of socketSync", (done)->
				if !first
					newColl = new TestCollection()

					newColl.fetch( socketSync: true ).done ->

						m = newColl.at(0)

						# create a new collection
						# destroy won't be called on first collection created
						# since the model instance will be removed by backbone
						newColl = new TestCollection()

						newColl.fetch().done ->

							spies =
								f: ->

							spyOn spies, 'f'

							newColl.on "destroyed", spies.f

							disconnect()
							m.destroy( socketSync: true ).done ->

								wait(deferDelay).done ->
									expect(spies.f).toHaveBeenCalled()

									connect()
									done()
				else
					done()

			it "should be able to query populate clauses", (done) ->
				if !first

					newColl = new TestCollection()

					newColl.query().populate("tests")

					newColl.fetch().done ->
						for models in newColl.models
							expect(models.get("tests")).toBeTruthy()

						done()

				else
					done()

			it "should be able to add to", (done) ->

				if !first

					m = new TestModel name: "im new"

					m.save().done ->

						m.addTo "tests",
							name: "im also new"
						,
							update: true
						.done ->

							expect(m.get("tests")).toBeTruthy()
							expect(m.get("tests").length).toEqual(1)
							expect(m.get("tests")[0].name).toEqual("im also new")

							another = new TestModel name: "wahay!"

							# no update this time
							m.addTo("tests", another).done ->
								expect(m.get("tests").length).toEqual(1)

								m = new TestModel id: m.id

								m.fetch populate: "tests"
								.done ->
									expect(m.get("tests").length).toEqual(2)

									done()

				else
					done()

			it "should be able to remove from", (done) ->

				if !first

					m = new TestModel name: "im new"

					m.save().done ->

						assoc = new AssociatedTestCollection m, 'tests'

						m1 = assoc.push name: "im first"
						m2 = assoc.push name: "im second"

						$.when(m1.save(), m2.save()).done ->

							id1 = m1.id
							id2 = m2.id

							m.fetch populate: "tests"
							.done ->

								expect(m.get("tests").length).toEqual(2)

								m.removeFrom 'tests', m1, update: true
								.done ->

									expect(m.get("tests").length).toEqual(1)

									m.removeFrom 'tests',
										id: id2
									.done ->

										expect(m.get("tests").length).toEqual(1)

										m.fetch populate: 'tests'
										.done ->

											expect(m.get('tests').length).toEqual(0)

											done()

				else
					done()

			it "should subscribe when requested", (done)->

				if !first

					newColl = new TestCollection()

					newColl.fetch().done ->

						m = newColl.at(0)

						id = m.id

						another = new TestModel id: id

						spies =
							f: ->

						spyOn spies, 'f'

						another.on "updated", spies.f

						m.set "name", "something else"

						m.save().done ->

							expect(spies.f).not.toHaveBeenCalled()

							another.subscribe().done ->

								m.save().done ->

									# will fire updated server side regardless
									# which will be forwarded after dirty checking
									expect(spies.f).toHaveBeenCalled()

									done()

				else
					done()

			it "should fire the addedTo event", (done) ->

				name = "a unique identity"

				if !first
					model = new TestModel name: name
					model.save().done ->

						spies =
							f: ->
							g: ->

						spyOn spies, 'f'
						spyOn spies, 'g'

						model.once "addedTo", spies.f
						model.once "addedTo:tests", spies.g

						wait(deferDelay).done ->
							expect(spies.f).toHaveBeenCalled()
							expect(spies.g).toHaveBeenCalled()

							done()

				else
					newColl = new TestCollection()
					newColl.fetch().done ->

						newColl.on "created", (data) ->
							if data.name == name
								model = new TestModel data

								model.addTo 'tests', name: "monica"
								.done ->
									done()

			it "should fire the updated event", (done) ->
				lastspec = true

				newColl = new TestCollection()
				newColl.fetch().done ->

					name = "Fred"
					if !first
						m = newColl.push name: name
						m.save().done ->
							newColl.once "updated:value", (model, val, e)->
								expect(val).toEqual(5)
								expect(e).toBeTruthy()
								expect(model).toEqual(m)

								done()
					else
						newColl.once "created", (data, e)->
							expect(data.name).toEqual(name)
							expect(e).toBeTruthy()
							m = new TestModel data
							m.set "value", 5
							m.save().done ->
								done()

