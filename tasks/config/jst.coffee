###
Precompiles Underscore templates to a `.jst` file
###
module.exports = (grunt) ->
	grunt.config.set "jst",
		dev:
			files:
				".tmp/public/jst.js": require("../pipeline").templateFilesToInject

	grunt.loadNpmTasks "grunt-contrib-jst"