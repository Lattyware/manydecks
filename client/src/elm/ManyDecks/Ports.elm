port module ManyDecks.Ports exposing (..)

import Json.Decode as Json
import ManyDecks.Auth as Auth


port tryGoogleAuth : () -> Cmd msg


port googleAuthResult : (Json.Value -> msg) -> Sub msg


port json5Decode : String -> Cmd msg


port json5Decoded : (Json.Value -> msg) -> Sub msg


port storeAuth : Maybe Auth.Auth -> Cmd msg


port copy : String -> Cmd msg
