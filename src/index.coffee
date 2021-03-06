'use strict'

taskName = 'Jade' # used with humans
safeTaskName = 'jade' # used with machines

jade = require 'gulp-jade'
minify = require 'gulp-minify-html'

{getConfig, gulp, API: {notify, merge, $, reload, handleError, typeCheck, debug}} = require 'pavios'
debug = debug 'task:' + taskName

config = getConfig safeTaskName

defaultOpts =
  minify: no
  renameTo: null
  insert: null
  compilerOpts: {}

for srcDestPair in config
  srcDestPair.opts = Object.assign {}, defaultOpts, srcDestPair.opts

# debug 'Merged config: ', config

result = typeCheck.standard config, taskName, typeCheck.generateType ['minify', 'renameTo', 'insert', 'compilerOpts']
debug 'Type check ' + (if result then 'passed' else 'failed')

gulp.task safeTaskName, (cb) ->
  unless result
    debug 'Exiting task early because config is invalid'
    return cb()

  streams = []

  for {src, dest, opts} in config
    if src.length > 0 and dest.length > 0
      debug "Creating stream for src #{src} and dest #{dest}..."
      streams.push(
        gulp.src src
        .pipe do handleError taskName
        .pipe $.changed(dest, extension: '.html')
        .pipe $.if(typeCheck.raw(typeCheck.types.insert, opts.insert), $.insert(opts.insert))
        .pipe jade opts.compilerOpts # errors from jade won't be caught for some reason
        .pipe $.if(opts.minify is yes, minify())
        .pipe $.if(typeCheck.raw(typeCheck.types.renameTo, opts.renameTo), $.rename(opts.renameTo))
        .pipe gulp.dest dest
        .pipe reload()
        .on 'end', -> notify.taskFinished taskName
      )

  merge streams

module.exports.order = 1
module.exports.sources = (src for {src} in config)
