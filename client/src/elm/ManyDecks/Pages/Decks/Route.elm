module ManyDecks.Pages.Decks.Route exposing
    ( Route(..)
    , parser
    , toUrl
    )

import ManyDecks.Deck as Deck
import ManyDecks.User as User
import Url.Builder as Url
import Url.Parser exposing (..)
import Url.Parser.Query as Query


type Route
    = Browse Int (Maybe String)
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

        Browse page search ->
            let
                p =
                    if page < 1 then
                        Nothing

                    else
                        page |> String.fromInt |> Just

                path =
                    [ Just "decks", p ] |> List.filterMap identity

                query =
                    [ search |> Maybe.map (Url.string "q") ] |> List.filterMap identity
            in
            Url.absolute path query


parser : Parser (Route -> c) c
parser =
    oneOf
        [ top <?> Query.string "q" |> map (Browse 1)
        , int <?> Query.string "q" |> map Browse
        , s "by" </> string |> map List
        , codeParser </> s "edit" |> map Edit
        , codeParser |> map View
        ]


codeParser : Parser (Deck.Code -> c) c
codeParser =
    string |> map Deck.code
