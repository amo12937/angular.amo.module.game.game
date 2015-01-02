# angular.amo.module.game.game

1 ゲームを表すステートマシンを提供する

# インストール方法
```
bower install -S angular.amo.module.game.game
```

```haml:index.haml
%script(src="bower_components/angular.amo.module.game.game/dist/js/game.min.js")
```

# game
game の役割は、各 player に適切なタイミングで play メッセージを送り、ゲームが終了したかを判定するのみである
インターフェースはとてもシンプルで、 start/pause/resume/stop の 4 メソッドしか無い。

Game に delegate を渡すと game インスタンスが生成される。
game に start メッセージを送ると、ゲームが開始される。
game が start したあとは player に順に play メッセージを送ることでゲームが勝手に進行する。

delegate に必要なのは、現在誰の手番なのかを取得するための delegate.getNextPlayer のみである。

```coffee
angular.module "yourApp", "amo.module.game.game"
.controller ["amo.module.game.game.Game", (Game) ->
  # ...
  delegate =
    getNextPlayer: ->
      if turn
        return black
      else
        return white
  game = Game delegate
  game.start()
]
```

| method | description |
|:-------|:------------|
| start | ゲームを開始する際に呼び出す。このメソッドは一度だけ呼べば良い。 |
| pause | このメソッドが呼び出されると、次に resume が呼ばれるまでゲームを中断できる。ゲーム中断中も play は続行されるが、次の player へは処理は渡らず、delegate.notifyFinishedPlaying は呼ばれない。 |
| resume | 中断中に呼び出されると、ゲームが再開される。play が終了していた場合は delegate.notifyFinishedPlaying が呼び出され、次の player へ処理が渡る。 |
| paused | 中断中の場合に true を返す |
| stop | ゲームを中止する。 |

# delegate
delegate は以下のメソッドを実装することができる。

| method | required | description |
|:-------|:---------|:------------|
| notifyStartingToPlay | x | 1 回の play のはじめに呼び出される |
| getNextPlayer | o | 次にプレイする player を返す関数。notifyStartingToPlay の後に一度だけ呼び出される |
| notifyFinishedPlaying | x | 1 回の play の終わりに呼び出される |
| notifyPausing | x | game.pause() を呼び出された場合に呼び出される |
| notifyResuming | x | game がポーズ中で、game.resume() が呼び出された場合に呼び出される |
| end | x | ゲームが終了したタイミングで呼び出される |
| stop | x | ゲームが停止したタイミングで呼び出される |

# player
player は以下のメソッドを実装することができる。

| method | required | description |
|:-------|:---------|:------------|
| play | o | delegate.notifyStartingToPlay と delegate.notifyFinishedPlaying の間に 1 度だけ呼び出される。play メソッドは、game が自分のターンで終了したかどうかを表す真偽値か、その promise を返す必要がある。true を返せば終了、 false を返せば次の player の play が呼ばれる。 |



