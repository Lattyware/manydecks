module ManyDecks.Auth.Twitch exposing
    ( Method
    , authPayload
    , decode
    , requestUrl
    )

import Json.Decode as Json
import Json.Decode.Pipeline as Json
import Json.Encode
import Url.Builder as Url


type alias Method =
    { id : String }


authPayload : String -> Maybe Json.Value
authPayload fragment =
    let
        parts =
            fragment |> String.split "&" |> List.map (String.split "=")

        extractIdToken part =
            case part of
                name :: value :: [] ->
                    if name == "id_token" then
                        Just value

                    else
                        Nothing

                _ ->
                    Nothing

        encode token =
            let
                encodedTokens =
                    [ ( "id", token |> Json.Encode.string ) ]
            in
            [ ( "twitch", encodedTokens |> Json.Encode.object ) ] |> Json.Encode.object
    in
    parts |> List.filterMap extractIdToken |> List.head |> Maybe.map encode


decode : Json.Decoder Method
decode =
    Json.succeed Method
        |> Json.required "id" Json.string


requestUrl : String -> Method -> String
requestUrl origin { id } =
    let
        clientId =
            id |> Url.string "client_id"

        claims =
            [ ( "id_token", [ ( "preferred_username", Json.Encode.null ) ] |> Json.Encode.object ) ]
                |> Json.Encode.object
                |> Json.Encode.encode 0
                |> Url.string "claims"

        redirectUri =
            Url.crossOrigin origin [ "sign-in" ] [] |> Url.string "redirect_uri"

        responseType =
            "id_token" |> Url.string "response_type"

        scope =
            "openid" |> Url.string "scope"
    in
    Url.crossOrigin "https://id.twitch.tv"
        [ "oauth2", "authorize" ]
        [ clientId, redirectUri, responseType, scope, claims ]
