repl = require 'repl'
loglet = require 'loglet'
funclet = require 'funclet'
repl = require 'repl'
path = require 'path'
coffee = require 'coffee-script'
cmdParser = require './command'

Runtime = require './runtime'
History = require './history'
Setup = require './setup'

history = History.make()
setup = Setup.make()
runtime = new Runtime()

cmdString = (cmd) ->
  cmd.substring(1, cmd.length - 2)

runCommand = (cmd, cb) ->
  switch cmd.command 
    when 'setup'
      try 
        setup.setup cmd.args[0], {type: cmd.args[1], options: cmd.args[2]}
        cb null
      catch e
        cb e
    when 'use'
      runtime.connect cmd.args[0], cb
    when 'show'
      switch cmd.args[0]
        when 'setups'
          try 
            cb null, setup.showSetups()
          catch e 
            cb e
        when 'tables'
          runtime.showTables cb
        when 'columns'
          tableName = cmd.args[1]
          runtime.showColumns tableName, cb
        else
          cb {erro: 'unknown_show_argument', command: cmd.command, args: cmd.args}
    when 'load'
      runtime.loadScript cmd.args[0], cb
    when 'deploy'
      runtime.deploy cmd.args[0], cmd.args[1], cb
    when 'quit'
      replExit()
    else
      cb {error: 'unknown_command', command: cmd.command, args: cmd.args}

myEval = (cmd, context, filename, cb) ->
  stmt = cmdString(cmd)
  if stmt == ''
    cb null
  else if stmt.match /^\:/
    stmt = stmt.substring 1
    try 
      parsed = cmdParser.parse stmt
      runCommand parsed, (err, res) ->
        if err
          loglet.error err
          cb null
        else 
          cb null, res
    catch e 
      loglet.error e
      cb null
  else
    runtime.eval stmt, (err, res) ->
      if err
        loglet.error err
        cb null
      else
        history.log stmt
        cb null, res

replExit = () ->
  loglet.log 'exiting...'
  funclet
    .start (next) ->
      history.save next
    .then (next) ->
      setup.save next
    .catch (err) ->
      runtime.exit (err) ->
        process.exit()
    .done () ->
      runtime.exit (err) ->
        process.exit()

startRepl = () ->
  inst = repl.start 
    prompt: 'dbi> '
    input: process.stdin
    output: process.stdout
    eval: myEval
  inst.on 'exit', replExit
  history.bind inst

run = (argv) ->
  funclet
    .start (next) ->
      setup.load next
    .then (next) ->
      history.load next
    .catch (err) ->
      loglet.croak err
    .done () ->
      startRepl()

module.exports = 
  run: run
