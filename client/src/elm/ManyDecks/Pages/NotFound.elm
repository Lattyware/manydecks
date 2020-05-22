module ManyDecks.Pages.NotFound exposing (..)

import Html exposing (Html)
import Html.Attributes as HtmlA
import ManyDecks.Meta as Meta
import ManyDecks.Model exposing (Model)
import Material.Card as Card


view : String -> Model -> List (Html msg)
view requested model =
    [ Card.view [ HtmlA.class "page not-found" ]
        [ Html.h1 [] [ Html.text "Not Found" ]
        , Html.p [] [ Html.text "The page you requested (“", Html.text requested, Html.text "”) was not found." ]
        , Html.p []
            [ Html.text "If you followed a link or clicked a button inside the application, please "
            , Html.a [ Meta.issuesUrl |> HtmlA.href ] [ Html.text "report this as a bug" ]
            , Html.text "."
            ]
        ]
    ]
