module ManyDecks.Pages.Decks.Browse exposing (..)

import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Keyed as HtmlK
import ManyDecks.Auth exposing (Auth)
import ManyDecks.Deck as Deck
import ManyDecks.Language as Language
import ManyDecks.Messages as Global
import ManyDecks.Model as Global
import ManyDecks.Pages.Decks.Browse.Messages exposing (..)
import ManyDecks.Pages.Decks.Browse.Model exposing (..)
import ManyDecks.Pages.Decks.Route as Decks
import ManyDecks.Pages.Decks.Summary as Summary
import ManyDecks.Route as Route
import Material.Card as Card
import Material.IconButton as IconButton
import Material.Select as Select
import Material.TextField as TextField


update : Msg -> Global.Model -> ( Global.Model, Cmd Global.Msg )
update msg model =
    case model.route of
        Global.Decks (Decks.Browse query) ->
            case msg of
                ReceiveDecks page ->
                    if query == page.query then
                        ( { model | browse = Just { page = page, searchQuery = query.search |> Maybe.withDefault "" } }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                SetSearchQuery search ->
                    case model.browse of
                        Just browse ->
                            let
                                newBrowse =
                                    { browse | searchQuery = search }
                            in
                            ( { model | browse = Just newBrowse }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                DoSearch search ->
                    let
                        q =
                            if String.isEmpty search then
                                Nothing

                            else
                                Just search
                    in
                    ( model, Decks.Browse { query | page = 1, search = q } |> Global.Decks |> Route.redirectTo model.navKey )

        _ ->
            ( model, Cmd.none )


view : Maybe Auth -> List Language.Described -> Query -> Model -> List (Html Global.Msg)
view auth knownLanguages query model =
    let
        deck codeAndSummary =
            ( codeAndSummary.code |> Deck.codeToString, Summary.view auth knownLanguages codeAndSummary )

        decks =
            model.page.decks |> List.map deck
    in
    [ Card.view [ HtmlA.class "page browse" ]
        [ searchControls knownLanguages query model.searchQuery
        , HtmlK.ul [ HtmlA.class "deck-list" ] decks
        , pageControls query (model.page.decks |> List.length)
        ]
    ]


searchControls : List Language.Described -> Query -> String -> Html Global.Msg
searchControls knownLanguages query search =
    let
        doSearch =
            search |> DoSearch |> Global.BrowseMsg
    in
    Html.div [ HtmlA.class "search" ]
        [ TextField.viewWithReturn "Search"
            TextField.Search
            search
            (SetSearchQuery >> Global.BrowseMsg |> Just)
            doSearch
            Global.NoOp
        , IconButton.view (Icon.search |> Icon.viewIcon) "Search" (doSearch |> Just)
        , languageControl knownLanguages query
        ]


languageControl : List Language.Described -> Query -> Html Global.Msg
languageControl knownLanguages query =
    let
        all =
            { id = Nothing, icon = Nothing, primary = [ "All" |> Html.text ], secondary = Nothing, meta = Nothing }

        languageOption { code, description } =
            { id = Just code
            , icon = Nothing
            , primary = [ Html.span [ HtmlA.title description ] [ description |> Html.text ] ]
            , secondary = Nothing
            , meta = Nothing
            }

        fromString id =
            case id of
                "All" ->
                    Nothing

                code ->
                    Just code
    in
    Select.view
        { label = "Language"
        , idToString = Maybe.withDefault "All"
        , idFromString = fromString >> Just
        , selected = Just query.language
        , wrap = \l -> Decks.Browse { query | language = l |> Maybe.withDefault Nothing } |> Global.Decks |> Global.ChangePage
        , disabled = False
        , fullWidth = False
        }
        (all :: (knownLanguages |> List.map languageOption))


pageControls : Query -> Int -> Html Global.Msg
pageControls query results =
    let
        previousAction =
            if query.page > 1 then
                Decks.Browse { query | page = query.page - 1 } |> Global.Decks |> Global.ChangePage |> Just

            else
                Nothing

        current =
            query.page |> String.fromInt |> Html.text

        nextAction =
            if results >= 20 then
                Decks.Browse { query | page = query.page + 1 } |> Global.Decks |> Global.ChangePage |> Just

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
