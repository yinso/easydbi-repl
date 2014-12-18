loglet = require 'loglet'

hasModuleVersion = (module, version, cb) ->
  @query 'select * from __version_t where module = $module and version = $version', {module: module, version: version}, cb

logModuleVersion = (module, version, query, cb) ->
  @query 'insert into __version_t (module, version, query) values ($module, $version, $query)', {module: module, version: version, query: query}, cb

module.exports = 
  hasModuleVersion: hasModuleVersion
  logModuleVersion: logModuleVersion
