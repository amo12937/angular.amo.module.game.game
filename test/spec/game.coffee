"use strict"

do (amo = @[".amo"], moduleName = "amo.module.game.game") ->
  describe "#{moduleName} の仕様", ->
    beforeEach module moduleName

    describe "#{moduleName}.Game の仕様", ->
      $rootScope = null
      $timeout = null
      game = null
      delegate = null
      players = null
      beforeEach ->
        module ["$provide", ($provide) ->
          decorator = amo.test.helper.jasmine.spyOnDecorator spyOn
          $provide.decorator "$timeout", decorator
          return
        ]

        inject ["$rootScope", "$timeout", "$q", "#{moduleName}.Game", (_$rootScope, _$timeout, $q, Game) ->
          $rootScope = _$rootScope
          $timeout = _$timeout

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
            deferred = null
            play: jasmine.createSpy("p[#{n}].play").and.callFake ->
              deferred = $q.defer()
              return deferred.promise
            resolve: (result) ->
              return unless deferred
              deferred.resolve result
              $rootScope.$digest()
              deferred = null

          delegate.getNextPlayer.and.callFake do (s = 0) -> ->
            p = players[s]
            s = (s + 1) % players.length
            return p

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
        expect(players[0].play).toHaveBeenCalled()

      it "players[0].play() が返す promise に true が渡されると、ゲームが終了する", ->
        game.start()
        $timeout.flush()
        players[0].resolve true
        expect(delegate.notifyFinishedPlaying).toHaveBeenCalled()
        expect(delegate.end).toHaveBeenCalled()

      it "player.play が callback に false を渡すと、次のプレイヤーに対し play メッセージを送る関数が $timeout に登録される", ->
        expectPlaying = (n, b) ->
          if b
            expect(players[n].play).toHaveBeenCalled()
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

      it "pause が呼ばれると paused が true になる", ->
        game.start()
        expect(game.paused()).toBe false
        game.pause()
        expect(game.paused()).toBe true

      it "pause が呼ばれると delegate.notifyPausing が呼ばれる", ->
        game.start()
        expect(delegate.notifyPausing).not.toHaveBeenCalled()
        game.pause()
        expect(delegate.notifyPausing).toHaveBeenCalled()

      it "pause を2回連続で呼んでも、 delegate.notifyPausing は1度だけしか呼ばれない", ->
        game.start()
        game.pause()
        expect(delegate.notifyPausing.calls.count()).toBe 1
        game.pause()
        expect(delegate.notifyPausing.calls.count()).toBe 1

      it "game が start する前は pause を呼んでも paused は true にならない", ->
        game.pause()
        expect(game.paused()).toBe false

      it "pause を読んだあと resume を呼ぶと paused が解除される", ->
        game.start()
        game.pause()
        expect(game.paused()).toBe true
        game.resume()
        expect(game.paused()).toBe false

      it "paused の時に player が play を終了しても、状態は遷移しない", ->
        game.start()
        $timeout.flush()
        game.pause()
        players[0].resolve false
        expect(delegate.notifyFinishedPlaying).not.toHaveBeenCalled()

        game.resume()
        $rootScope.$digest()
        expect(delegate.notifyFinishedPlaying).toHaveBeenCalled()
        expect(delegate.notifyStartingToPlay).toHaveBeenCalled()

      it "pause が呼ばれた後で resume が呼ばれると delegate.notifyResuming が呼ばれる", ->
        game.start()
        game.pause()
        expect(delegate.notifyResuming).not.toHaveBeenCalled()
        game.resume()
        expect(delegate.notifyResuming).toHaveBeenCalled()

      it "pause が呼ばれる前に resume を呼んでも delegate.notifyResuming は呼ばれない", ->
        game.start()
        game.resume()
        expect(delegate.notifyResuming).not.toHaveBeenCalled()

      it "resume を2回連続で呼んでも、delegate.notifyResuming は1度だけしか呼ばれない", ->
        game.start()
        game.pause()
        game.resume()
        expect(delegate.notifyResuming.calls.count()).toBe 1
        game.resume()
        expect(delegate.notifyResuming.calls.count()).toBe 1

      it "start 前に stop を呼ぶと game は始まらない", ->
        game.stop()
        expect(delegate.stop).toHaveBeenCalled()

        game.start()
        expect(delegate.notifyStartingToPlay).not.toHaveBeenCalled()

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
          game.start()
          expect(-> game.pause()).not.toThrow()

        it "notifyResuming は任意である", ->
          delete delegate.notifyResuming
          game.start()
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

