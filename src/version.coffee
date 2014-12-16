###

idea is simple - 
1) we can use the REPL to modify the database, which will be logged into a script.

This will be similar to history - but it will track only the particular ones that we want to store... 

Because this is a deployment script - we will want to store it at a place that we can gain access more easily.

We will also want the ability to change the particular database that it's stored to... 

> 

####

filelet = require 'filelet'
fs = require 'fs'
path = require 'path'
funclet = require 'funclet'
_ = require 'underscore'
loglet = require 'loglet'

class Version
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
    if not _.contains @inner, cmd
      @inner.push cmd

module.exports = History
