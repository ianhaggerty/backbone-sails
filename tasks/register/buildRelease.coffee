module.exports = (grunt) ->
  grunt.registerTask "buildRelease", [
    "coffee:api"
    "coffee:asset"
    "compress:release"
  ]