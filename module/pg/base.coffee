loglet = require 'loglet'

showTables = (args, cb) ->
  query = "select table_name from information_schema.tables where table_schema='public' and table_type='BASE TABLE';"
  @query query, {}, cb

showColumns = (args, cb) ->
  query = "select column_name, data_type, is_nullable from information_schema.columns where table_schema='public' and table_name = $tableName" 
  loglet.log 'showColumns', query, args
  @query query, args, cb

module.exports = 
  showTables: showTables
  showColumns: showColumns
