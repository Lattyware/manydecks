module Cards.Call.Part.Model exposing (..)

import Cards.Call.Style exposing (Style)
import Cards.Call.Transform exposing (Transform)


type Part
    = Text String Style
    | Slot Transform Style
