module.exports = (grunt) ->

	grunt.config.set "concurrent",
		watchAll: [
			"watch"
			"compass:watch"
		]

	grunt.loadNpmTasks "grunt-concurrent"