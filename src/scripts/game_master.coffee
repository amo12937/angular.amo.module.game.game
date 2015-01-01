"use strict"

do (moduleName = "amo.module.game.game_master") ->
  angular.module moduleName, ["ng", "amo.module.state_machine"]

  .factory "#{moduleName}.GameMasterFsm", ["amo.module.state_machine.StateSetter", (StateSetter) ->
    (action) ->
      s = StateSetter()

      class DefaultState
        Entry: s.defaultAction
        Exit: s.defaultAction
        start: s.defaultAction
        pause: s.defaultAction
        resume: s.defaultAction
        finish: s.defaultAction
        stop: -> s STOPPED

      INIT = new class extends DefaultState
        start: -> s PLAYING
      PLAYING = do ->
        pausing = false
        return new class extends DefaultState
          Entry: -> action.startToPlay()
          Exit: -> action.finishPlaying()
          pause: ->
            return if pausing
            return unless action.canPause()
            pausing = true
            action.pause()
          resume: ->
            return unless pausing
            action.resume()
            pausing = false
          finish: (ended) ->
            return if pausing
            if ended
              s DONE
            else
              s PLAYING
      DONE = new class extends DefaultState
        Entry: -> action.entryDone()
        stop: s.defaultAction
      STOPPED = new class extends DefaultState
        Entry: -> action.entryStopped()
        stop: s.defaultAction

      return s.getFsm INIT
  ]

  .factory "#{moduleName}.GameMasterAction", [
    "$timeout"
    "#{moduleName}.GameMasterFsm"
    ($timeout, Fsm) ->
      (delegate) ->
        current = null
        fsm = Fsm
          startToPlay: ->
            delegate.notifyStartingToPlay?()
            current = delegate.getNextPlayer()
            $timeout ->
              current.play (ended) ->
                fsm().finish ended
          finishPlaying: ->
            current = null
            delegate.notifyFinishedPlaying?()
          canPause: -> current.canPause?()
          pause: ->
            current.pause?()
            delegate.notifyPausing?()
          resume: ->
            delegate.notifyResuming?()
            current.resume?()
          entryDone: -> delegate.end?()
          entryStopped: -> delegate.stop?()

        self =
          start: -> fsm().start()
          pause: -> fsm().pause()
          resume: -> fsm().resume()
          stop: -> fsm().stop()

