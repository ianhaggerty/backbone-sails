ExamplesApp.module "ChatClientApp.Entities", (Entities) ->

	Entities.Message = Backbone.Sails.Model.extend
		urlRoot: "/chatclientmessage"

	Entities.MessageCollection = Backbone.Sails.Collection.extend
		url: "/chatclientmessage"
		comparator: (message) ->
			(new Date(message.get("createdAt"))).getTime()

	Entities.AssociatedMessageCollection = Backbone.Sails.associated Entities.MessageCollection
