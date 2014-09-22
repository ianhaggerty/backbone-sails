###
A grunt task to keep directories in sync. It is very similar to grunt-contrib-copy
but tries to copy only those files that has actually changed.
###
module.exports = (grunt) ->
	grunt.config.set "sync",
		dev:
			files: [
				cwd: "./assets"
				src: ["**/*.!(coffee)"]
				dest: ".tmp/public"
			]

	grunt.loadNpmTasks "grunt-sync"