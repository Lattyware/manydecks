module ManyDecks.Auth.Google exposing
    ( Method
    , authPayload
    , authResult
    , decode
    )

import Json.Decode as Json
import Json.Decode.Pipeline as Json
import Json.Encode


type alias Method =
    { id : String }


authPayload : String -> Json.Value
authPayload code =
    [ ( "google", code |> Json.Encode.string ) ] |> Json.Encode.object


decode : Json.Decoder Method
decode =
    Json.succeed Method
        |> Json.required "id" Json.string


authResult : Json.Decoder (Result String String)
authResult =
    let
        codeOrError code =
            case code of
                Just c ->
                    Json.succeed Ok
                        |> Json.required "code" Json.string

                Nothing ->
                    Json.succeed Err
                        |> Json.required "error" Json.string
    in
    Json.maybe (Json.field "code" Json.string) |> Json.andThen codeOrError
