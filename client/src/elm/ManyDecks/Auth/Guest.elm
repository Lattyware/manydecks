module ManyDecks.Auth.Guest exposing (..)

import Json.Decode as Json
import Json.Encode


type alias Method =
    {}


authPayload : Json.Value
authPayload =
    [ ( "guest", True |> Json.Encode.bool ) ] |> Json.Encode.object


decode : Json.Decoder Method
decode =
    Json.succeed {}
