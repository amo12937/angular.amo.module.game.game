"use strict"

do (moduleName = "amo.module.game.game_master", smModuleName = "amo.module.state_machine") ->
  describe "#{moduleName} の仕様", ->
    beforeEach module moduleName

    describe "#{moduleName}.GameMasterFsm の仕様", ->
      it "StateSetter を使用し、StateSetter().getFsm が返す値を返す", ->
        module ["$provide", ($provide) ->
          $provide.decorator "#{smModuleName}.StateSetter", ($delegate) ->
            holder = {$delegate}
            spyOn(holder, "$delegate").and.callThrough()
            return holder.$delegate
        ]

        inject ["#{smModuleName}.StateSetter", "#{moduleName}.GameMasterFsm", (StateSetter, GameMasterFsm) ->
          s = StateSetter()
          StateSetter.and.returnValue s

          expected = {}
          spyOn(s, "getFsm").and.returnValue expected

          actual = GameMasterFsm {}
          expect(actual).toBe expected
        ]

      describe "生成される fsm の挙動", ->
        fsm = null
        action = null

        beforeEach ->
          action = jasmine.createSpyObj "action", [
            "startToPlay"
            "finishPlaying"
            "canPause"
            "pause"
            "resume"
            "entryDone"
            "entryStopped"
          ]
          action.canPause.and.returnValue true
          inject ["#{moduleName}.GameMasterFsm", (GameMasterFsm) ->
            fsm = GameMasterFsm action
          ]

        describe "INIT 状態のとき", ->
          it "はじめは INIT 状態である", ->
            expect(fsm().isInit()).toBe true

          it "start が呼ばれると PLAYING 状態に遷移する", ->
            fsm().start()
            expect(fsm().isPlaying()).toBe true

          it "pause, resume, finish が呼ばれても状態は変化しない", ->
            for func in ["pause", "resume", "finish"]
              fsm()[func]()
              expect(fsm().isInit()).toBe true

          it "pause, resume が呼ばれても action の canPause, pause, resume は呼ばれない", ->
            fsm().pause()
            expect(action.canPause).not.toHaveBeenCalled()
            expect(action.pause).not.toHaveBeenCalled()
            fsm().resume()
            expect(action.resume).not.toHaveBeenCalled()

          it "stop が呼ばれると STOPPED 状態に遷移する", ->
            fsm().stop()
            expect(fsm().isStopped()).toBe true

        describe "PLAYING 状態のとき", ->
          beforeEach ->
            fsm().start()

          it "Entry 時に action.startToPlay が呼ばれる", ->
            expect(action.startToPlay).toHaveBeenCalled()

          it "start が呼ばれても状態は変化しない", ->
            fsm().start()
            expect(fsm().isPlaying()).toBe true

          it "pause が呼ばれると action.canPause が呼ばれる", ->
            fsm().pause()
            expect(action.canPause).toHaveBeenCalled()

          it "action.canPause が false を返すと action.pause は呼ばれない", ->
            action.canPause.and.returnValue false
            fsm().pause()
            expect(action.pause).not.toHaveBeenCalled()

          it "action.canPause が true を返すと action.pause が呼ばれる", ->
            fsm().pause()
            expect(action.pause).toHaveBeenCalled()

          it "pause に成功するとポーズ状態になる", ->
            fsm().pause()
            expect(fsm().isPlaying()).toBe true
            expect(fsm().isPausing()).toBe true

          describe "ポーズ状態のとき", ->
            beforeEach ->
              fsm().pause()

            it "start, pause, finish が呼ばれても状態は変化しない", ->
              for func in ["start", "pause", "finish"]
                fsm()[func]()
                expect(fsm().isPlaying()).toBe true
                expect(fsm().isPausing()).toBe true

            it "resume が呼ばれると action.resume が呼ばれ、ポーズ状態が解除される", ->
              fsm().resume()
              expect(action.resume).toHaveBeenCalled()
              expect(fsm().isPlaying()).toBe true
              expect(fsm().isPausing()).toBe false

            it "stop が呼ばれると STOPPED 状態に遷移する", ->
              fsm().stop()
              expect(fsm().isStopped()).toBe true
              expect(fsm().isPausing()).toBe false

          it "ポーズ状態でないときに resume が呼ばれても、action.resume は呼ばれず、状態は変化しない", ->
            fsm().resume()
            expect(action.resume).not.toHaveBeenCalled()
            expect(fsm().isPlaying()).toBe true

          it "finish に true が渡されると DONE 状態に遷移する", ->
            fsm().finish true
            expect(action.finishPlaying).toHaveBeenCalled()
            expect(fsm().isDone()).toBe true

          it "finish に false が渡されると再び PLAYING 状態に遷移する", ->
            expect(action.startToPlay.calls.count()).toBe 1
            fsm().finish false
            expect(action.finishPlaying).toHaveBeenCalled()
            expect(action.startToPlay.calls.count()).toBe 2
            expect(fsm().isPlaying()).toBe true

          it "stop が呼ばれると STOPPED 状態に遷移する", ->
            fsm().stop()
            expect(fsm().isStopped()).toBe true

        describe "DONE 状態のとき", ->
          beforeEach ->
            fsm().start()
            expect(action.entryDone).not.toHaveBeenCalled()
            fsm().finish true

          it "Entry 時に action.entryDone が呼ばれる", ->
            expect(action.entryDone).toHaveBeenCalled()

          it "start, pause, resume, finish, stop が呼ばれても状態は変化しない", ->
            for func in ["start", "pause", "resume", "finish", "stop"]
              fsm()[func]()
              expect(fsm().isDone()).toBe true

        describe "STOPPED 状態のとき", ->
          beforeEach ->
            expect(action.entryStopped).not.toHaveBeenCalled()
            fsm().stop()

          it "Entry 時に action.entryStopped が呼ばれる", ->
            expect(action.entryStopped).toHaveBeenCalled()

          it "start, pause, resume, finish, stop が呼ばれても状態は変化しない", ->
            for func in ["start", "pause", "resume", "finish", "stop"]
              fsm()[func]()
              expect(fsm().isStopped()).toBe true

