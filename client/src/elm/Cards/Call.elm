module Cards.Call exposing
    ( Call
    , Line
    , decode
    , editor
    , editorToCall
    , encode
    , fromStrings
    , init
    , toString
    , type_
    , view
    )

import Cards.Call.Part as Part
import Cards.Call.Part.Model as Part exposing (Part)
import Cards.Call.Style as Style
import Cards.Call.Transform as Transform
import Cards.Card as Card
import Cards.Response exposing (Response)
import Cards.Type as Type exposing (Type)
import Html exposing (Html)
import Json.Decode as Json
import Json.Encode
import List.Extra as List
import ManyDecks.Pages.Decks.Edit.CallEditor.Model as Editor exposing (Atom(..))


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


view : List Response -> Card.Side -> Call -> Html msg
view fill side (Call lines) =
    let
        folder row part ( f, column, soFar ) =
            let
                ( rendered, rest ) =
                    Part.view f part
            in
            ( rest, column + 1, rendered :: soFar )

        lineFolder line ( f, row, soFar ) =
            let
                ( rest, _, lineContent ) =
                    line |> List.foldr (folder row) ( f, 0, [] )
            in
            ( rest, row + 1, Html.p [] lineContent :: soFar )

        ( _, _, content ) =
            lines |> List.foldr lineFolder ( fill, 0, [] )
    in
    Card.view type_ Card.Immutable content side


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


editor : Call -> Editor.Model
editor (Call lines) =
    { atoms = lines |> List.map (List.concatMap partToAtoms) |> List.intersperse [ NewLine ] |> List.concat
    , selection = { start = 0, end = 0 }
    , selecting = Nothing
    , moving = Nothing
    , control = False
    }


partToAtoms : Part -> List Editor.Atom
partToAtoms part =
    case part of
        Part.Text text style ->
            text |> String.toList |> List.map (\c -> Editor.Letter c style)

        Part.Slot transform style ->
            [ Editor.Slot transform style ]


editorToCall : Editor.Model -> Result String Call
editorToCall { atoms } =
    let
        parts =
            atoms |> List.groupWhile (\a b -> b /= NewLine) |> List.map atomsToParts
    in
    if parts |> List.any (List.any Part.isSlot) then
        parts |> Call |> Ok

    else
        "Calls must contain at least one slot." |> Err


atomsToParts : ( Editor.Atom, List Editor.Atom ) -> List Part
atomsToParts ( f, r ) =
    let
        atoms =
            f :: r

        group a b =
            case a of
                Letter _ styleA ->
                    case b of
                        Letter _ styleB ->
                            styleA == styleB

                        _ ->
                            False

                _ ->
                    False

        toChar atom =
            case atom of
                Letter char _ ->
                    Just char

                _ ->
                    Nothing

        toPart ( first, rest ) =
            case first of
                Letter _ style ->
                    (first :: rest)
                        |> List.filterMap toChar
                        |> String.fromList
                        |> (\t -> Part.Text t style |> Just)

                Slot transform style ->
                    Part.Slot transform style |> Just

                _ ->
                    Nothing
    in
    atoms |> List.groupWhile group |> List.filterMap toPart
