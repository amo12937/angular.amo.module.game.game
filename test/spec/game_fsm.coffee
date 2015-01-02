"use strict"

do (moduleName = "amo.module.game.game", smModuleName = "amo.module.state_machine") ->
  describe "#{moduleName} の仕様", ->
    beforeEach module moduleName

    describe "#{moduleName}.GameFsm の仕様", ->
      it "StateSetter を使用し、StateSetter().getFsm が返す値を返す", ->
        module ["$provide", ($provide) ->
          $provide.decorator "#{smModuleName}.StateSetter", ($delegate) ->
            holder = {$delegate}
            spyOn(holder, "$delegate").and.callThrough()
            return holder.$delegate
        ]

        inject ["#{smModuleName}.StateSetter", "#{moduleName}.GameFsm", (StateSetter, GameFsm) ->
          s = StateSetter()
          StateSetter.and.returnValue s

          expected = {}
          spyOn(s, "getFsm").and.returnValue expected

          actual = GameFsm {}
          expect(actual).toBe expected
        ]

      describe "生成される fsm の挙動", ->
        fsm = null
        action = null

        beforeEach ->
          action = jasmine.createSpyObj "action", [
            "startToPlay"
            "finishPlaying"
            "entryDone"
            "entryStopped"
          ]
          inject ["#{moduleName}.GameFsm", (GameFsm) ->
            fsm = GameFsm action
          ]

        describe "INIT 状態のとき", ->
          it "はじめは INIT 状態である", ->
            expect(fsm().isInit()).toBe true

          it "start が呼ばれると PLAYING 状態に遷移する", ->
            fsm().start()
            expect(fsm().isPlaying()).toBe true

          it "finish が呼ばれても状態は変化しない", ->
            fsm().finish()
            expect(fsm().isInit()).toBe true

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

          it "start, finish, stop が呼ばれても状態は変化しない", ->
            for func in ["start", "finish", "stop"]
              fsm()[func]()
              expect(fsm().isDone()).toBe true

        describe "STOPPED 状態のとき", ->
          beforeEach ->
            expect(action.entryStopped).not.toHaveBeenCalled()
            fsm().stop()

          it "Entry 時に action.entryStopped が呼ばれる", ->
            expect(action.entryStopped).toHaveBeenCalled()

          it "start, finish, stop が呼ばれても状態は変化しない", ->
            for func in ["start", "finish", "stop"]
              fsm()[func]()
              expect(fsm().isStopped()).toBe true

