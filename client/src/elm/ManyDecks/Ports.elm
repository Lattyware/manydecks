port module ManyDecks.Ports exposing
    ( copy
    , focus
    , getCallInputGhostSelection
    , googleAuthResult
    , json5Decode
    , json5Decoded
    , languageExpand
    , languageExpanded
    , languageResults
    , languageSearch
    , setCallInputGhostSelection
    , storeAuth
    , tryGoogleAuth
    )

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


port languageSearch : String -> Cmd msg


port languageResults : (Json.Value -> msg) -> Sub msg


port languageExpand : String -> Cmd msg


port languageExpanded : (List Json.Value -> msg) -> Sub msg
