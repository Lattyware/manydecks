module Cards.Call.Style exposing
    ( Style(..)
    , decode
    , encode
    , toNode
    )

import Html exposing (Html)
import Json.Decode as Json
import Json.Encode


type Style
    = None
    | Em


toNode : Style -> (List (Html.Attribute msg) -> List (Html msg) -> Html msg)
toNode style =
    case style of
        None ->
            Html.span

        Em ->
            Html.em


decode : Json.Decoder Style
decode =
    let
        byName name =
            case name of
                "Em" ->
                    Json.succeed Em

                _ ->
                    "Unknown style: " ++ name |> Json.fail
    in
    Json.string |> Json.andThen byName


encode : Style -> Maybe Json.Value
encode s =
    let
        name =
            case s of
                None ->
                    Nothing

                Em ->
                    Just "Em"
    in
    name |> Maybe.map Json.Encode.string
