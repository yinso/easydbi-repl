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

historyPath = () ->
  path.join process.env.HOME, '.easydbi/history.json'
setupPath = () ->
  path.join process.env.HOME, '.easydbi/setup.json'
  
history = History.make historyPath()
setup = Setup.make setupPath()
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
        else
          cb {erro: 'unknown_show_argument', command: cmd.command, args: cmd.args}
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

startRepl = () ->
  inst = repl.start 
    prompt: 'dbi> '
    input: process.stdin
    output: process.stdout
    eval: myEval
  inst.on 'exit', () ->
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
  inst.defineCommand 'test',
    help: 'a test command'
    action: (cb) ->
      @displayPrompt()
  inst.defineCommand 'list',
    help: 'list connections'
    action: (cb) ->
      for key, val of runtime.conns
        loglet.log key, val.options
      @displayPrompt()
  inst.defineCommand 'setup',
    help: 'setup type, options'
    action: (cmd) ->
      try 
        str = '[' + cmd + ']'
        args = coffee.eval str
        runtime.setup args[0], args[1]
        @displayPrompt()
      catch e 
        loglet.error e
        @displayPrompt()
  inst.defineCommand 'connect',
    help: '.connect key'
    action: (cmd) ->
      try 
        args = coffee.eval "[#{cmd}]"
        runtime.connect args[0], (err, conn) =>
          if err 
            loglet.error e
            @displayPrompt()
          else
            @displayPrompt()
      catch e
        loglet.error e
        @displayPrompt()
  inst.defineCommand 'tables',
    help: 'show all tables'
    action: () ->
      query = "select table_name from information_schema.tables where table_schema='public' and table_type='BASE TABLE';"
      runtime.eval query, (err, rows) =>
        if err 
          loglet.error e
          @displayPrompt()
        else
          loglet.log rows
          @displayPrompt()
  inst.defineCommand 'columns',
    help: 'show all tables'
    action: (table) ->
      query = "select column_name, data_type, is_nullable from informatioN_schema.columns where table_schema='public' and table_name='#{table}'" 
      runtime.eval query, (err, rows) =>
        if err 
          loglet.error e
          @displayPrompt()
        else
          loglet.log rows
          @displayPrompt()
  history.bind inst
  #inst.displayPrompt()

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
