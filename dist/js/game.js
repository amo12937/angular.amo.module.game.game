(function() {
  "use strict";
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  (function(moduleName) {
    return angular.module(moduleName, ["ng", "amo.module.state_machine"]).factory("" + moduleName + ".GameFsm", [
      "amo.module.state_machine.StateSetter", function(StateSetter) {
        return function(action) {
          var DONE, DefaultState, INIT, PLAYING, STOPPED, s;
          s = StateSetter();
          DefaultState = (function() {
            function DefaultState() {}

            DefaultState.prototype.Entry = s.defaultAction;

            DefaultState.prototype.Exit = s.defaultAction;

            DefaultState.prototype.start = s.defaultAction;

            DefaultState.prototype.finish = s.defaultAction;

            DefaultState.prototype.stop = s.defaultAction;

            DefaultState.prototype.isInit = function() {
              return false;
            };

            DefaultState.prototype.isPlaying = function() {
              return false;
            };

            DefaultState.prototype.isDone = function() {
              return false;
            };

            DefaultState.prototype.isStopped = function() {
              return false;
            };

            return DefaultState;

          })();
          INIT = new ((function(_super) {
            __extends(_Class, _super);

            function _Class() {
              return _Class.__super__.constructor.apply(this, arguments);
            }

            _Class.prototype.start = function() {
              return s(PLAYING);
            };

            _Class.prototype.stop = function() {
              return s(STOPPED);
            };

            _Class.prototype.isInit = function() {
              return true;
            };

            return _Class;

          })(DefaultState));
          PLAYING = new ((function(_super) {
            __extends(_Class, _super);

            function _Class() {
              return _Class.__super__.constructor.apply(this, arguments);
            }

            _Class.prototype.Entry = function() {
              return action.startToPlay();
            };

            _Class.prototype.Exit = function() {
              return action.finishPlaying();
            };

            _Class.prototype.finish = function(ended) {
              if (ended) {
                return s(DONE);
              } else {
                return s(PLAYING);
              }
            };

            _Class.prototype.stop = function() {
              return s(STOPPED);
            };

            _Class.prototype.isPlaying = function() {
              return true;
            };

            return _Class;

          })(DefaultState));
          DONE = new ((function(_super) {
            __extends(_Class, _super);

            function _Class() {
              return _Class.__super__.constructor.apply(this, arguments);
            }

            _Class.prototype.Entry = function() {
              return action.entryDone();
            };

            _Class.prototype.isDone = function() {
              return true;
            };

            return _Class;

          })(DefaultState));
          STOPPED = new ((function(_super) {
            __extends(_Class, _super);

            function _Class() {
              return _Class.__super__.constructor.apply(this, arguments);
            }

            _Class.prototype.Entry = function() {
              return action.entryStopped();
            };

            _Class.prototype.isStopped = function() {
              return true;
            };

            return _Class;

          })(DefaultState));
          return s.getFsm(INIT);
        };
      }
    ]).factory("" + moduleName + ".Game", [
      "$timeout", "$q", "" + moduleName + ".GameFsm", function($timeout, $q, Fsm) {
        return function(delegate) {
          var fsm, paused, self, stream;
          stream = (function() {
            var deferred, promise, self;
            deferred = $q.defer();
            promise = deferred.promise;
            deferred.resolve();
            return self = {
              add: function(f) {
                promise = promise.then(f);
                return self;
              }
            };
          })();
          paused = null;
          fsm = Fsm({
            startToPlay: function() {
              var current;
              if (typeof delegate.notifyStartingToPlay === "function") {
                delegate.notifyStartingToPlay();
              }
              current = delegate.getNextPlayer();
              return $timeout(function() {
                return stream.add(function() {
                  return current.play();
                }).add(function(ended) {
                  if (paused) {
                    paused.promise.then(function() {
                      return fsm().finish(ended);
                    });
                  } else {
                    fsm().finish(ended);
                  }
                });
              });
            },
            finishPlaying: function() {
              return typeof delegate.notifyFinishedPlaying === "function" ? delegate.notifyFinishedPlaying() : void 0;
            },
            entryDone: function() {
              return typeof delegate.end === "function" ? delegate.end() : void 0;
            },
            entryStopped: function() {
              return typeof delegate.stop === "function" ? delegate.stop() : void 0;
            }
          });
          return self = {
            start: function() {
              return fsm().start();
            },
            pause: function() {
              if (!fsm().isPlaying() || paused) {
                return;
              }
              paused = $q.defer();
              return typeof delegate.notifyPausing === "function" ? delegate.notifyPausing() : void 0;
            },
            resume: function() {
              if (!paused) {
                return;
              }
              if (typeof delegate.notifyResuming === "function") {
                delegate.notifyResuming();
              }
              paused.resolve();
              return paused = null;
            },
            paused: function() {
              return !!paused;
            },
            stop: function() {
              return fsm().stop();
            }
          };
        };
      }
    ]);
  })("amo.module.game.game");

}).call(this);
