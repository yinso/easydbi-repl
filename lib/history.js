// Generated by CoffeeScript 1.4.0
(function() {
  var History, filelet, fs, funclet, loglet, path, _;

  filelet = require('filelet');

  fs = require('fs');

  path = require('path');

  funclet = require('funclet');

  _ = require('underscore');

  loglet = require('loglet');

  History = (function() {

    History.defaultPath = function() {
      return path.join(process.env.HOME, '.easydbi/history.json');
    };

    History.make = function(filePath) {
      if (filePath == null) {
        filePath = this.defaultPath();
      }
      return new this(filePath);
    };

    function History(filePath) {
      this.filePath = filePath;
      this.inner = [];
    }

    History.prototype.bind = function(repl) {
      repl.rli.history = [].concat(this.inner).reverse();
      return repl.rli.historyIndex = 0;
    };

    History.prototype.load = function(cb) {
      var _this = this;
      return funclet.bind(fs.readFile, this.filePath, 'utf8').then(function(data, next) {
        var args;
        try {
          args = JSON.parse(data);
          return next(null, args);
        } catch (e) {
          return next(e);
        }
      })["catch"](function(err) {
        _this.inner = [];
        return cb(null);
      }).done(function(args) {
        _this.inner = args;
        return cb(null);
      });
    };

    History.prototype.save = function(cb) {
      var _this = this;
      return funclet.start(function(next) {
        return filelet.mkdirp(path.dirname(_this.filePath), next);
      }).then(function(next) {
        return fs.writeFile(_this.filePath, JSON.stringify(_this.inner), next);
      })["catch"](function(err) {
        loglet.error(err);
        return cb(null);
      }).done(function() {
        return cb(null);
      });
    };

    History.prototype.log = function(cmd) {
      if (_.contains(this.inner, cmd)) {
        this.inner = _.filter(this.inner, function(item) {
          return item !== cmd;
        });
      }
      return this.inner.push(cmd);
    };

    return History;

  })();

  module.exports = History;

}).call(this);
