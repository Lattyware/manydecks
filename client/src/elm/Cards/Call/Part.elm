module Cards.Call.Part exposing
    ( decode
    , encode
    , isSlot
    , view
    )

import Cards.Call.Part.Model exposing (Part(..))
import Cards.Call.Style as Style exposing (Style)
import Cards.Call.Transform as Transform exposing (Transform)
import Cards.Response as Response exposing (Response(..))
import Html exposing (Html)
import Html.Attributes as HtmlA
import Json.Decode as Json
import Json.Decode.Pipeline as Json
import Json.Encode


view : List Response -> Part -> ( Html msg, List Response )
view fill part =
    let
        splitWords string =
            case String.uncons string of
                Nothing ->
                    []

                Just ( first, rest ) ->
                    case first of
                        ' ' ->
                            String.fromChar first :: splitWords rest

                        other ->
                            case splitWords rest of
                                [] ->
                                    [ String.fromChar other ]

                                head :: tail ->
                                    String.cons other head :: tail

        viewText text =
            text |> splitWords |> List.map (\t -> Html.span [] [ Html.text t ])
    in
    case part of
        Text text style ->
            ( Style.toNode style [ HtmlA.class "text" ] (viewText text), fill )

        Slot transform style ->
            let
                ( emptyAttr, text, restOfFill ) =
                    case fill of
                        r :: rest ->
                            ( [], r |> Response.toString |> viewText, rest )

                        [] ->
                            ( [ HtmlA.class "empty" ], [], [] )

                attrs =
                    List.concat [ [ HtmlA.class "slot" ], emptyAttr, Transform.toAttributes transform ]
            in
            ( Style.toNode style attrs text, restOfFill )


decode : Json.Decoder Part
decode =
    let
        slot =
            Json.succeed Slot
                |> Json.optional "transform" Transform.decode Transform.None
                |> Json.optional "style" Style.decode Style.None
    in
    Json.oneOf
        [ decodeText |> Json.map (\( t, s ) -> Text t s)
        , slot
        ]


decodeText : Json.Decoder ( String, Style )
decodeText =
    let
        styled =
            Json.succeed (\t s -> ( t, s ))
                |> Json.required "text" Json.string
                |> Json.optional "style" Style.decode Style.None
    in
    Json.oneOf
        [ Json.string |> Json.map (\t -> ( t, Style.None ))
        , styled
        ]


encode : Part -> Json.Value
encode part =
    let
        maybeField field =
            case field of
                ( n, Just v ) ->
                    Just ( n, v )

                ( _, Nothing ) ->
                    Nothing

        maybeObject =
            List.filterMap maybeField >> Json.Encode.object
    in
    case part of
        Text text Style.None ->
            text |> Json.Encode.string

        Text text s ->
            maybeObject [ ( "text", text |> Json.Encode.string |> Just ), ( "style", s |> Style.encode ) ]

        Slot t s ->
            maybeObject [ ( "transform", t |> Transform.encode ), ( "style", s |> Style.encode ) ]


isSlot : Part -> Bool
isSlot part =
    case part of
        Text _ _ ->
            False

        Slot _ _ ->
            True
