ExamplesApp.module "ChatClientApp.Message.Create", (Create) ->
  Create.Controller =
    showPrompt: ->
      user = ExamplesApp.ChatClientApp.reqres.request "current:user"

      createMessageView = new Create.View user

      createMessageView.on "create:message", (data)->
        message = new ExamplesApp.ChatClientApp.Entities.Message data

        ###
        We'll save the message to the server here. This will trigger 'created' events on
        subscribed collection instances.
        ###
        message.populate("user").save().then ->
          Create.trigger "new:message", message

      ExamplesApp.mainRegion.currentView.createMessageRegion.show createMessageView