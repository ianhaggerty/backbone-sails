###
Compresses files into a zip
###
  
module.exports = (grunt) ->
  grunt.config.set "compress",
    release:
      options:
        archive: 'releases/release/archive.zip'
      files: [
        expand: true
        cwd: 'releases/release/'
        src: '**/*.js'
      ]

  grunt.loadNpmTasks "grunt-contrib-compress"