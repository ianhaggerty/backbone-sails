ExamplesApp.module "ChatClientApp.User.Create", (Create) ->
  Create.View = Marionette.ItemView.extend
    className: "contactsapp create user dialog"
    template: "chatclient/users/create"

    ui:
      name: "input#name"

    events:
      "keypress @ui.name": "handleKeyPress"
      "blur @ui.name": "focusInput"

    focusInput: ->
      @ui.name.focus()

    isEnter: (e)->
      return e.keyCode == 13

    handleKeyPress: (e)->
      if @isEnter e
        @trigger "create:user",
          name: @ui.name.val()

    onShow: ->
      @focusInput()
