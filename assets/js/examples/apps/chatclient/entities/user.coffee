ExamplesApp.module "ChatClientApp.Entities", (Entities) ->

	Entities.User = Backbone.Sails.Model.extend
		urlRoot: "/chatclientuser"

	Entities.UserCollection = Backbone.Sails.Collection.extend
		url: "/chatclientuser"

