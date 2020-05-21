module Cards.Card exposing
    ( Mutability(..)
    , Side(..)
    , view
    )

import Cards.Type as Type exposing (Type)
import Html exposing (Html)
import Html.Attributes as HtmlA


type Mutability value msg
    = Immutable
    | Mutable (value -> msg)


type Side
    = Face
    | Reverse


view : Type value -> Mutability value msg -> List (Html msg) -> Side -> Html msg
view type_ mutability content visibleSide =
    let
        mutabilityClass =
            case mutability of
                Immutable ->
                    "immutable"

                Mutable _ ->
                    "mutable"

        typeClass =
            case type_ of
                Type.Call ->
                    "call"

                Type.Response ->
                    "response"

        visibleSideClass =
            case visibleSide of
                Face ->
                    "face-up"

                Reverse ->
                    "face-down"

        viewSide side primary secondary =
            let
                sideClass =
                    case side of
                        Face ->
                            "face"

                        Reverse ->
                            "reverse"
            in
            Html.div [ HtmlA.classList [ ( "side", True ), ( sideClass, True ) ] ]
                [ Html.div [ HtmlA.class "primary-content" ] primary
                , Html.div [ HtmlA.class "secondary-content" ] secondary
                ]
    in
    Html.div
        [ HtmlA.classList
            [ ( "game-card", True )
            , ( typeClass, True )
            , ( visibleSideClass, True )
            , ( mutabilityClass, True )
            ]
        ]
        [ viewSide Reverse [ Html.text "Massive", Html.text "Decks" ] []
        , viewSide Face content []
        ]
