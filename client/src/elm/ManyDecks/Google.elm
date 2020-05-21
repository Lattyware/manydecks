module ManyDecks.Google exposing (..)

import Http
import Json.Decode as Json
import Json.Decode.Pipeline as Json
import Json.Encode
import ManyDecks.Auth as Auth exposing (Auth)


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


signIn : String -> (Result Http.Error Auth -> msg) -> Cmd msg
signIn code toMsg =
    Http.post
        { url = "/api/users"
        , body = [ ( "google", code |> Json.Encode.string ) ] |> Json.Encode.object |> Http.jsonBody
        , expect = Http.expectJson toMsg Auth.decoder
        }
