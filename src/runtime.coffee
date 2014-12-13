loglet = require 'loglet'
funclet = require 'funclet'
DBI = require 'easydbi'
require 'easydbi-pg'
path = require 'path'
fs = require 'fs'
funclet = require 'funclet'
_ = require 'underscore'

class Runtime 
  constructor: () ->
    @conns = {}
  connect: (key, cb) ->
    if @conns.hasOwnProperty(key)
      cb null
    else
      DBI.connect key, (err, conn) =>
        if err 
          cb err
        else
          @conns[key] = conn
          @current = conn
          cb null
  eval: (cmd, cb) ->
    if not @current
      cb {error: 'no_connection_selected', description: 'use :show setups to see the connections or :setup to setup one up.'}
    else
      @current.query cmd, {}, (err, rows) ->
        if err 
          cb err
        else 
          cb null, rows
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
