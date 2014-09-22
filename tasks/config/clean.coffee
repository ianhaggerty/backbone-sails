###
Clean files and folders
###
module.exports = (grunt) ->
	grunt.config.set "clean",
		dev: [".tmp/public/**"]
		build: ["www"]

	grunt.loadNpmTasks "grunt-contrib-clean"
	return