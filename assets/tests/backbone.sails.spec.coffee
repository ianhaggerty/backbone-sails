
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

modelOne = undefined
modelTwo = undefined
modelOneTests = undefined
modelOneModel = undefined
tests = undefined

coll = new TestCollection()
coll.on "all", -> console.log "collection says...", arguments
coll.query()
	.sort "createdAt DESC"
	.limit 10
coll.fetch()
.done ->
	modelOne = coll.models[0]
	modelTwo = coll.models[1]
	modelOne?.on "all", -> console.log "modelOne says..", arguments
	modelTwo?.on "all", -> console.log "modelTwo says..", arguments


Backbone.Sails.on "all", -> console.log "Sails says...", arguments
