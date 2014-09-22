module.exports = (grunt) ->
	grunt.registerTask "syncAssets", [
		"jst:dev"
		"sync:dev"
		"coffee:dev"
	]