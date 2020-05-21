module Cards.Call.Transform exposing
    ( Transform(..)
    , decode
    , encode
    , toAttributes
    )

import Html
import Html.Attributes as HtmlA
import Json.Decode as Json
import Json.Encode


type Transform
    = None
    | UpperCase
    | Capitalize


toAttributes : Transform -> List (Html.Attribute msg)
toAttributes style =
    case style of
        None ->
            []

        UpperCase ->
            [ HtmlA.class "upper-case" ]

        Capitalize ->
            [ HtmlA.class "capitalize" ]


decode : Json.Decoder Transform
decode =
    let
        byName name =
            case name of
                "UpperCase" ->
                    Json.succeed UpperCase

                "Capitalize" ->
                    Json.succeed Capitalize

                _ ->
                    "Unknown transform: " ++ name |> Json.fail
    in
    Json.string |> Json.andThen byName


encode : Transform -> Maybe Json.Value
encode t =
    let
        name =
            case t of
                None ->
                    Nothing

                Capitalize ->
                    Just "Capitalize"

                UpperCase ->
                    Just "UpperCase"
    in
    name |> Maybe.map Json.Encode.string
