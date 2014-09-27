ExamplesApp.module "ChatClientApp.Message", (Message) ->
	Message.LayoutView = Backbone.Marionette.LayoutView.extend
		template: "chatclient/messages/layout"
		regions:
			messagesRegion: "#messages-region"
			createMessageRegion: "#create-message-region"

