ExamplesApp.module "ChatClientApp.Message.List", (List) ->
  List.MessageView = Backbone.Marionette.ItemView.extend
    template: "chatclient/messages/message"

  List.View = Backbone.Marionette.CollectionView.extend
    childView: List.MessageView
    tagName: "ul"
    className: "contactsapp messages"

    scrollToBottom: ->
      window.scrollTo 0, document.body.scrollHeight

    onNewMessage: ->
      @scrollToBottom()

    onShow: ->
      @scrollToBottom()

