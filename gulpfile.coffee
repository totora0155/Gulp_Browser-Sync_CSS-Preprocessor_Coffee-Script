'use strict'
$$ = require 'gulp'
$ = require('gulp-load-plugins')()
runSequence = require 'run-sequence'
del = require 'del'
browserSync = require 'browser-sync'
reload = browserSync.reload

paths =
  html: 'app/**/*.html'
  sass: 'app/style/**/*.scss'
  less: 'app/style/**/*.less'
  stylus: 'app/style/**/*.styl'
  coffee: 'app/script/**/*.coffee'
  dist: 'app/**/*.{html,css,js,map}'

use =
  sass: 'rubySass'
  less: 'less'
  stylus: 'stylus'
  coffee: 'coffee'

getTypeName = (path) ->
  return 'style' if path.indexOf('style') > -1
  return 'script' if path.indexOf('script') > -1
  console.error new Error 'Invalid type'

makeCompileStream = (lang, path, opts)->
  typeName = getTypeName path
  compiler = $[use[lang]]

  $$.src path
    .pipe $.plumber()
    .pipe $.cached lang

    .pipe $.sourcemaps.init()
    .pipe $.if '*.coffee', $.coffeelint()
    .pipe $.if '*.coffee', $.coffeelint.reporter()
    .pipe compiler opts
    .pipe $.sourcemaps.write()

    .pipe $$.dest "app/#{typeName}"
    .pipe $.if '*.css', reload {stream: true}, reload()
    .pipe $.size showFile: true, title: typeName

$$.task 'del', del.bind null, ['dist/**/*']

$$.task 'copy', ->
  $$.src paths.dist
    .pipe $.if '*.html', $.minifyHtml()
    .pipe $.if '*.css', $.pleeease()
    .pipe $.if '*.js', $.uglify()
    .pipe $$.dest 'dist'

$$.task 'sass', ->
  opts =
    style: 'expanded'
    precision: 10

  makeCompileStream 'sass', paths.sass, opts

$$.task 'less', ->
  opts = {}
  makeCompileStream 'less', paths.less, opts

$$.task 'stylus', ->
  opts = {}
  makeCompileStream 'stylus', paths.stylus, opts

$$.task 'coffee', ->
  opts = {}
  makeCompileStream 'coffee', paths.coffee, opts

$$.task 'default', ->
  browserSync
    server: ['app']
    port: 8000
    notify: false
    open: false

  $$.watch paths.html, reload
  $$.watch paths.sass, ['sass']
  $$.watch paths.less, ['less']
  $$.watch paths.stylus, ['stylus']
  $$.watch paths.coffee, ['coffee']

$$.task 'dist', (cb) -> runSequence('del','copy',cb)
