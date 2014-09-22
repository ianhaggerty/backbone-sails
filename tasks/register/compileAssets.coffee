module.exports = (grunt) ->
	grunt.registerTask "compileAssets", [
		"clean:dev"
		"jst:dev"
		"compass:dev"
		"copy:dev"
		"coffee:dev"
	]