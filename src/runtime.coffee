loglet = require 'loglet'
filelet = require 'filelet'
DBI = require 'easydbi'
require 'easydbi-pg'
path = require 'path'
fs = require 'fs'
funclet = require 'funclet'
_ = require 'underscore'
semver = require 'semver'
require 'coffee-script/register'

pathName = (filePath) ->
  path.basename filePath, path.extname(filePath)

readdir = (dirPath, cb) ->
  fs.readdir dirPath, (err, files) ->
    if err
      cb err
    else
      fileList = []
      funclet
        .each files, (file, next) -> 
          filePath = path.join(dirPath, file)
          fs.stat filePath, (err, stat) ->
            if err
              next err
            else if stat.isFile() and semver.valid(path.basename(file, path.extname(file)))
              fileList.push filePath
              next null
            else
              next null
        .catch(cb)
        .done (files) ->
          fileList.sort (v1, v2) ->
            semver.compare pathName(v1), pathName(v2)
          cb null, fileList

class Runtime 
  constructor: () ->
    @conns = {}
  connect: (key, cb) ->
    if @conns.hasOwnProperty(key)
      cb null
    else
      try 
        type = DBI.getPool(key).type
        DBI.load key, require "../module/#{type}/base"
        DBI.load key, require "../module/#{type}/version"
        DBI.connect key, (err, conn) =>
          if err 
            cb err
          else
            @conns[key] = conn
            @current = conn
            cb null
      catch e
        cb e
  eval: (cmd, args, cb) ->
    if arguments.length == 2
      cb = args
      args = {}
    if not @current
      cb {error: 'no_connection_selected', description: 'use :show setups to see the connections or :setup to setup one up.'}
    else
      @current.query cmd, args, (err, rows) ->
        if err 
          cb err
        else 
          cb null, rows
  requireModule: (modulePath, cb) ->
    try
      DBI.load @current.key, require(path.resolve(modulePath))
      cb null
    catch e
      cb e
  runFunc: (cmd, args, cb) ->
    if @current[cmd] 
      try 
        @current[cmd] args..., cb
      catch e
        cb e
    else
      cb {error: 'unknown_command', command: cmd, args: args}
  loadScript: (filePath, cb) ->
    fs.readFile filePath, 'utf8', (err, data) =>
      if err 
        cb err
      else # now we need a way to run through sequence... do we have that in funclet?
        queries = _.filter (item.trim() for item in data.split(/;/)), (q) -> q?.length > 0
        funclet 
          .eachSeries queries, (query, next) =>
            loglet.log query
            @eval query, (err, rows) =>
              if err 
                next err
              else 
                if rows
                  loglet.log rows
                next null
          .catch (err) =>
            cb err
          .done () =>
            cb null
  deploy: (moduleName, dirPath, cb) ->
    funclet
      .bind(readdir, dirPath)
      .thenEachSeries (filePath, next) =>
        @_deployScript moduleName, filePath, next
      .catch(cb)
      .done cb
  _deployScript: (moduleName, filePath, cb) ->
    # determine module & version from filePath? 
    # or just have them 
    version = path.basename filePath, path.extname(filePath)
    funclet
      .start (next) =>
        @current.showColumns '__version_t', (err, columns) =>
          if err
            next err
          else if columns.length == 0 # table doesn't exist. need to create it.
            query = "create table __version_t ( id serial primary key , module varchar(32) not null, version varchar(64) not null, query text not null )"
            @eval query, (err) =>
              if err
                next err
              else
                next null
          else
            next null
      .then (next) =>
        @current.hasModuleVersion moduleName, version, (err, rows) =>
          if err 
            next err
          else if rows.length > 0 # exists - we do not do anything.
            loglet.log "#{moduleName}@#{version} already deployed. Skip."
            next null
          else # we can install.
            loglet.log "install #{moduleName}@#{version}..."
            @_deployScriptHelper moduleName, version, filePath, next
      .catch(cb)
      .done () =>
        cb null
  _deployScriptHelper: (module, version, filePath, cb) ->
    fs.readFile filePath, 'utf8', (err, data) =>
      if err 
        cb err
      else # now we need a way to run through sequence... do we have that in funclet?
        queries = _.filter (item.trim() for item in data.split(/;/)), (q) -> q?.length > 0
        funclet 
          .eachSeries queries, (query, next) =>
            loglet.log query
            @_deployEval module, version, query, (err, rows) =>
              if err 
                next err
              else 
                if rows
                  loglet.log rows
                next null
          .catch (err) =>
            cb err
          .done () =>
            cb null
  _deployEval: (module, version, query, cb) ->
    funclet
      .start (next) =>
        @eval query, (err) ->
          if err 
            next err
          else
            next null
      .catch(cb)
      .done () =>
        @current.logModuleVersion module, version, query, cb
  exit: (cb) ->
    # we will need to exit all of the connections... 
    conns = []
    for key, val of @conns
      conns.push val
    funclet
      .each conns, (conn, next) ->
        conn.disconnect next
      .catch (err) ->
        cb err
      .done () ->
        loglet.log 'all connect disconnected.'
        cb null

module.exports = Runtime
