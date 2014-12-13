funclet = require 'funclet'
filelet = require 'filelet'
loglet = require 'loglet'
path = require 'path'
fs = require 'fs'
DBI = require 'easydbi'
_ = require 'underscore'

class Setup
  @defaultPath: () ->
    path.join process.env.HOME, '.easydbi/setup.json'
  @make: (filePath = @defaultPath()) ->
    new @(filePath)
  constructor: (@filePath) ->
    @inner = {}
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
        cb null
      .done (data) =>
        try 
          for key, val of data
            @setup key, val
          cb null
        catch e
          cb e
  setup: (key, options) ->
    if @inner.hasOwnProperty(key)
      throw {error: 'duplicate_key', key: key}
    DBI.setup key, options
    @inner[key] = options
  replacePwd: (pass) ->
    ('*' for i in [0...pass.length]).join('')
  showSetups: () ->
    setups = {}
    for key, {type, options} of @inner
      opt = _.extend {}, options
      if opt.password
        opt.password = @replacePwd(opt.password)
      setups[key] = 
        type: type
        options: opt
    setups
  save: (cb) ->
    funclet
      .start (next) =>
        filelet.mkdirp path.dirname(@filePath), (err) ->
          next err
      .then (next) =>
        fs.writeFile @filePath, JSON.stringify(@inner), 'utf8', next
      .catch(cb)
      .done () ->
        cb null

module.exports = Setup
