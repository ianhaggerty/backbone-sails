ExamplesApp.module "ChatClientApp.Message.Create", (Create)->
  class Create.View extends Backbone.Marionette.ItemView
    className: "contactsapp create message dialog"
    template: "chatclient/messages/create"

    constructor: (user) ->
      super
      @user = user

    serializeData: ->
      name: @user.get "name"

    ui:
      text: "input"

    events:
      "keypress @ui.text": "handleKeyPress"
      "blur @ui.text": "focusInput"

    isEnter: (e)->
      return e.keyCode == 13

    handleKeyPress: (e)->
      if @isEnter e
        @trigger "create:message",
          user: @user.attributes
          content: @ui.text.val()
        @ui.text.val("")

    focusInput: ->
      @ui.text.focus()

    onShow: ->
      @focusInput()