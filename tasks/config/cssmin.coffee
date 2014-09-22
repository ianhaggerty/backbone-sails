###
Compress CSS files
###
module.exports = (grunt) ->
	grunt.config.set "cssmin",
		dist:
			src: [".tmp/public/concat/production.css"]
			dest: ".tmp/public/min/production.min.css"

	grunt.loadNpmTasks "grunt-contrib-cssmin"