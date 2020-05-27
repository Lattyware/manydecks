module ManyDecks.Auth exposing
    ( Auth
    , Token
    , decoder
    , store
    , toUser
    )

import Json.Decode as Json
import Json.Encode
import Jwt
import ManyDecks.Ports as Ports
import ManyDecks.User exposing (User)


type alias Token =
    String


type alias Auth =
    { token : Token
    , id : String
    , name : String
    }


decoder : Json.Decoder Auth
decoder =
    let
        idDecoder =
            Json.field "sub" Json.string

        internal token =
            case token |> Jwt.decodeToken idDecoder of
                Ok id ->
                    Json.map (Auth token id)
                        (Json.field "name" Json.string)

                Err error ->
                    error |> Jwt.errorToString |> Json.fail
    in
    Json.field "token" Json.string |> Json.andThen internal


store : Maybe Auth -> Cmd msg
store auth =
    let
        encode a =
            Json.Encode.object
                [ ( "token", a.token |> Json.Encode.string )
                , ( "name", a.name |> Json.Encode.string )
                ]
    in
    auth |> Maybe.map encode |> Ports.storeAuth


toUser : Auth -> User
toUser auth =
    { id = auth.id
    , name = auth.name
    }
