###
Minify files with UglifyJS
###
module.exports = (grunt) ->
	grunt.config.set "uglify",
		dist:
			src: [".tmp/public/concat/production.js"]
			dest: ".tmp/public/min/production.min.js"

	grunt.loadNpmTasks "grunt-contrib-uglify"