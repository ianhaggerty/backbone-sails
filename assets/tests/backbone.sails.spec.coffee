
Backbone.Sails.configure
	attempts: 5
	interval: 500
	socketSync: false
	subscribe: true
	query:
		limit: 20

TestCollection = undefined
TestsCollection = undefined

# Generic Test Model
class TestModel extends Backbone.Sails.Model

# Generic Test Collection
class TestCollection extends Backbone.Sails.Collection
	url: "/testmodel"
	model: TestModel

AssociatedTestCollection = Backbone.Sails.Associated TestCollection

modelOne = undefined
modelTwo = undefined
modelOneTests = undefined
modelTwoTests = undefined
modelOneModel = undefined
tests = undefined

coll = new TestCollection()
coll.on "all", -> console.log "collection says...", arguments
coll.query
	sort: "createdAt DESC"
	limit: 10
	populate: "tests"
coll.fetch()
.done ->
	modelOne = coll.models[0]
	modelTwo = coll.models[1]

	modelOne?.on "all", -> console.log "modelOne says..", arguments
	modelTwo?.on "all", -> console.log "modelTwo says..", arguments

	modelOneTests = new AssociatedTestCollection modelOne, 'tests'
	modelTwoTests = new AssociatedTestCollection modelTwo, 'tests'

	modelOneTests.on "all", -> console.log "modelOneTests says...", arguments
	modelTwoTests.on "all", -> console.log "modelTwoTests says...", arguments

	modelOneTests.fetch()
	modelTwoTests.fetch()


Backbone.Sails.on "all", -> console.log "Sails says...", arguments
