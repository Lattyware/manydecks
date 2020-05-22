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
    | Edit Deck.Code


toUrl : Route -> String
toUrl route =
    case route of
        List ->
            Url.absolute [ "decks" ] []

        Edit code ->
            Url.absolute [ "decks", code |> Deck.codeToString ] []


parser : Parser (Route -> c) c
parser =
    oneOf
        [ top |> map List
        , codeParser |> map Edit
        ]


codeParser : Parser (Deck.Code -> c) c
codeParser =
    string |> map Deck.code
