ExamplesApp.module "ChatClientApp", (ChatClientApp) ->
  ChatClientApp.Router = Marionette.AppRouter.extend
    appRoutes:
      "examples/chatclient": "createUser"

  API =
    createUser: ->
      ChatClientApp.User.Create.Controller.create()

    showMessages: ->
      ChatClientApp.Message.Controller.loadMessagingLayout()

  ChatClientApp.on "show:messages", ->
    API.showMessages()

  ChatClientApp.on "user:created", (user) ->
    ChatClientApp.commands.execute "set:current:user", user

    API.showMessages()

  ExamplesApp.addInitializer ->
    new ChatClientApp.Router
      controller: API

  ChatClientApp.commands = new Backbone.Wreqr.Commands()
  ChatClientApp.reqres = new Backbone.Wreqr.RequestResponse()