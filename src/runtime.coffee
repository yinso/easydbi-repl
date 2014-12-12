loglet = require 'loglet'
funclet = require 'funclet'
DBI = require 'easydbi'
require 'easydbi-pg'

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
