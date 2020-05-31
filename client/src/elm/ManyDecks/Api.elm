module ManyDecks.Api exposing
    ( backup
    , browseDecks
    , createDeck
    , deleteDeck
    , deleteProfile
    , getAuthMethods
    , getDeck
    , getDecks
    , getLanguages
    , save
    , saveProfile
    , signIn
    )

import Bytes exposing (Bytes)
import Http
import Json.Decode
import Json.Encode as Json
import Json.Patch
import Json.Patch.Invertible as Json
import ManyDecks.Auth as Auth exposing (Auth)
import ManyDecks.Auth.Methods as Auth
import ManyDecks.Deck as Deck exposing (Deck)
import ManyDecks.Error as Error
import ManyDecks.Error.Model as Error exposing (Error)
import ManyDecks.Messages exposing (Msg(..))
import ManyDecks.Pages.Decks.Browse.Model as Browse
import ManyDecks.Pages.Decks.Model as Decks
import ManyDecks.User as User
import Url.Builder as Url


apiUrl : List String -> String
apiUrl path =
    Url.absolute ("api" :: path) []


queryApiUrl : List String -> List Url.QueryParameter -> String
queryApiUrl path queries =
    Url.absolute ("api" :: path) queries


getLanguages : (List String -> Msg) -> Cmd Msg
getLanguages handleSuccess =
    Http.get
        { url = apiUrl [ "languages" ]
        , expect = expectJsonOrError handleSuccess (Json.Decode.list Json.Decode.string)
        }


getAuthMethods : (Auth.Methods -> Msg) -> Cmd Msg
getAuthMethods handleSuccess =
    Http.get
        { url = apiUrl [ "auth" ]
        , expect = expectJsonOrError handleSuccess Auth.decode
        }


signIn : Json.Value -> (Auth -> Msg) -> Cmd Msg
signIn authPayload handleSuccess =
    Http.post
        { url = apiUrl [ "users" ]
        , body = authPayload |> Http.jsonBody
        , expect = expectJsonOrError handleSuccess Auth.decoder
        }


getDeck : Deck.Code -> (Deck -> Msg) -> Cmd Msg
getDeck code toMsg =
    Http.get
        { url = apiUrl [ "decks", code |> Deck.codeToString ]
        , expect = expectJsonOrError toMsg Deck.decode
        }


getDecks : User.Id -> Maybe String -> (List Decks.CodeAndSummary -> Msg) -> Cmd Msg
getDecks id token toMsg =
    let
        body =
            case token of
                Just t ->
                    [ ( "token", t |> Json.string ) ]

                Nothing ->
                    []
    in
    Http.post
        { url = apiUrl [ "decks", "by", id ]
        , body = body |> Json.object |> Http.jsonBody
        , expect = expectJsonOrError toMsg (Decks.codeAndSummaryDecoder |> Json.Decode.list)
        }


browseDecks : Browse.Query -> (List Decks.CodeAndSummary -> Msg) -> Cmd Msg
browseDecks { page, language, search } toMsg =
    let
        queries =
            [ search |> Maybe.map (Url.string "q")
            , language |> Maybe.map (Url.string "l")
            , Url.int "p" (page - 1) |> Just
            ]
    in
    Http.get
        { url = queryApiUrl [ "decks", "browse" ] (queries |> List.filterMap identity)
        , expect = expectJsonOrError toMsg (Decks.codeAndSummaryDecoder |> Json.Decode.list)
        }


createDeck : String -> Deck -> (Deck.Code -> Msg) -> Cmd Msg
createDeck token d toMsg =
    Http.post
        { url = apiUrl [ "decks" ]
        , body =
            [ ( "token", token |> Json.string )
            , ( "initial", d |> Deck.encode )
            ]
                |> Json.object
                |> Http.jsonBody
        , expect = expectJsonOrError toMsg Deck.codeDecoder
        }


deleteDeck : String -> Deck.Code -> (Deck.Code -> Msg) -> Cmd Msg
deleteDeck token code toMsg =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = apiUrl [ "decks", code |> Deck.codeToString ]
        , body = [ ( "token", token |> Json.string ) ] |> Json.object |> Http.jsonBody
        , expect = expectJsonOrError toMsg Deck.codeDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


save : String -> Deck.Code -> Json.Patch -> (Deck -> Msg) -> Cmd Msg
save token code patch toMsg =
    Http.request
        { method = "PATCH"
        , headers = []
        , url = apiUrl [ "decks", code |> Deck.codeToString ]
        , body =
            [ ( "token", token |> Json.string )
            , ( "patch", patch |> Json.toPatch |> Json.Patch.encoder )
            ]
                |> Json.object
                |> Http.jsonBody
        , expect = expectJsonOrError toMsg Deck.decode
        , timeout = Nothing
        , tracker = Nothing
        }


backup : String -> (Bytes -> Msg) -> Cmd Msg
backup token toMsg =
    Http.post
        { url = apiUrl [ "backup" ]
        , body =
            [ ( "token", token |> Json.string ) ]
                |> Json.object
                |> Http.jsonBody
        , expect = expectBytesOrError toMsg
        }


saveProfile : String -> String -> (Auth.Auth -> Msg) -> Cmd Msg
saveProfile token name toMsg =
    Http.post
        { url = apiUrl [ "users" ]
        , body =
            [ ( "token", token |> Json.string )
            , ( "name", name |> Json.string )
            ]
                |> Json.object
                |> Http.jsonBody
        , expect = expectJsonOrError toMsg Auth.decoder
        }


deleteProfile : String -> (() -> Msg) -> Cmd Msg
deleteProfile token toMsg =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = apiUrl [ "users" ]
        , body = [ ( "token", token |> Json.string ) ] |> Json.object |> Http.jsonBody
        , expect = expectJsonOrError toMsg (Json.Decode.succeed ())
        , timeout = Nothing
        , tracker = Nothing
        }


expectJsonOrError : (value -> Msg) -> Json.Decode.Decoder value -> Http.Expect Msg
expectJsonOrError toMsg decoder =
    let
        onGoodStatus =
            Json.Decode.decodeString decoder >> Result.mapError (Error.BadResponse >> Error.Application)

        onBadStatus body =
            case body |> Json.Decode.decodeString Error.decode of
                Ok error ->
                    error

                Err jsonError ->
                    jsonError |> Error.BadResponse |> Error.Application
    in
    handle onGoodStatus onBadStatus |> Http.expectStringResponse (toMsgHandlingErrors toMsg)


expectBytesOrError : (Bytes -> Msg) -> Http.Expect Msg
expectBytesOrError toMsg =
    handle Ok (Error.ServerError |> Error.Application |> always)
        |> Http.expectBytesResponse (toMsgHandlingErrors toMsg)


handle : (body -> Result Error value) -> (body -> Error) -> Http.Response body -> Result Error value
handle onGoodStatus onBadStatus response =
    case response of
        Http.BadUrl_ url ->
            url |> Error.InvalidUrl |> Error.Application |> Err

        Http.Timeout_ ->
            Error.ServerDown |> Error.Transient |> Err

        Http.NetworkError_ ->
            Error.NetworkError |> Error.Transient |> Err

        Http.BadStatus_ { statusCode } body ->
            if statusCode >= 502 && statusCode <= 504 then
                Error.ServerDown |> Error.Transient |> Err

            else
                onBadStatus body |> Err

        Http.GoodStatus_ _ body ->
            onGoodStatus body


toMsgHandlingErrors : (value -> Msg) -> Result Error value -> Msg
toMsgHandlingErrors toMsg result =
    case result of
        Ok value ->
            toMsg value

        Err error ->
            error |> SetError
