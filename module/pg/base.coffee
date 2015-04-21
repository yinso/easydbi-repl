loglet = require 'loglet'

showTables = (cb) ->
  query = "select table_name from information_schema.tables where table_schema='public' and table_type='BASE TABLE';"
  @query query, {}, cb

showColumns = (tableName, cb) ->
  query = "select column_name, data_type, is_nullable from information_schema.columns where table_schema='public' and table_name = $tableName" 
  @query query, {tableName: tableName}, cb

module.exports = 
  showTables: showTables
  showColumns: showColumns
