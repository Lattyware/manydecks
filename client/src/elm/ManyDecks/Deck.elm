module ManyDecks.Deck exposing
    ( Code
    , Deck
    , Summary
    , code
    , codeDecoder
    , codeToString
    , decode
    , defaultInstructions
    , empty
    , encode
    , fromFileDeck
    , summaryDecoder
    , summaryOf
    , toFileDeck
    , viewCode
    , viewCodeMulti
    )

import Cards.Call as Call exposing (Call)
import Cards.Deck as FileDeck
import Cards.Response as Response exposing (Response)
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode as Json
import Json.Decode.Pipeline as Json
import Json.Encode
import ManyDecks.Auth as Auth exposing (Auth)
import ManyDecks.User as User exposing (User)
import Set


type alias Deck =
    { name : String
    , language : Maybe String
    , author : User
    , calls : List Call
    , responses : List Response
    , public : Bool
    , version : Int
    }


empty : String -> Auth -> Deck
empty defaultLanguage auth =
    { name = "New Deck"
    , language = Just defaultLanguage
    , author = auth |> Auth.toUser
    , calls = []
    , responses = []
    , public = False
    , version = 0
    }


encode : Deck -> Json.Value
encode deck =
    let
        maybeField field =
            case field of
                ( n, Just v ) ->
                    Just ( n, v )

                ( _, Nothing ) ->
                    Nothing

        maybeObject =
            List.filterMap maybeField >> Json.Encode.object

        publicValue =
            if deck.public then
                True |> Json.Encode.bool |> Just

            else
                Nothing

        parts =
            [ ( "name", Json.Encode.string deck.name |> Just )
            , ( "language", deck.language |> Maybe.map Json.Encode.string )
            , ( "author", deck.author |> User.encode |> Just )
            , ( "calls", deck.calls |> Json.Encode.list Call.encode |> Just )
            , ( "responses", deck.responses |> Json.Encode.list Response.encode |> Just )
            , ( "public", publicValue )
            , ( "version", deck.version |> Json.Encode.int |> Just )
            ]
    in
    maybeObject parts


decode : Json.Decoder Deck
decode =
    Json.succeed Deck
        |> Json.required "name" Json.string
        |> Json.optional "language" (Json.string |> Json.map Just) Nothing
        |> Json.required "author" User.decode
        |> Json.required "calls" (Json.list Call.decode)
        |> Json.required "responses" (Json.list Response.decode)
        |> Json.optional "public" Json.bool False
        |> Json.required "version" Json.int


type Code
    = Code String


codeDecoder : Json.Decoder Code
codeDecoder =
    Json.string |> Json.map Code


viewCode : (String -> msg) -> Code -> Html msg
viewCode copy c =
    viewCodeMulti copy "" c


viewCodeMulti : (String -> msg) -> String -> Code -> Html msg
viewCodeMulti copy suffix (Code c) =
    let
        id =
            c ++ suffix
    in
    Html.input
        [ id |> HtmlA.id
        , HtmlA.type_ "text"
        , HtmlA.readonly True
        , HtmlA.class "deck-code"
        , HtmlA.value c
        , id |> copy |> HtmlE.onClick
        ]
        []


codeToString : Code -> String
codeToString (Code c) =
    c


code : String -> Code
code string =
    string |> String.toUpper |> String.toList |> List.filter isValidChar |> String.fromList |> Code


validChars : Set.Set Char
validChars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" |> String.toList |> Set.fromList


isValidChar : Char -> Bool
isValidChar char =
    Set.member char validChars


type alias Summary =
    { name : String
    , author : User
    , language : Maybe String
    , calls : Int
    , responses : Int
    , public : Bool
    , version : Int
    }


summaryOf : Auth -> Deck -> Summary
summaryOf auth deck =
    { name = deck.name
    , author = auth |> Auth.toUser
    , language = deck.language
    , calls = deck.calls |> List.length
    , responses = deck.responses |> List.length
    , public = deck.public
    , version = deck.version
    }


summaryDecoder : Json.Decoder Summary
summaryDecoder =
    Json.succeed Summary
        |> Json.required "name" Json.string
        |> Json.required "author" User.decode
        |> Json.optional "language" (Json.string |> Json.map Just) Nothing
        |> Json.required "calls" Json.int
        |> Json.required "responses" Json.int
        |> Json.required "public" Json.bool
        |> Json.required "version" Json.int


defaultInstructions : Int -> List (Html msg)
defaultInstructions slots =
    let
        instruction amount name =
            Html.span [ HtmlA.class "instruction" ]
                [ Html.text name
                , Html.span [ HtmlA.class "amount" ]
                    [ amount |> String.fromInt |> Html.text ]
                ]

        pick =
            [ instruction slots "Pick" ]

        draw =
            if slots > 2 then
                [ instruction (slots - 2) "Draw" ]

            else
                []
    in
    [ draw, pick ] |> List.concat


fromFileDeck : Auth -> FileDeck.Deck -> Deck
fromFileDeck auth fileDeck =
    { name = fileDeck.name
    , language = fileDeck.language
    , author = auth |> Auth.toUser
    , calls = fileDeck.calls
    , responses = fileDeck.responses
    , public = False
    , version = 0
    }


toFileDeck : Deck -> FileDeck.Deck
toFileDeck deck =
    { name = deck.name
    , language = deck.language
    , author = Just deck.author.name
    , translator = Nothing
    , calls = deck.calls
    , responses = deck.responses
    }
