ExamplesApp.module "ChatClientApp.Message", (Message) ->
  Message.Controller =
    loadMessagingLayout: ->
      messageLayout = new Message.LayoutView()
      listMessagesView = new Message.List.View()

      ExamplesApp.mainRegion.show messageLayout

      Message.Create.Controller.showPrompt()
      Message.List.Controller.listMessages()

  Message.Create.on "new:message", (message) ->
    Message.List.trigger "new:message", message