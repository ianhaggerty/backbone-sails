ExamplesApp.module "ChatClientApp.User.Create", (Create) ->
  Create.Controller =
    create: ->

      createView = new Create.View

      createView.on "create:user", (data) ->
        user = new ExamplesApp.ChatClientApp.Entities.User data
        user.save().done ->
          ExamplesApp.ChatClientApp.trigger "user:created", user

      ExamplesApp.mainRegion.show createView