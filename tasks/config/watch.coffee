###*
Run predefined tasks whenever watched file patterns are added, changed or deleted.
###
module.exports = (grunt) ->
	grunt.config.set "watch",
		api:

		# API files to watch:
			files: ["api/**/*"]

		assets:

		# Assets to watch:
			files: [
				"assets/**/*"
				"tasks/pipeline.js"
			]

		# When assets are changed:
			tasks: [
				"syncAssets"
				"linkAssets"
			]

	grunt.loadNpmTasks "grunt-contrib-watch"