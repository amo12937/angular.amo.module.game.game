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
Game に delegate を渡すと game インスタンスが生成される。

ゲームを始めるには、game インスタンスに対して start メッセージを送ればよい。
あとは player や board に適切なメッセージが送信され、ゲームが勝手に進行する。

delegate に必要なのは、現在誰の手番なのかを取得するための delegate.getNextPlayer のみである。

```coffee
angular.module "yourApp", "amo.module.game.game"
.controller ["amo.module.game.game.Game", (Game) ->
  # ...
  game = Game delegate
  game.start()
]
```

# delegate
delegate は以下のメソッドを実装することができる。

| method | required | description |
|:-------|:---------|:------------|
| notifyStartingToPlay | x | 1 回の play のはじめに呼び出される |
| getNextPlayer | o | 次にプレイする player を返す関数。notifyStartingToPlay の後に一度だけ呼び出される |
| notifyFinishedPlaying | x | 1 回の play の終わりに呼び出される |
| notifyPausing | x | game.pause() を呼び出し、player.canPause() が true を返した場合に呼び出される |
| notifyResuming | x | game がポーズ中で、game.resume() が呼び出された場合に呼び出される |
| end | x | ゲームが終了したタイミングで呼び出される |
| stop | x | ゲームが停止したタイミングで呼び出される |

# player
player は以下のメソッドを実装することができる。

| method | required | description |
|:--|:--|:--|
| play | o | delegate.notifyStartingToPlay と delegate.notifyFinishedPlaying の間に 1 度だけ呼び出される。1 play は player.play の呼び出しから 第1引数 callback が実行されるまでで、callback に渡す値が true の場合にゲーム終了、 false の場合に 次の player の play がはじまる。 |
| canPause | x | pause 可能かどうかを返す。定義されない場合は pause されない |
| pause | * | canPause が定義され、true を返した場合に呼ばれる。canPause が true の場合には必須だが、そうでない場合は任意。 |
| resume | * | 中断状態が解除された場合に呼ばれる。 canPause が true の場合には必須 |



