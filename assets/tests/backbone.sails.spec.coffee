
Backbone.Sails.configure
	attempts: 5
	interval: 500
	socketSync: false
	subscribe: true

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
coll.sort "createdAt  DESC"
coll.fetch()
.done ->
	modelOne = coll.models[0]
	modelTwo = coll.models[1]
	modelOne?.on "all", -> console.log "modelOne says..", arguments
	modelTwo?.on "all", -> console.log "modelTwo says..", arguments

	modelOneTests = modelOne.get("tests")
	modelOneTests.on "all", -> console.log "associated collection says...", arguments

	modelOneModel = modelOneTests.push
		name: "A new one!"

	modelOneModel.save()

	modelOne.addTo "tests",
		name: "I was added to modelOne"
	.done (data)->
		modelOne.removeFrom "tests", data
		.done ->


Backbone.Sails.on "all", -> console.log "Sails says...", arguments
