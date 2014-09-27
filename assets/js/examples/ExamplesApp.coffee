ExamplesApp = new Marionette.Application()

ExamplesApp.addRegions
	mainRegion: "#main-region"

ExamplesApp.on "start", ->
	if Backbone.history
		Backbone.history.start
			pushState: true

