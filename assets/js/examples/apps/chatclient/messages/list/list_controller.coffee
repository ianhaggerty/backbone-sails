ExamplesApp.module "ChatClientApp.Message.List", (List) ->
  List.Controller =
    listMessages: ->
      messages = new ExamplesApp.ChatClientApp.Entities.MessageCollection

      messages.query
        limit: 10
        sort: "createdAt DESC"
        populate: "user"

      # force a sync over the socket
      messages.fetch
        socketSync: true
      .done ->
        messagesView = new List.View
          collection: messages

        ExamplesApp.mainRegion.currentView.messagesRegion.show messagesView

        # listen for new messages (we are now subscribed)
        messages.on "created", (data)->
          message = new ExamplesApp.ChatClientApp.Entities.Message data
          message.query "populate", "user"
          message.fetch().done ->
            messages.add message
            messagesView.triggerMethod "new:message", message

        # client-side creation of messages
        List.on "new:message", (message)->
          messages.add message
          if _.isObject message.get("user")
            messagesView.triggerMethod "new:message", message
          else
            message.populate("user").fetch().then ->
              messagesView.triggerMethod "new:message", message

