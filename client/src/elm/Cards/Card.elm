module Cards.Card exposing
    ( Mutability(..)
    , Side(..)
    , Source
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


type alias Source =
    { name : String, url : Maybe String }


view : Type value -> Mutability value msg -> Source -> List (Html msg) -> List (Html msg) -> Side -> Html msg
view type_ mutability source content meta visibleSide =
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

        sourceContent =
            let
                wrap =
                    case source.url of
                        Just url ->
                            \t -> Html.a [ HtmlA.target "blank_", HtmlA.href url ] [ t ]

                        Nothing ->
                            identity
            in
            Html.span [ HtmlA.class "source" ] [ Html.span [ HtmlA.class "name" ] [ source.name |> Html.text |> wrap ] ]
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
        , viewSide Face content (sourceContent :: meta)
        ]
