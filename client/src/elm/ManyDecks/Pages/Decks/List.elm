module ManyDecks.Pages.Decks.List exposing (..)

import FontAwesome.Attributes as Icon
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Keyed as HtmlK
import ManyDecks.Deck as Deck
import ManyDecks.Messages as Global
import ManyDecks.Model exposing (Model)
import ManyDecks.Pages.Decks.Messages exposing (Msg(..))
import ManyDecks.Pages.Decks.Model exposing (CodeAndSummary)
import ManyDecks.Pages.Decks.Summary as Summary
import ManyDecks.User as User
import Material.Button as Button
import Material.Card as Card


view : User.Id -> Model -> List (Html Global.Msg)
view viewing { browserLanguage, auth, decks, knownLanguages } =
    let
        deck codeAndSummary =
            ( codeAndSummary.code |> Deck.codeToString
            , Summary.view auth knownLanguages codeAndSummary
            )

        renderedDecks =
            case decks of
                Just d ->
                    d |> List.map deck |> HtmlK.ul [ HtmlA.class "deck-list" ]

                Nothing ->
                    Icon.spinner |> Icon.viewStyled [ Icon.spin ]

        newDeckAction a =
            Deck.empty browserLanguage a |> NewDeck |> Global.DecksMsg

        newDeck =
            Button.view Button.Raised
                Button.Padded
                "New Deck"
                (Icon.plus |> Icon.viewIcon |> Just)
                (auth |> Maybe.map newDeckAction)

        uploadDeck =
            Button.view Button.Raised
                Button.Padded
                "Upload Deck"
                (Icon.upload |> Icon.viewIcon |> Just)
                (UploadDeck |> Global.DecksMsg |> Just)

        controls =
            if (auth |> Maybe.map .id) == Just viewing then
                Html.div [ HtmlA.class "controls" ] [ uploadDeck, newDeck ]

            else
                Html.text ""
    in
    [ Card.view [ HtmlA.class "page decks" ] [ renderedDecks, controls ] ]
