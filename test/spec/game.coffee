"use strict"

do (amo = @[".amo"], moduleName = "amo.module.game.game") ->
  describe "#{moduleName} の仕様", ->
    beforeEach module moduleName

    describe "#{moduleName}.Game の仕様", ->
      $timeout = null
      game = null
      delegate = null
      players = null
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
        players = [0..2].map (n) ->
          p = jasmine.createSpyObj "p[#{n}]", [
            "play"
            "canPause"
            "pause"
            "resume"
          ]
          _callback = null
          p.play.and.callFake (callback) ->
            _callback = callback
          p.resolve = (result) ->
            _callback? result
          return p

        delegate.getNextPlayer.and.callFake do (s = 0) -> ->
          p = players[s]
          s = (s + 1) % players.length
          return p

        module ["$provide", ($provide) ->
          decorator = amo.test.helper.jasmine.spyOnDecorator spyOn
          $provide.decorator "$timeout", decorator
          return
        ]

        inject ["$timeout", "#{moduleName}.Game", (_$timeout, Game) ->
          $timeout = _$timeout
          game = Game delegate
        ]

      it "start を呼ぶと delegate の notifyStartingToPlay, getNextPlayer が呼ばれる", ->
        game.start()
        expect(delegate.notifyStartingToPlay).toHaveBeenCalled()
        expect(delegate.getNextPlayer).toHaveBeenCalled()

      it "delegate.getNextPlayer() が返すプレイヤーに対して play メッセージを送る関数が $timeout に登録される", ->
        expect($timeout).not.toHaveBeenCalled()
        game.start()
        expect($timeout).toHaveBeenCalledWith jasmine.any Function
        expect(players[0].play).not.toHaveBeenCalled()
        $timeout.flush()
        expect(players[0].play).toHaveBeenCalledWith jasmine.any Function

      it "players[0].play が callback に true を渡すと、ゲームが終了する", ->
        game.start()
        $timeout.flush()
        players[0].resolve true
        expect(delegate.notifyFinishedPlaying).toHaveBeenCalled()
        expect(delegate.end).toHaveBeenCalled()

      it "player.play が callback に false を渡すと、次のプレイヤーに対し play メッセージを送る関数が $timeout に登録される", ->
        expectPlaying = (n, b) ->
          if b
            expect(players[n].play).toHaveBeenCalledWith jasmine.any Function
          else
            expect(players[n].play).not.toHaveBeenCalled()

        expect(delegate.notifyStartingToPlay.calls.count()).toBe 0
        game.start()
        expect(delegate.notifyStartingToPlay.calls.count()).toBe 1

        expectPlaying 0, false
        expect($timeout.calls.count()).toBe 1
        $timeout.flush()
        expectPlaying 0, true


        expect(delegate.notifyStartingToPlay.calls.count()).toBe 1
        expect(delegate.notifyFinishedPlaying.calls.count()).toBe 0
        players[0].resolve false
        expect(delegate.notifyFinishedPlaying.calls.count()).toBe 1
        expect(delegate.notifyStartingToPlay.calls.count()).toBe 2


        expectPlaying 1, false
        expect($timeout.calls.count()).toBe 2
        $timeout.flush()
        expectPlaying 1, true


        expect(delegate.notifyStartingToPlay.calls.count()).toBe 2
        expect(delegate.notifyFinishedPlaying.calls.count()).toBe 1
        players[1].resolve false
        expect(delegate.notifyFinishedPlaying.calls.count()).toBe 2
        expect(delegate.notifyStartingToPlay.calls.count()).toBe 3


        expectPlaying 2, false
        expect($timeout.calls.count()).toBe 3
        $timeout.flush()
        expectPlaying 2, true

        expect(delegate.notifyStartingToPlay.calls.count()).toBe 3
        expect(delegate.notifyFinishedPlaying.calls.count()).toBe 2
        players[2].resolve true
        expect(delegate.notifyFinishedPlaying.calls.count()).toBe 3
        expect(delegate.notifyStartingToPlay.calls.count()).toBe 3

        expect(delegate.end).toHaveBeenCalled()

      it "pause を呼ぶと、現在 play 中の player の canPause が呼ばれる", ->
        game.start()
        $timeout.flush()
        expect(players[0].canPause).not.toHaveBeenCalled()
        game.pause()
        expect(players[0].canPause).toHaveBeenCalled()

      it "canPause が true を返すと player.pause が呼ばれ、delegate.notifyPausing が呼ばれる", ->
        players[0].canPause.and.returnValue true
        game.start()
        $timeout.flush()
        game.pause()
        expect(players[0].pause).toHaveBeenCalled()
        expect(delegate.notifyPausing).toHaveBeenCalled()

      it "canPause が false を返すと player.pause, delegate.notifyPausing は呼ばれない", ->
        players[0].canPause.and.returnValue false
        game.start()
        $timeout.flush()
        game.pause()
        expect(players[0].pause).not.toHaveBeenCalled()
        expect(delegate.notifyPausing).not.toHaveBeenCalled()

      it "pause が呼ばれた後で player が play を終了しても、状態は遷移しない", ->
        players[0].canPause.and.returnValue true
        game.start()
        $timeout.flush()
        game.pause()
        players[0].resolve false
        expect(delegate.notifyFinishedPlaying).not.toHaveBeenCalled()

        game.resume()
        players[0].resolve false
        expect(delegate.notifyFinishedPlaying).toHaveBeenCalled()

      it "pause が呼ばれた後で resume が呼ばれると player.resume, delegate.notifyResuming が呼ばれる", ->
        players[0].canPause.and.returnValue true
        game.start()
        $timeout.flush()
        game.pause()
        expect(players[0].resume).not.toHaveBeenCalled()
        expect(delegate.notifyResuming).not.toHaveBeenCalled()
        game.resume()
        expect(players[0].resume).toHaveBeenCalled()
        expect(delegate.notifyResuming).toHaveBeenCalled()

      it "pause が呼ばれる前に resume を呼んでも player.resume, delegate.notifyResuming は呼ばれない", ->
        players[0].canPause.and.returnValue true
        game.start()
        $timeout.flush()
        game.resume()
        expect(players[0].resume).not.toHaveBeenCalled()
        expect(delegate.notifyResuming).not.toHaveBeenCalled()

      it "start 前に stop を呼ぶと game は始まらない", ->
        game.stop()
        expect(delegate.stop).toHaveBeenCalled()

        game.start()
        expect(-> $timeout.verifyNoPendingTasks).not.toThrow()

      it "play 中に stop を呼ぶと play が強制終了される", ->
        game.start()
        $timeout.flush()

        expect(delegate.stop).not.toHaveBeenCalled()
        expect(delegate.notifyFinishedPlaying).not.toHaveBeenCalled()
        game.stop()
        expect(delegate.notifyFinishedPlaying).toHaveBeenCalled()
        expect(delegate.stop).toHaveBeenCalled()

      it "stop してから player が play を終了しても、結果は無視される", ->
        game.start()
        $timeout.flush()
        game.stop()
        players[0].resolve true
        expect(delegate.end).not.toHaveBeenCalled()

      it "pause 中に stop すると play が強制終了される", ->
        game.start()
        $timeout.flush()
        game.pause()
        expect(delegate.stop).not.toHaveBeenCalled()
        expect(delegate.notifyFinishedPlaying).not.toHaveBeenCalled()
        game.stop()
        expect(delegate.notifyFinishedPlaying).toHaveBeenCalled()
        expect(delegate.stop).toHaveBeenCalled()

      describe "渡す delegate の仕様", ->
        it "notifyStartingToPlay は任意である", ->
          delete delegate.notifyStartingToPlay
          expect(-> game.start()).not.toThrow()

        it "getNextPlayer は必須である", ->
          delete delegate.getNextPlayer
          expect(-> game.start()).toThrow()

        it "notifyFinishedPlaying は任意である", ->
          delete delegate.notifyFinishedPlaying
          game.start()
          $timeout.flush()
          expect(-> players[0].resolve false).not.toThrow()

        it "notifyPausing は任意である", ->
          delete delegate.notifyPausing
          players[0].canPause.and.returnValue true
          game.start()
          $timeout.flush()
          expect(-> game.pause()).not.toThrow()

        it "notifyResuming は任意である", ->
          delete delegate.notifyResuming
          players[0].canPause.and.returnValue true
          game.start()
          $timeout.flush()
          game.pause()
          expect(-> game.resume()).not.toThrow()

        it "end は任意である", ->
          delete delegate.end
          game.start()
          $timeout.flush()
          expect(-> players[0].resolve true).not.toThrow()

        it "stop は任意である", ->
          delete delegate.stop
          expect(-> game.stop()).not.toThrow()

      describe "player の仕様", ->
        it "play は必須である", ->
          delete players[0].play
          game.start()
          expect(-> $timeout.flush()).toThrow()

        it "canPause は任意である", ->
          delete players[0].canPause
          game.start()
          $timeout.flush()
          expect(-> game.pause()).not.toThrow()

        it "canPause がない場合は pause は不要である", ->
          delete players[0].canPause
          delete players[0].pause
          game.start()
          $timeout.flush()
          expect(-> game.pause()).not.toThrow()

        it "canPause が true を返す場合は、pause は必須である", ->
          delete players[0].pause
          players[0].canPause.and.returnValue true
          game.start()
          $timeout.flush()
          expect(-> game.pause()).toThrow()

        it "canPause が必ず false を返す場合は、pause は必須である", ->
          delete players[0].pause
          players[0].canPause.and.returnValue false
          game.start()
          $timeout.flush()
          expect(-> game.pause()).not.toThrow()

        it "canPause がない場合は resume は不要である", ->
          delete players[0].canPause
          delete players[0].resume
          game.start()
          $timeout.flush()
          game.pause()
          expect(-> game.resume()).not.toThrow()

        it "canPause が true を返す場合は、resume は必須である", ->
          delete players[0].resume
          players[0].canPause.and.returnValue true
          game.start()
          $timeout.flush()
          game.pause()
          expect(-> game.resume()).toThrow()

        it "canPause が必ず false を返す場合は、resume は必須である", ->
          delete players[0].resume
          players[0].canPause.and.returnValue false
          game.start()
          $timeout.flush()
          game.pause()
          expect(-> game.resume()).not.toThrow()

