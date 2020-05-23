module ManyDecks.Pages.Decks exposing (..)

import Browser.Navigation as Navigation
import File
import File.Select as File
import FontAwesome.Attributes as Icon
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import ManyDecks.Api as Api
import ManyDecks.Messages as Global
import ManyDecks.Model as Route exposing (Model)
import ManyDecks.Pages.Decks.Deck as Deck
import ManyDecks.Pages.Decks.Edit as Edit
import ManyDecks.Pages.Decks.List as List
import ManyDecks.Pages.Decks.Messages exposing (Msg(..))
import ManyDecks.Pages.Decks.Model exposing (CodeAndSummary)
import ManyDecks.Pages.Decks.Route as Route exposing (Route)
import ManyDecks.Pages.Decks.View as View
import ManyDecks.Ports as Ports
import ManyDecks.Route as GlobalRoute
import Task


update : Msg -> Model -> ( Model, Cmd Global.Msg )
update msg model =
    case msg of
        ReceiveDecks decks ->
            ( { model | decks = Just decks }, Cmd.none )

        UploadDeck ->
            ( model, File.file [ ".deck.json5" ] (UploadedDeck >> Global.DecksMsg) )

        UploadedDeck file ->
            ( model, file |> File.toString |> Task.perform (Json5Parse >> Global.DecksMsg) )

        Json5Parse raw ->
            ( model, Ports.json5Decode raw )

        NewDeck d ->
            let
                token =
                    model.auth |> Maybe.map .token |> Maybe.withDefault ""
            in
            ( model, Api.createDeck token d (\code -> EditDeck code (Just d) |> Global.DecksMsg) )

        EditDeck code maybeDeck ->
            case maybeDeck of
                Just d ->
                    let
                        route =
                            Route.Decks (Route.Edit code)

                        changeRouteIfNeeded =
                            if model.route == route then
                                Cmd.none

                            else
                                route |> GlobalRoute.toUrl |> Navigation.pushUrl model.navKey
                    in
                    ( { model | edit = d |> Edit.init |> Just }, changeRouteIfNeeded )

                Nothing ->
                    ( model, GlobalRoute.redirectTo (Route.Decks (Route.Edit code)) model.navKey )

        Delete code ->
            case model.auth of
                Just auth ->
                    let
                        newDecks =
                            model.decks |> Maybe.map (List.filter (\d -> d.code /= code))
                    in
                    ( { model | decks = newDecks, edit = Nothing }
                    , Api.deleteDeck auth.token code (DeckDeleted >> Global.DecksMsg)
                    )

                Nothing ->
                    ( model, GlobalRoute.redirectTo (Route.Login Nothing) model.navKey )

        DeckDeleted code ->
            let
                newDecks =
                    model.decks |> Maybe.map (List.filter (\d -> d.code /= code))
            in
            ( { model | decks = newDecks, edit = Nothing }
            , GlobalRoute.redirectTo (Route.Decks Route.List) model.navKey
            )

        Save code patch ->
            case model.auth of
                Just auth ->
                    let
                        updateDeck edit =
                            { edit | changes = [] }
                    in
                    ( { model | edit = model.edit |> Maybe.map updateDeck }
                    , Api.save auth.token code patch (DeckSaved code >> Global.DecksMsg)
                    )

                Nothing ->
                    ( model, GlobalRoute.redirectTo (Route.Login Nothing) model.navKey )

        DeckSaved code deck ->
            let
                replace d =
                    if d.code == code then
                        { code = code, summary = Deck.summaryOf deck }

                    else
                        d

                updateDeck edit =
                    { edit | deck = deck.deck }
            in
            ( { model
                | edit = model.edit |> Maybe.map updateDeck
                , decks = model.decks |> Maybe.map (List.map replace)
              }
            , Cmd.none
            )

        ViewDeck code maybeDeck ->
            case maybeDeck of
                Just d ->
                    let
                        route =
                            Route.Decks (Route.View code)

                        changeRouteIfNeeded =
                            if model.route == route then
                                Cmd.none

                            else
                                route |> GlobalRoute.toUrl |> Navigation.pushUrl model.navKey
                    in
                    ( { model | edit = d |> Edit.init |> Just }, changeRouteIfNeeded )

                Nothing ->
                    ( model, GlobalRoute.redirectTo (Route.Decks (Route.View code)) model.navKey )


view : Route -> Model -> List (Html Global.Msg)
view route model =
    case route of
        Route.List ->
            List.view model

        Route.Edit code ->
            case model.edit of
                Just edit ->
                    Edit.view code edit

                Nothing ->
                    [ Html.div [] [ Icon.spinner |> Icon.viewStyled [ Icon.spin ] ] ]

        Route.View code ->
            case model.edit of
                Just edit ->
                    View.view code model.auth edit

                Nothing ->
                    [ Html.div [] [ Icon.spinner |> Icon.viewStyled [ Icon.spin ] ] ]
