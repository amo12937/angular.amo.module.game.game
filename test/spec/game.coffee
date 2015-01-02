"use strict"

do (moduleName = "amo.module.game.game") ->
  describe "#{moduleName} の仕様", ->
    beforeEach module moduleName

    describe "#{moduleName}.Game の仕様", ->
      game = null
      delegate = null
      player = null
      beforeEach ->
        delegate = jasmine.createSpyObj "delegate", [
          "notifyStartingToPlay"
          "getNextPlayer"
          "notifyFinishedPlaying"
          "notifyPausing"
          "notifyResuming"
          "end"
          "stop"
        ]
        player = jasmine.createSpyObj "player", [
          "play"
          "canPause"
          "pause"
          "resume"
        ]
        delegate.getNextPlayer.and.returnValue player
        inject ["#{moduleName}.Game", (Game) ->
          game = Game delegate
        ]

      it "start を呼ぶと delegate の notifyStartingToPlay, getNextPlayer が呼ばれる", ->
        game.start()
        expect(delegate.notifyStartingToPlay).toHaveBeenCalled()
        expect(delegate.getNextPlayer).toHaveBeenCalled()

      it "delegate.notifyStartingToPlay は任意である", ->
        delete delegate.notifyStartingToPlay
        expect(-> game.start()).not.toThrow()

      it "delegate.getNextPlayer は必須である", ->
        delete delegate.getNextPlayer
        expect(-> game.start()).toThrow()

      it "delegate.getNextPlayer() が返すプレイヤーに対して play メッセージを送る関数が $timeout に登録される", ->
        delegate.getNextPlayer.and.returnValue player

