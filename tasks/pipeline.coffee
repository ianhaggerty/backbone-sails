cssFilesToInject = [
	"styles/**/*.css"
]

jsFilesToInject = [
	"js/dependencies/sails.io.js"
	"js/dependencies/jquery.js"
	"js/dependencies/jquery.**.js"
	"js/dependencies/lodash.js"
	"js/dependencies/backbone.js"
	"js/dependencies/backbone.**.js"
	"js/dependencies/**/*.js"

	"js/config/**/*.js"

	"js/app.js"
	"js/entities/**/*.js"
	"js/apps/**/*.js"

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
