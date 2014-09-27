cssFilesToInject = [
	"styles/**/*.css"
]

jsFilesToInject = [
	## Backbone.Sails dependencies ##
	"js/dependencies/sails.io.js"
	"js/dependencies/jquery.js"
	"js/dependencies/lodash.js"
	"js/dependencies/json2.js"
	"js/dependencies/backbone.js"

	## Backbone.Sails ##
	"js/backbone.js"

	## Examples dependencies ##
	"js/examples/dependencies/*.js"
	## Examples dependencies configuration ##
	"js/examples/dependencies/config/**/*.js"
	## Examples App ##
	"js/examples/ExamplesApp.js"
	## Examples Submodules ##
	"js/examples/**/*.js"


	## Anything else ##
	"js/**/*.js"
]

templateFilesToInject = [
	'templates/**/*.html'
	'templates/**/*.ejs'
]

jsTestFilesToInject = [
	"tests/jasmine/jasmine.js"
	"tests/jasmine/jasmine-html.js"
	"tests/jasmine/console.js"
	"tests/jasmine/boot.js"

	"tests/**/*.js"
]

cssTestStylesToInject = [
	"tests/jasmine/**/*.css"
]

module.exports.cssFilesToInject = cssFilesToInject.map (path) ->
	".tmp/public/" + path

module.exports.jsFilesToInject = jsFilesToInject.map (path) ->
	".tmp/public/" + path

module.exports.templateFilesToInject = templateFilesToInject.map (path) ->
	"assets/" + path

module.exports.jsTestFilesToInject = jsTestFilesToInject.map (path) ->
	".tmp/public/" + path

module.exports.cssTestStylesToInject = cssTestStylesToInject.map (path) ->
	".tmp/public/" + path
