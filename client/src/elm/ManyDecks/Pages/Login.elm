module ManyDecks.Pages.Login exposing (..)

import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html
import Html.Attributes as HtmlA
import ManyDecks.Messages exposing (Msg(..))
import Material.Button as Button
import Material.Card as Card


view : Html.Html Msg
view =
    Card.view [ HtmlA.class "log-in" ]
        [ Html.h1 [] [ Icon.boxOpen |> Icon.viewIcon, Html.text "Many Decks" ]
        , Html.span [ HtmlA.class "version" ] [ Html.text "alpha" ]
        , Html.p []
            [ Html.text "Create decks for "
            , Html.a [ HtmlA.target "_blank", HtmlA.href "https://md.rereadgames.com" ] [ Html.text "Massive Decks" ]
            , Html.text "."
            ]
        , Html.p []
            [ Html.text "This is a very early version, produced quickly in response to Cardcast's demise, there will "
            , Html.text "likely be bugs. Please report any you find "
            , Html.a [ HtmlA.target "_blank", HtmlA.href "https://github.com/Lattyware/manydecks" ]
                [ Html.text "on GitHub" ]
            ]
        , Html.p []
            [ Html.text "Currently the data for this service is not backed up! Please keep local copies of your "
            , Html.text "decks as well, just in case something goes wrong."
            ]
        , Html.div [ HtmlA.id "google-sign-in" ]
            [ Button.view Button.Raised
                Button.Padded
                "Sign in with Google"
                (Html.div [ HtmlA.class "google-icon" ] [] |> Just)
                (Just TryGoogleAuth)
            ]
        ]
