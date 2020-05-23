module ManyDecks.Pages.Decks.Deck exposing
    ( Code
    , Summary
    , Versioned
    , code
    , codeDecoder
    , codeToString
    , summaryDecoder
    , summaryOf
    , versionedDecoder
    , viewCode
    , viewCodeMulti
    )

import Cards.Deck as Deck exposing (Deck)
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode as Json
import Json.Decode.Pipeline as Json
import Set


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
    , author : Maybe String
    , language : Maybe String
    , calls : Int
    , responses : Int
    , version : Int
    }


type alias Versioned =
    { deck : Deck
    , version : Int
    }


summaryOf : Versioned -> Summary
summaryOf { deck, version } =
    { name = deck.name
    , author = deck.author
    , language = deck.language
    , calls = deck.calls |> List.length
    , responses = deck.responses |> List.length
    , version = version
    }


summaryDecoder : Json.Decoder Summary
summaryDecoder =
    Json.succeed Summary
        |> Json.required "name" Json.string
        |> Json.optional "author" (Json.string |> Json.map Just) Nothing
        |> Json.optional "language" (Json.string |> Json.map Just) Nothing
        |> Json.required "calls" Json.int
        |> Json.required "responses" Json.int
        |> Json.required "version" Json.int


versionedDecoder : Json.Decoder Versioned
versionedDecoder =
    Json.map2 Versioned
        Deck.decode
        (Json.field "version" Json.int)
