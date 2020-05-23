module ManyDecks.Pages.Decks.Route exposing
    ( Route(..)
    , parser
    , toUrl
    )

import ManyDecks.Pages.Decks.Deck as Deck
import Url.Builder as Url
import Url.Parser exposing (..)


type Route
    = List
    | View Deck.Code
    | Edit Deck.Code


toUrl : Route -> String
toUrl route =
    case route of
        List ->
            Url.absolute [ "decks" ] []

        View code ->
            Url.absolute [ "decks", code |> Deck.codeToString ] []

        Edit code ->
            Url.absolute [ "decks", code |> Deck.codeToString, "edit" ] []


parser : Parser (Route -> c) c
parser =
    oneOf
        [ top |> map List
        , codeParser </> s "edit" |> map Edit
        , codeParser |> map View
        ]


codeParser : Parser (Deck.Code -> c) c
codeParser =
    string |> map Deck.code
