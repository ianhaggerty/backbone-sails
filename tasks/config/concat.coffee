###
Concatenate files
###
module.exports = (grunt) ->
	grunt.config.set "concat",
		js:
			src: require("../pipeline").jsFilesToInject
			dest: ".tmp/public/concat/production.js"

		css:
			src: require("../pipeline").cssFilesToInject
			dest: ".tmp/public/concat/production.css"

	grunt.loadNpmTasks "grunt-contrib-concat"