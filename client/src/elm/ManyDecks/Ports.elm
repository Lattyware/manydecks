port module ManyDecks.Ports exposing (..)

import Json.Decode as Json
import ManyDecks.Pages.Decks.Edit.CallEditor.Model exposing (Span)


port tryGoogleAuth : String -> Cmd msg


port googleAuthResult : (Json.Value -> msg) -> Sub msg


port json5Decode : String -> Cmd msg


port json5Decoded : (Json.Value -> msg) -> Sub msg


port storeAuth : Maybe Json.Value -> Cmd msg


port copy : String -> Cmd msg


port focus : String -> Cmd msg


port setCallInputGhostSelection : Span -> Cmd msg


port getCallInputGhostSelection : (Span -> msg) -> Sub msg
