module ManyDecks.Pages.Decks.Edit.CallEditor.Model exposing (..)

import Cards.Call.Style exposing (Style)
import Cards.Call.Transform exposing (Transform)


type alias Model =
    { atoms : List Atom
    , selection : Maybe Span
    , selecting : Maybe Position
    , moving : Maybe Position
    , hover : Maybe Position
    , cursor : Position
    , styled : List ( Span, Style )
    , control : Bool
    }


type alias Position =
    Int


type alias Span =
    { start : Position
    , end : Position
    }


type Atom
    = Letter Char
    | Slot Transform Style
    | NewLine


type Msg
    = Enter Position
    | Leave Position
    | StartSelection Position
    | EndSelection Position
    | StartMoving Position
    | KeyDown Key
    | KeyUp Key
    | AddSlot


type Key
    = Character Char
    | Control String
