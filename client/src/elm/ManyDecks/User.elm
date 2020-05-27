module ManyDecks.User exposing
    ( Id
    , User
    , decode
    , encode
    )

import Json.Decode as Json
import Json.Decode.Pipeline as Json
import Json.Encode


type alias Id =
    String


type alias User =
    { id : Id
    , name : String
    }


decode : Json.Decoder User
decode =
    Json.succeed User
        |> Json.required "id" Json.string
        |> Json.required "name" Json.string


encode : User -> Json.Value
encode { id, name } =
    Json.Encode.object [ ( "id", Json.Encode.string id ), ( "name", Json.Encode.string name ) ]
