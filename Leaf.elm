module Leaf(State, initialState, nextState, plotPoints) where
import Window
import Generator
import Generator.Standard
import Debug
import IntRange (to)
import IntRange

{- Define constants -}

sidaWidth=500
sidaHeight=500
    
randomSeed : Int
randomSeed = 12346789

{- State -}

type Gen = Generator.Generator Generator.Standard.Standard
type State =
    { points: Path
    , gen: Gen
    }

initialState : State
initialState = State [(0,0)] (Generator.Standard.generator randomSeed)

{- Update -}

nextState : Float -> Int -> State -> State
nextState dx num initState =
    let -- 点を1つ増やすステップ。foldlに渡して使用。
      addPoints dx _ acc = -- : Float -> a -> State -> State
          let (pos, nGen) = transformStep (head acc.points) acc.gen dx
          in {acc| points <- (pos::acc.points)
                 , gen <- nGen }
    in IntRange.foldl (addPoints dx) initState (0 `to` num)

{- フラクタルな点列の一つをアフィン変換で計算する。 -}
transformStep : (Float, Float) -> Gen -> Float -> ((Float, Float), Gen)
transformStep (x, y) gen0 dx =
    let
      (rnd32, gen1) = Generator.int32 gen0
      rnd = rnd32 % 100
      nextXY = if | rnd > 15 -> ((dx) * x + (1-dx) * y, -(1-dx) * x + dx * y + 0.169)
                  | rnd > 8  -> (-0.141 * x + 0.302 * y, 0.302 * x + 0.141 * y + 0.127)
                  | rnd > 1  -> (0.141 * x - 0.302 * y, 0.302 * x + 0.141 * y + 0.169)
                  | otherwise -> (0, 0.175337 * y)
    in (nextXY, gen1)

{- Display -}

{- 点列を描画。-}
plotPoints : [(Float,Float)] -> [Form]
plotPoints = map (\(x,y) -> move (x*sidaWidth,y*sidaHeight-sidaHeight/2) <| filled green <| square 1)

{- puts it all together and shows it on screen. -}
{- 以降はデモ用(Leaf.elmをメインモジュールとして実行した場合のみ使用) -}

drawLeaf : Float -> Int -> [Form]
drawLeaf dx num = (nextState dx num initialState).points |> plotPoints

main : Signal Element
main = let disp (w,h) = collage w h (drawLeaf 0.5 1000)
       in disp <~ Window.dimensions
