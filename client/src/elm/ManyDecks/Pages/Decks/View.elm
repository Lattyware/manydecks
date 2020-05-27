module ManyDecks.Pages.Decks.View exposing (view)

import Cards.Call as Call
import Cards.Card as Card
import Cards.Response as Response
import FontAwesome.Icon as Icon
import FontAwesome.Regular as RegIcon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import ManyDecks.Auth exposing (Auth)
import ManyDecks.Deck as Deck
import ManyDecks.Messages as Global
import ManyDecks.Meta as Meta
import ManyDecks.Model as Route
import ManyDecks.Pages.Decks.Edit.Model as Edit
import ManyDecks.Pages.Decks.Messages as Decks
import ManyDecks.Pages.Decks.Route as Decks
import ManyDecks.Route as Route
import Material.Button as Button
import Material.Card as MaterialCard


view : Deck.Code -> Maybe Auth -> Edit.Model -> List (Html Global.Msg)
view code auth model =
    let
        viewAuthor { id, name } =
            let
                link =
                    Html.a [ id |> Decks.List |> Route.Decks |> Route.toUrl |> HtmlA.href ] [ Html.text name ]
            in
            Html.span [ HtmlA.class "author" ] [ Html.text "By ", link ]

        li content =
            Html.li [] [ content ]

        deck =
            model.deck

        source =
            { name = deck.name, url = code |> Decks.View |> Route.Decks |> Route.toUrl |> Just }

        responses =
            deck.responses |> List.map (Response.view Card.Immutable Card.Face source >> li)

        call c =
            Call.view [] Card.Face source (c |> Call.slotCount |> Deck.defaultInstructions) c |> li

        calls =
            deck.calls |> List.map call

        editButton =
            Button.view Button.Raised
                Button.Padded
                "Edit"
                (Icon.pen |> Icon.viewIcon |> Just)
                (Decks.EditDeck code (Just model.deck) |> Global.DecksMsg |> Just)

        ownerActions a =
            if a.id == model.deck.author.id then
                Html.div [ HtmlA.class "owner-actions" ] [ Html.div [] [], editButton ] |> Just

            else
                Nothing
    in
    [ MaterialCard.view [ HtmlA.class "page view" ]
        [ Html.div [ HtmlA.class "header" ]
            [ auth |> Maybe.andThen ownerActions |> Maybe.withDefault (Html.text "")
            , Html.h1 [ HtmlA.class "title" ] [ code |> Deck.viewCode Global.Copy, deck.name |> Html.text ]
            , Html.div [ HtmlA.class "details" ]
                [ deck.author |> viewAuthor
                , Html.span [ HtmlA.class "counts" ]
                    [ Html.span [ HtmlA.class "responses" ]
                        [ Html.a [ HtmlA.href "#responses" ]
                            [ RegIcon.square |> Icon.viewIcon
                            , Html.text "×"
                            , deck.responses |> List.length |> String.fromInt |> Html.text
                            ]
                        ]
                    , Html.span [ HtmlA.class "calls" ]
                        [ Html.a [ HtmlA.href "#calls" ]
                            [ Icon.square |> Icon.viewIcon
                            , Html.text "×"
                            , deck.calls |> List.length |> String.fromInt |> Html.text
                            ]
                        ]
                    ]
                ]
            ]
        , Html.p [ HtmlA.class "massive-decks-ad" ]
            [ Html.text "You can play with this deck on "
            , Html.a [ Meta.massiveDecksUrl |> HtmlA.href, HtmlA.target "_blank" ] [ Html.text "Massive Decks" ]
            , Html.text ", just use the deck code "
            , code |> Deck.viewCodeMulti Global.Copy "-2"
            , Html.text " after selecting "
            , Icon.boxOpen |> Icon.viewIcon
            , Html.text " Many Decks, or you can try "
            , Html.a [ HtmlA.href "/" ] [ Html.text "making your own decks here" ]
            , Html.text "."
            ]
        , Html.div [ HtmlA.class "cards" ]
            [ Html.ul [ HtmlA.id "responses" ] responses
            , Html.ul [ HtmlA.id "calls" ] calls
            ]
        ]
    ]
