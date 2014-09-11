module Gauge where

import Window
import Mouse
import Text (..)
import Debug

{- User input -}

data UserInput = MouseUp Int | MouseDown Int | MouseMove Int

userInput : Signal UserInput
userInput = merges [ MouseMove <~ Mouse.x
                    , (\mouseDown -> if mouseDown then MouseDown else MouseUp) <~ Mouse.isDown ~ Mouse.x ]

type GaugeInput = { timeDelta:Float, userInput:UserInput }

{- State -}

type State = {x:Int, mouseDown:Bool}

defaultGauge : State
defaultGauge = {x=0, mouseDown=False}

{- Update -}

stepGauge : GaugeInput -> State -> State
stepGauge {timeDelta,userInput} gaugeState =
   case userInput of
      MouseUp x -> {gaugeState|x<-x,mouseDown<-False}
      MouseDown x -> {gaugeState|x<-x,mouseDown<-True}
      MouseMove x -> {gaugeState|x<-x}

{- Display -}

gaugeValue : Int -> Int -> Float
gaugeValue w x =
    min 1 <| max 0 <| (toFloat x) / (toFloat w-100)

getRoundedValue : Float -> Float
getRoundedValue x =
    toFloat (round ( x * 10)) / 10

gauge : (Int, Int) -> Int -> [Form]
gauge (w,h) x = let
    hw = toFloat w/2
    hh = toFloat h/2
    x1 = -hw+50
    y1 = hh-50
    x2 = hw-50
    y2 = hh-50
    mx = min x2 <| max x1 (toFloat x-hw)
    val = getRoundedValue <| gaugeValue w x
  in
    [ filled red <| polygon [ (x1,y1-2), (x2,y2-2), (x2,y2+2), (x1,y1+2) ]
    , circle 10 |> filled red |> move (mx,y1)
    , leftAligned (style {defaultStyle|color<-red} (toText << show <| val)) |> toForm |> move (mx, y1+20) ]

display : (Int,Int) -> State -> Element
display (w,h) gaugeState = collage w h (if gaugeState.mouseDown then gauge (w,h) gaugeState.x
                                       else [])

{- puts it all together and shows it on screen. -}

delta : Signal Float
delta = fps 10

input : Signal GaugeInput
input = sampleOn delta (lift2 GaugeInput delta userInput)

gaugeState : Signal State
gaugeState = foldp stepGauge defaultGauge input

main : Signal Element
main =
    let _ = (Debug.watch "gs" gaugeState)
    in lift2 display Window.dimensions gaugeState
