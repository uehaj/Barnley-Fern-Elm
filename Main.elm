module Main where
import Window
import Mouse
import Text (..)
import Debug
import Leaf
import Gauge

{- Define constants -}

threshold = 2000 -- 1フレーム描画にかかる時間(ミリ秒)のしきい値

{- 1フレームで計算して追加する点の個数。点の個数は累積的に追加されるの
   で表示に要する描画時間は増えていく。そのままにしておくと徐々にレスポ
   ンスが悪くなる一方なので、フレームごとの描画時間を計測し、その時間が
   しきい値を越えた時点でフレームごとに追加する点の数を半減させて調整す
   る。この値が0になると画面は変化しなくなる。-}
initialPointsPerFrame = 4000

{- User input -}

-- 入力イベント情報(時間経過、マウスボタン押下(MouseDown)、離す(MouseUp))
data Event = TimeTick Time Int Int Int | MouseUp Int | MouseDown Int | MouseMove Int

{- State -}

type State =
    { leafState:Leaf.State
    , mouseDown:Bool
    , dx:Int
    , pointsPerFrame:Int
    }

initialState : State
initialState = State Leaf.initialState False 500 initialPointsPerFrame

{- Update -}

nextState : Event -> State -> State
nextState event oldState =
    case event of
      -- 一定時刻経過のイベント。
      TimeTick tim x w h ->
        let d1 = (Debug.watch "tim" tim)
            d2 = (Debug.watch "pointsPerFrame" oldState.pointsPerFrame)
        in
          if (oldState.mouseDown) then -- マウスボタンを押下したままのドラッグ時には点数を減らしアニメーションを軽快にする
              {oldState| leafState <- Leaf.nextState (Gauge.gaugeValue w x) 200  Leaf.initialState }
          else
              if (tim > threshold) then -- 閾値以上の時間が描画にかかるなら1フレームあたりの追加描画点列数を半減。
                  {oldState| pointsPerFrame <- oldState.pointsPerFrame // 2 }
              else -- pointsPerFrame個の点列を計算
                  {oldState| leafState <- Leaf.nextState (Gauge.gaugeValue w oldState.dx) oldState.pointsPerFrame oldState.leafState }
      -- マウスボタン押下
      MouseDown x -> if oldState.mouseDown == False -- マウスボタンを押した瞬間
                     then {oldState| mouseDown <- True
                                   , leafState <- Leaf.initialState -- 累積計算されてきた点列は破棄し、初期状態に設定
                                   , pointsPerFrame <- initialPointsPerFrame }
                     else oldState
      -- 押下されていたマウスボタンを離した
      MouseUp x -> if oldState.mouseDown == True -- マウスボタンを離した瞬間
                     then { oldState| mouseDown <- False
                          , dx <- x }
                     else oldState

{- Display -}

background : Int -> Int -> Element
background w h = collage w h [ move (0,0) (filled black <| rect (toFloat w) (toFloat h)) ]

statusInfo : State -> String
statusInfo state = "points="++(state.leafState.points |> length |> show)
                   ++ if (state.mouseDown) then "" else " Click To Move"

statusLine : State -> Element
statusLine state =
     statusInfo state
         |> toText
         |> style {defaultStyle|color<-red}
         |> leftAligned

gaugeForm : State -> Int -> Int -> Int -> [Element]
gaugeForm state w h mx = if (state.mouseDown) then -- クリックしているときのみゲージが現われる
                             [ Gauge.gauge (w,h) mx |> collage w h ]
                         else []

display : State -> b -> Int -> Int -> Int -> Element
display state gauge w h mx =
    layers <| [ background w h
              , collage w h (Leaf.plotPoints state.leafState.points)
              , statusLine state ] ++ (gaugeForm state w h mx)

{- puts it all together and shows it on screen. -}

inputSignal : Signal Event
inputSignal = merges [ TimeTick <~ fps 5 ~ Mouse.x ~ Window.width ~ Window.height
                     , (\mouseDown -> if mouseDown then MouseDown else MouseUp) <~ Mouse.isDown ~ Mouse.x ]

currentState : Signal State
currentState = foldp nextState initialState inputSignal

main : Signal Element
main = display <~ currentState ~ Gauge.main ~ Window.width ~ Window.height ~ Mouse.x
