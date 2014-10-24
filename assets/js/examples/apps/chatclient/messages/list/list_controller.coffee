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
          # data will not have user populated at the moment
          # we'll have to send another request, and then
          # add to the messages collection
          message = new ExamplesApp.ChatClientApp.Entities.Message data
          message.query "populate", "user"
          message.fetch().done ->
            messages.add message

            messagesView.triggerMethod "new:message", message

