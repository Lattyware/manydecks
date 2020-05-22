module ManyDecks.Pages.Decks.Edit.CallEditor.Model exposing (..)

import Cards.Call.Style exposing (Style)
import Cards.Call.Transform exposing (Transform)


type alias Model =
    { atoms : List Atom
    , selection : Span
    , selecting : Maybe Position
    , moving : Maybe Position
    , control : Bool
    }


type alias Position =
    Int


type alias Span =
    { start : Position
    , end : Position
    }


type Atom
    = Letter Char Style
    | Slot Transform Style
    | NewLine


type Msg
    = Enter Position
    | Leave Position
    | StartSelection Position
    | EndSelection Position
    | StartMoving Position
    | AddSlot
    | SetStyle Style
    | SetTransform Transform
    | UpdateFromGhost String
    | GhostSelectionChanged Span
