module ManyDecks.Pages.Decks.Edit.Change exposing
    ( apply
    , asContextForError
    , fromEditor
    , manyToPatch
    , toPatch
    )

import Cards.Call as Call
import Cards.Response as Response
import Html exposing (Html)
import Html.Attributes as HtmlA
import Json.Decode
import Json.Encode as Json
import Json.Patch
import Json.Patch.Invertible as Json
import Json.Pointer as Json
import ManyDecks.Deck as Deck exposing (Deck)
import ManyDecks.Pages.Decks.Edit.CallEditor as CallEditor
import ManyDecks.Pages.Decks.Edit.Model exposing (..)


apply : List Change -> Direction -> Deck -> Result String Deck
apply changes direction deck =
    applyPatchToDeck (changes |> toPatch direction) deck


manyToPatch : List ( Change, Direction ) -> Json.Patch
manyToPatch changes =
    let
        single ( c, d ) =
            toPatch d [ c ]
    in
    changes |> List.map single |> List.concat


toPatch : Direction -> List Change -> Json.Patch
toPatch direction changes =
    let
        directionOp =
            case direction of
                Perform ->
                    identity

                Revert ->
                    Json.invert
    in
    changes |> List.map toOperation |> directionOp


asContextForError : String -> Change -> Direction -> Html msg
asContextForError error change direction =
    Html.div [ HtmlA.class "error-with-context" ]
        [ Html.span [ HtmlA.class "message" ] [ Html.text error ]
        , Html.span [ HtmlA.class "change" ]
            [ [ change ] |> toPatch direction |> Json.toPatch |> Json.Patch.encoder |> Json.encode 2 |> Html.text ]
        ]


fromEditor : CardEditor -> Result String (Maybe Change)
fromEditor editor =
    let
        ifChanged wrap index old new =
            if old /= new then
                Replace index old new |> wrap |> Just

            else
                Nothing
    in
    case editor of
        CallEditor index old new ->
            CallEditor.editorToCall new |> Result.map (ifChanged CallChange index old)

        ResponseEditor index old new ->
            ifChanged ResponseChange index old new |> Ok

        NameEditor old new ->
            if old /= new then
                ChangeName old new |> Just |> Ok

            else
                Nothing |> Ok


applyPatchToDeck : Json.Patch -> Deck -> Result String Deck
applyPatchToDeck patch =
    Deck.encode
        >> Json.Patch.apply (Json.toPatch patch)
        >> Result.andThen (Json.Decode.decodeValue Deck.decode >> Result.mapError Json.Decode.errorToString)


toOperation : Change -> Json.Operation
toOperation change =
    case change of
        ChangeName old newName ->
            Json.Replace [ "name" ] (old |> Json.string) (newName |> Json.string)

        ChangePublic listed ->
            if listed then
                Json.Add [ "public" ] (Json.bool True)

            else
                Json.Remove [ "public" ] (Json.bool True)

        CallChange cardChange ->
            handleCardChange [ "calls" ] Call.encode cardChange

        ResponseChange cardChange ->
            handleCardChange [ "responses" ] Response.encode cardChange


handleCardChange : Json.Pointer -> (value -> Json.Value) -> CardChange value -> Json.Operation
handleCardChange basePath encodeValue cardChange =
    case cardChange of
        Add index value ->
            Json.Add (basePath ++ [ index |> String.fromInt ]) (encodeValue value)

        Replace index old value ->
            Json.Replace (basePath ++ [ index |> String.fromInt ]) (encodeValue old) (encodeValue value)

        Remove index old ->
            Json.Remove (basePath ++ [ index |> String.fromInt ]) (encodeValue old)
