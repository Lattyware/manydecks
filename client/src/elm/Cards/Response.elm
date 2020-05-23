module Cards.Response exposing
    ( Response
    , decode
    , encode
    , fromString
    , init
    , toString
    , view
    )

import Cards.Card as Card
import Cards.Type as Type exposing (Type)
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode as Json
import Json.Encode


type Response
    = Response String


type_ : Type Response
type_ =
    Type.Response


init : Response
init =
    Response ""


view : Card.Mutability Response msg -> Card.Side -> Card.Source -> Response -> Html msg
view mutability side source (Response text) =
    let
        content =
            case mutability of
                Card.Immutable ->
                    [ Html.text text ]

                Card.Mutable update attrs ->
                    [ Html.textarea
                        ([ HtmlA.value text
                         , HtmlE.onInput (fromString >> update)
                         ]
                            ++ attrs
                        )
                        []
                    ]
    in
    Card.view type_ mutability source content [] side


toString : Response -> String
toString (Response text) =
    text


fromString : String -> Response
fromString =
    String.replace "\n" "" >> Response


encode : Response -> Json.Value
encode (Response response) =
    response |> Json.Encode.string


decode : Json.Decoder Response
decode =
    Json.string |> Json.map Response
