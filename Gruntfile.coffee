"use strict"

module.exports = (grunt) ->
  require("load-grunt-tasks") grunt
  require("time-grunt") grunt

  grunt.initConfig
    pkg: grunt.file.readJSON "bower.json"
    context:
      dir:
        src: "src/scripts"
        dist: "dist/js"
    clean:
      dist: "<%= context.dir.dist %>"
    coffee:
      dist:
        files: [
          {
            expand: true
            cwd: "<%= context.dir.src %>"
            src: "**/*.coffee"
            dest: "<%= context.dir.dist %>"
            ext: ".js"
          }
        ]
    uglify:
      options:
        banner: "/*! <%= pkg.name %> <%= pkg.version %> | Copyright (c) <%= grunt.template.today('yyyy') %> Author: <%= pkg.authors %> | License: <%= pkg.license %> */"
      build:
        src: "<%= context.dir.dist %>/translator.js"
        dest: "<%= context.dir.dist %>/translator.min.js"
    karma:
      unit:
        configFile: "karma.conf.coffee"
        singleRun: true

  grunt.registerTask "build", [
    "clean:dist"
    "coffee:dist"
    "uglify"
  ]

  grunt.registerTask "test", [
    "karma:unit:start"
  ]
