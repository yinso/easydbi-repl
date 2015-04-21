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
    when 'showSetups'
      try 
        cb null, setup.showSetups()
      catch e 
        cb e
    when 'use'
      runtime.connect cmd.args[0], cb
    when 'load'
      runtime.loadScript cmd.args[0], cb
    when 'deploy'
      runtime.deploy cmd.args[0], cmd.args[1], cb
    when 'quit'
      replExit()
    when 'require'
      runtime.requireModule cmd.args[0], cb
    else
      runtime.runFunc cmd.command, cmd.args, cb

innerEval = (stmt, cb) ->
  if stmt == ''
    cb null
  else if stmt.match /^\:/
    try 
      parsed = cmdParser.parse stmt.substring(1)
      runCommand parsed, (err, res) ->
        history.log stmt
        if err
          loglet.error err
          cb null, undefined
        else 
          cb null, res
    catch e 
      loglet.error e
      cb null, undefined
  else
    runtime.eval stmt, (err, res) ->
      history.log stmt
      if err
        loglet.error err
        cb null, undefined
      else
        cb null, res

myEval = (cmd, context, filename, cb) ->
  stmt = cmdString(cmd)
  innerEval stmt, cb

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

startRepl = (argv) ->
  funclet
    .start (next) ->
      if argv.use
        innerEval ":use('#{argv.use}')", (err) ->
          if err
            next err
          else
            next null
      else
        next null
    .then (next) ->
      if argv.require
        innerEval ":require('#{argv.require}')", (err) ->
          if err
            next err
          else
            next null
      else
        next null
    .catch (err) ->
      loglet.error err
      replExit()
    .done () ->
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
      startRepl(argv)

module.exports = 
  run: run
