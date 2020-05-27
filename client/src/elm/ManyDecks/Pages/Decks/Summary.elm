module ManyDecks.Pages.Decks.Summary exposing (view)

import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import ManyDecks.Auth exposing (Auth)
import ManyDecks.Deck as Deck
import ManyDecks.Messages as Global
import ManyDecks.Model as Route
import ManyDecks.Pages.Decks.Messages exposing (Msg(..))
import ManyDecks.Pages.Decks.Model as Decks
import ManyDecks.Pages.Decks.Route as Decks
import ManyDecks.Route as Route
import Material.IconButton as IconButton


view : Maybe Auth -> Decks.CodeAndSummary -> Html Global.Msg
view auth { code, summary } =
    let
        isOwner =
            (auth |> Maybe.map .id) == Just summary.author.id

        ownerActions =
            if isOwner then
                Html.div [ HtmlA.class "actions" ]
                    [ IconButton.view (Icon.pen |> Icon.viewIcon) "Edit" (EditDeck code Nothing |> Global.DecksMsg |> Just)
                    ]
                    |> Just

            else
                Nothing

        authorLink author =
            Html.a [ author.id |> Decks.List |> Route.Decks |> Route.toUrl |> HtmlA.href ] [ Html.text author.name ]

        description =
            [ Html.span [ HtmlA.class "author" ] [ Html.text "by ", authorLink summary.author ] |> Just
            , summary.language |> Maybe.map (\l -> Html.span [ HtmlA.class "language" ] [ Html.text "in ", Html.text l ])
            ]

        nameLink =
            Html.a [ code |> Decks.View |> Route.Decks |> Route.toUrl |> HtmlA.href ] [ Html.text summary.name ]
    in
    Html.li [ HtmlA.class "deck" ]
        [ Deck.viewCode Global.Copy code
        , Html.div [ HtmlA.class "details" ]
            [ Html.span [ HtmlA.class "name", HtmlA.title summary.name ] [ nameLink ]
            , Html.span [ HtmlA.class "description" ] (description |> List.filterMap identity)
            ]
        , Html.div [ HtmlA.class "cards" ]
            [ Html.span [ HtmlA.class "calls", HtmlA.title "Calls" ]
                [ summary.calls |> String.fromInt |> Html.text ]
            , Html.span [ HtmlA.class "responses", HtmlA.title "Responses" ]
                [ summary.responses |> String.fromInt |> Html.text ]
            ]
        , ownerActions |> Maybe.withDefault (Html.text "")
        ]
