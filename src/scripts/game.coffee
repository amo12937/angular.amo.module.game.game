"use strict"

do (moduleName = "amo.module.game.game") ->
  angular.module moduleName, ["ng", "amo.module.state_machine"]

  .factory "#{moduleName}.GameFsm", ["amo.module.state_machine.StateSetter", (StateSetter) ->
    (action) ->
      s = StateSetter()

      class DefaultState
        Entry: s.defaultAction
        Exit: s.defaultAction
        start: s.defaultAction
        finish: s.defaultAction
        stop: s.defaultAction
        isInit: -> false
        isPlaying: -> false
        isDone: -> false
        isStopped: -> false

      INIT = new class extends DefaultState
        start: -> s PLAYING
        stop: -> s STOPPED
        isInit: -> true
      PLAYING = new class extends DefaultState
        Entry: -> action.startToPlay()
        Exit: -> action.finishPlaying()
        finish: (ended) -> if ended then s DONE else s PLAYING
        stop: -> s STOPPED
        isPlaying: -> true
      DONE = new class extends DefaultState
        Entry: -> action.entryDone()
        isDone: -> true
      STOPPED = new class extends DefaultState
        Entry: -> action.entryStopped()
        isStopped: -> true

      return s.getFsm INIT
  ]

  .factory "#{moduleName}.Game", [
    "$timeout"
    "$q"
    "#{moduleName}.GameFsm"
    ($timeout, $q, Fsm) ->
      (delegate) ->
        stream = do ->
          deferred = $q.defer()
          promise = deferred.promise
          deferred.resolve()
          self =
            add: (f) ->
              promise = promise.then f
              return self
        paused = null
        fsm = Fsm
          startToPlay: ->
            delegate.notifyStartingToPlay?()
            current = delegate.getNextPlayer()
            $timeout ->
              stream
              .add -> current.play()
              .add (ended) ->
                if paused
                  paused.promise.then -> fsm().finish ended
                else
                  fsm().finish ended
                return
          finishPlaying: ->
            delegate.notifyFinishedPlaying?()
          entryDone: -> delegate.end?()
          entryStopped: -> delegate.stop?()

        self =
          start: ->
            fsm().start()
          pause: ->
            return if not fsm().isPlaying() or paused
            paused = $q.defer()
            delegate.notifyPausing?()
          resume: ->
            return unless paused
            delegate.notifyResuming?()
            paused.resolve()
            paused = null
          paused: -> !!paused
          stop: -> fsm().stop()
  ]

