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
import ManyDecks.Messages as Global
import ManyDecks.Meta as Meta
import ManyDecks.Model as Route
import ManyDecks.Pages.Decks.Deck as Deck
import ManyDecks.Pages.Decks.Edit.Model as Edit
import ManyDecks.Pages.Decks.Messages as Decks
import ManyDecks.Pages.Decks.Route as Decks
import ManyDecks.Route as Route
import Material.Button as Button
import Material.Card as MaterialCard


view : Deck.Code -> Maybe Auth -> Edit.Model -> List (Html Global.Msg)
view code auth model =
    let
        viewAuthor author =
            Html.span [ HtmlA.class "author" ] [ Html.text "By ", Html.text author ]

        li content =
            Html.li [] [ content ]

        source =
            { name = model.deck.name, url = code |> Decks.View |> Route.Decks |> Route.toUrl |> Just }

        responses =
            model.deck.responses |> List.map (Response.view Card.Immutable Card.Face source >> li)

        call c =
            Call.view [] Card.Face source (c |> Call.slotCount |> Deck.defaultInstructions) c |> li

        calls =
            model.deck.calls |> List.map call

        editButton =
            Button.view Button.Raised
                Button.Padded
                "Edit"
                (Icon.pen |> Icon.viewIcon |> Just)
                (Decks.EditDeck code (Just model.deck) |> Global.DecksMsg |> Just)

        ownerActions _ =
            Html.div [ HtmlA.class "owner-actions" ] [ Html.div [] [], editButton ]
    in
    [ MaterialCard.view [ HtmlA.class "page view" ]
        [ Html.div [ HtmlA.class "header" ]
            [ auth |> Maybe.map ownerActions |> Maybe.withDefault (Html.text "")
            , Html.h1 [ HtmlA.class "title" ] [ code |> Deck.viewCode Global.Copy, model.deck.name |> Html.text ]
            , Html.div [ HtmlA.class "details" ]
                [ model.deck.author |> Maybe.map viewAuthor |> Maybe.withDefault (Html.text "")
                , Html.span [ HtmlA.class "counts" ]
                    [ Html.span [ HtmlA.class "responses" ]
                        [ Html.a [ HtmlA.href "#responses" ]
                            [ RegIcon.square |> Icon.viewIcon
                            , Html.text "×"
                            , model.deck.responses |> List.length |> String.fromInt |> Html.text
                            ]
                        ]
                    , Html.span [ HtmlA.class "calls" ]
                        [ Html.a [ HtmlA.href "#calls" ]
                            [ Icon.square |> Icon.viewIcon
                            , Html.text "×"
                            , model.deck.calls |> List.length |> String.fromInt |> Html.text
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
