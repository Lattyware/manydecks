module ManyDecks.Pages.Decks.Route exposing
    ( Route(..)
    , parser
    , toUrl
    )

import ManyDecks.Deck as Deck
import ManyDecks.Pages.Decks.Browse.Model as Browse
import ManyDecks.User as User
import Url.Builder as Url
import Url.Parser exposing (..)
import Url.Parser.Query as Query


type Route
    = Browse Browse.Query
    | List User.Id
    | View Deck.Code
    | Edit Deck.Code


toUrl : Route -> String
toUrl route =
    case route of
        List id ->
            Url.absolute [ "decks", "by", id ] []

        View code ->
            Url.absolute [ "decks", code |> Deck.codeToString ] []

        Edit code ->
            Url.absolute [ "decks", code |> Deck.codeToString, "edit" ] []

        Browse { page, language, search } ->
            let
                p =
                    if page < 2 then
                        Nothing

                    else
                        page |> String.fromInt |> Just

                path =
                    [ Just "decks", p ] |> List.filterMap identity

                query =
                    [ language |> Maybe.map (Url.string "l"), search |> Maybe.map (Url.string "q") ]
            in
            Url.absolute path (query |> List.filterMap identity)


parser : Parser (Route -> c) c
parser =
    oneOf
        [ top <?> Query.string "l" <?> Query.string "q" |> map (\l q -> Browse.Query 1 l q |> Browse)
        , int <?> Query.string "l" <?> Query.string "q" |> map (\p l q -> Browse.Query p l q |> Browse)
        , s "by" </> string |> map List
        , codeParser </> s "edit" |> map Edit
        , codeParser |> map View
        ]


codeParser : Parser (Deck.Code -> c) c
codeParser =
    string |> map Deck.code
