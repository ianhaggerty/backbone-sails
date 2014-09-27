ExamplesApp.module "ChatClientApp.Message.Create", (Create) ->
	Create.Controller =
		showPrompt: ->
			user = ExamplesApp.ChatClientApp.reqres.request "current:user"

			createMessageView = new Create.View user

			createMessageView.on "create:message", (data)->
				message = new ExamplesApp.ChatClientApp.Entities.Message data

				###
        We'll save the message to the server here. Instead of emitting a 'message created'
        clientside, we'll let the messages collection pick up the 'created' event and
        then hand off to the collection view.
        ###
				message.save()

			ExamplesApp.mainRegion.currentView.createMessageRegion.show createMessageView