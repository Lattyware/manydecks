module ManyDecks.Pages.Decks.Browse exposing (..)

import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Keyed as HtmlK
import ManyDecks.Auth exposing (Auth)
import ManyDecks.Deck as Deck
import ManyDecks.Messages as Global
import ManyDecks.Model as Global
import ManyDecks.Pages.Decks.Browse.Messages exposing (..)
import ManyDecks.Pages.Decks.Browse.Model exposing (..)
import ManyDecks.Pages.Decks.Route as Decks
import ManyDecks.Pages.Decks.Summary as Summary
import ManyDecks.Route as Route
import Material.Card as Card
import Material.IconButton as IconButton
import Material.TextField as TextField


update : Msg -> Global.Model -> ( Global.Model, Cmd Global.Msg )
update msg model =
    case msg of
        ReceiveDecks page ->
            case model.route of
                Global.Decks (Decks.Browse wantedPage wantedSearch) ->
                    if wantedSearch == page.search && wantedPage == page.index then
                        ( { model | browse = Just { page = page, searchQuery = page.search |> Maybe.withDefault "" } }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SetSearchQuery query ->
            case model.browse of
                Just browse ->
                    let
                        newBrowse =
                            { browse | searchQuery = query }
                    in
                    ( { model | browse = Just newBrowse }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        DoSearch query ->
            let
                q =
                    if String.isEmpty query then
                        Nothing

                    else
                        Just query
            in
            ( model, Decks.Browse 1 q |> Global.Decks |> Route.redirectTo model.navKey )


view : Maybe Auth -> Int -> Maybe String -> Model -> List (Html Global.Msg)
view auth page search model =
    let
        deck codeAndSummary =
            ( codeAndSummary.code |> Deck.codeToString, Summary.view auth codeAndSummary )

        decks =
            model.page.decks |> List.map deck
    in
    [ Card.view [ HtmlA.class "page browse" ]
        [ searchControls model.searchQuery
        , HtmlK.ul [ HtmlA.class "deck-list" ] decks
        , pageControls page search (model.page.decks |> List.length)
        ]
    ]


searchControls : String -> Html Global.Msg
searchControls query =
    let
        doSearch =
            query |> DoSearch |> Global.BrowseMsg
    in
    Html.div [ HtmlA.class "search" ]
        [ TextField.viewWithReturn "Search"
            TextField.Search
            query
            (SetSearchQuery >> Global.BrowseMsg |> Just)
            doSearch
            Global.NoOp
        , IconButton.view (Icon.search |> Icon.viewIcon) "Search" (doSearch |> Just)
        ]


pageControls : Int -> Maybe String -> Int -> Html Global.Msg
pageControls page search results =
    let
        previousAction =
            if page > 1 then
                Decks.Browse (page - 1) search |> Global.Decks |> Global.ChangePage |> Just

            else
                Nothing

        current =
            page |> String.fromInt |> Html.text

        nextAction =
            if results >= 20 then
                Decks.Browse (page + 1) search |> Global.Decks |> Global.ChangePage |> Just

            else
                Nothing

        parts =
            [ IconButton.view (Icon.arrowLeft |> Icon.viewIcon) "Previous Page" previousAction
            , current
            , IconButton.view (Icon.arrowRight |> Icon.viewIcon) "Next Page" nextAction
            ]
    in
    Html.div [ HtmlA.class "page-controls" ] parts


wrap : Msg -> Global.Msg
wrap =
    Global.BrowseMsg
