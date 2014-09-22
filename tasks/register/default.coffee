module.exports = (grunt) ->
	grunt.registerTask "boot", [
		"compileAssets"
		"linkAssets"
		"concurrent:watchAll"
	]
	grunt.registerTask "default", [] # make sails happy