ExamplesApp.module "ChatClientApp.Entities", (Entities) ->

  Entities.User = Backbone.Sails.Model.extend
    modelName: "chatclientuser"

  Entities.UserCollection = Backbone.Sails.Collection.extend
    model: Entities.User