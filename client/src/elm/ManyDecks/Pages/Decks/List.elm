module ManyDecks.Pages.Decks.List exposing (..)

import Cards.Deck as Deck
import FontAwesome.Attributes as Icon
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Html.Keyed as HtmlK
import ManyDecks.Messages as Global
import ManyDecks.Model exposing (Model)
import ManyDecks.Pages.Decks.Deck as Deck
import ManyDecks.Pages.Decks.Messages exposing (Msg(..))
import ManyDecks.Pages.Decks.Model exposing (CodeAndSummary)
import Material.Button as Button
import Material.Card as Card
import Material.IconButton as IconButton


view : Model -> List (Html Global.Msg)
view { decks } =
    let
        renderedDecks =
            case decks of
                Just d ->
                    d |> List.map deck |> HtmlK.ul []

                Nothing ->
                    Icon.spinner |> Icon.viewStyled [ Icon.spin ]

        newDeck =
            Button.view Button.Raised
                Button.Padded
                "New Deck"
                (Icon.plus |> Icon.viewIcon |> Just)
                (Deck.empty |> NewDeck |> Global.DecksMsg |> Just)

        uploadDeck =
            Button.view Button.Raised
                Button.Padded
                "Upload Deck"
                (Icon.upload |> Icon.viewIcon |> Just)
                (UploadDeck |> Global.DecksMsg |> Just)

        controls =
            Html.div [ HtmlA.class "controls" ] [ uploadDeck, newDeck ]
    in
    [ Card.view [ HtmlA.class "decks" ] [ renderedDecks, controls ] ]


deck : CodeAndSummary -> ( String, Html Global.Msg )
deck { code, summary } =
    ( code |> Deck.codeToString
    , Html.li [ HtmlA.class "deck" ]
        [ Deck.viewCode Global.Copy code
        , Html.div [ HtmlA.class "details", ViewDeck code Nothing |> Global.DecksMsg |> HtmlE.onClick ]
            [ Html.span [ HtmlA.class "name", HtmlA.title summary.name ] [ Html.text summary.name ]
            , Html.span [ HtmlA.class "language" ] [ summary.language |> Maybe.withDefault "" |> Html.text ]
            ]
        , Html.div [ HtmlA.class "cards" ]
            [ Html.span [ HtmlA.class "calls", HtmlA.title "Calls" ]
                [ summary.calls |> String.fromInt |> Html.text ]
            , Html.span [ HtmlA.class "responses", HtmlA.title "Responses" ]
                [ summary.responses |> String.fromInt |> Html.text ]
            ]
        , Html.div [ HtmlA.class "actions" ]
            [ IconButton.view (Icon.pen |> Icon.viewIcon) "Edit" (EditDeck code Nothing |> Global.DecksMsg |> Just)
            ]
        ]
    )
