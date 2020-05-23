module Cards.Call exposing
    ( Call(..)
    , Line
    , decode
    , encode
    , fromStrings
    , init
    , slotCount
    , toString
    , type_
    , view
    , viewInstructions
    )

import Cards.Call.Part as Part
import Cards.Call.Part.Model as Part exposing (Part)
import Cards.Call.Style as Style
import Cards.Call.Transform as Transform
import Cards.Card as Card
import Cards.Response exposing (Response)
import Cards.Type as Type exposing (Type)
import Html exposing (Html)
import Html.Attributes as HtmlA
import Json.Decode as Json
import Json.Encode


type Call
    = Call (List Line)


type alias Line =
    List Part


type_ : Type Call
type_ =
    Type.Call


init : Call
init =
    Call [ [ Part.Slot Transform.None Style.None ] ]


view : List Response -> Card.Side -> Card.Source -> List (Html msg) -> Call -> Html msg
view fill side source instructions (Call lines) =
    let
        folder part ( f, soFar ) =
            let
                ( rendered, rest ) =
                    Part.view f part
            in
            ( rest, rendered :: soFar )

        lineFolder line ( f, soFar ) =
            let
                ( rest, lineContent ) =
                    line |> List.foldr folder ( f, [] )
            in
            ( rest, Html.p [] lineContent :: soFar )

        ( _, content ) =
            lines |> List.foldr lineFolder ( fill, [] )
    in
    Card.view type_ Card.Immutable source content (viewInstructions instructions) side


toString : String -> List Response -> Call -> String
toString lineBreak _ (Call lines) =
    let
        toBasic part =
            case part of
                Part.Slot _ _ ->
                    "_"

                Part.Text text _ ->
                    text
    in
    lines |> List.map (List.map toBasic) |> List.intersperse [ lineBreak ] |> List.concat |> String.concat


fromStrings : List String -> Call
fromStrings strings =
    strings
        |> List.map (\t -> Part.Text t Style.None)
        |> List.intersperse (Part.Slot Transform.None Style.None)
        |> (\p -> Call [ p ])


decode : Json.Decoder Call
decode =
    let
        line =
            Json.list Part.decode
    in
    Json.list line |> Json.map Call


encode : Call -> Json.Value
encode (Call call) =
    let
        line =
            Json.Encode.list Part.encode
    in
    call |> Json.Encode.list line


viewInstructions : List (Html msg) -> List (Html msg)
viewInstructions items =
    let
        listItem content =
            Html.li [] [ content ]

        instructionViews =
            items |> List.map listItem
    in
    if List.length instructionViews > 0 then
        [ Html.ol [ HtmlA.class "instructions" ] instructionViews ]

    else
        []


slotCount : Call -> Int
slotCount (Call lines) =
    let
        partSlotCount part =
            case part of
                Part.Slot _ _ ->
                    1

                _ ->
                    0
    in
    lines |> List.concat |> List.map partSlotCount |> List.sum
