ExamplesApp.module "ChatClientApp.Entities", (Entities) ->

  Entities.Message = Backbone.Sails.Model.extend
    modelName: "chatclientmessage"

  Entities.MessageCollection = Backbone.Sails.Collection.extend
    modelName: "chatclientmessage"
    comparator: (message) ->
      (new Date(message.get("createdAt"))).getTime()
