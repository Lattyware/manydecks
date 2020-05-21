module ManyDecks.Auth exposing
    ( Auth
    , Token
    , decoder
    )

import Json.Decode as Json
import Json.Decode.Pipeline as Json


type alias Token =
    String


type alias Auth =
    { token : Token
    , name : String
    }


decoder : Json.Decoder Auth
decoder =
    Json.succeed Auth
        |> Json.required "token" Json.string
        |> Json.required "name" Json.string
