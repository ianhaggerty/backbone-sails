###
  Testing a library like this with jasmine is extremely difficult. For that reason, extensive
  logging capabilities have been implemented to monitor the exact state of the application under
  different scenarios.

  To see what the library is capable of, set the log level to 6, open up two browser windows
  and start cruding away(see below). Make sure you have 2 test models to play with.
###

Sails = Backbone.Sails
Model = Sails.Model
Collection = Sails.Collection

Sails.configure
	attempts: 5
	interval: 500

# Generic Test Model
class TestModel extends Model
	urlRoot: "/testmodel"

# Generic Test Collection
class TestCollection extends Collection
	url: "/testmodel"

modelOne = undefined
modelTwo = undefined
coll = new TestCollection()
coll.on "all", -> console.log "collection says...", arguments
coll.sort "createdAt  DESC"
coll.fetch()
.done ->
	modelOne = coll.models[0]
	modelTwo = coll.models[1]
	modelOne?.on "all", -> console.log "modelOne says..", arguments
	modelTwo?.on "all", -> console.log "modelTwo says..", arguments

Sails.on "all", -> console.log "Sails says...", arguments
