filelet = require 'filelet'
fs = require 'fs'
path = require 'path'
funclet = require 'funclet'
_ = require 'underscore'
loglet = require 'loglet'

class History
  @defaultPath: () ->
    path.join process.env.HOME, '.easydbi/history.json'
  @make: (filePath = @defaultPath()) ->
    new @ filePath
  constructor: (@filePath) ->
    @inner = []
  bind: (repl) ->
    repl.rli.history = [].concat(@inner).reverse()
    repl.rli.historyIndex = 0;
  load: (cb) ->
    funclet
      .bind(fs.readFile, @filePath, 'utf8')
      .then (data, next) =>
        try
          args = JSON.parse data
          next null, args
        catch e
          next e
      .catch (err) =>
        @inner = []
        cb null
      .done (args) =>
        @inner = args
        cb null
  save: (cb) ->
    funclet
      .start (next) =>
        filelet.mkdirp path.dirname(@filePath), next
      .then (next) =>
        fs.writeFile @filePath, JSON.stringify(@inner), next
      .catch (err) =>
        loglet.error err
        cb null
      .done () =>
        cb null
  log: (cmd) ->
    if _.contains @inner, cmd
      @inner = _.filter @inner, (item) -> item != cmd
    @inner.push cmd

module.exports = History
