###
Compile CoffeeScript files to JavaScript.
###
module.exports = (grunt) ->
  grunt.config.set "coffee",
    dev:
      options:
        bare: true

      files:
        expand: true
        cwd: "assets/"
        src: ["**/*.coffee"]
        dest: ".tmp/public/"
        ext: ".js"

    api:
      expand: true,
      flatten: true,
      cwd: 'api/blueprints',
      src: ['*.coffee'],
      dest: 'releases/release/api/blueprints',
      ext: '.js'

    asset:
      files:
        'releases/release/assets/js/backbone.sails.js': 'assets/js/backbone.sails.coffee'


  grunt.loadNpmTasks "grunt-contrib-coffee"