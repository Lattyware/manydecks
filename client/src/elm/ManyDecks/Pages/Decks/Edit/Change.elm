module ManyDecks.Pages.Decks.Edit.Change exposing
    ( apply
    , asContextForError
    , fromEditor
    , toPatch
    , undo
    )

import Cards.Call as Call
import Cards.Deck as Deck exposing (Deck)
import Cards.Response as Response
import Html exposing (Html)
import Html.Attributes as HtmlA
import Json.Decode
import Json.Encode as Json
import Json.Patch
import Json.Patch.Invertible as Json
import Json.Pointer as Json
import ManyDecks.Pages.Decks.Edit.Model exposing (..)


apply : List Change -> Deck -> Result String Deck
apply changes deck =
    applyPatchToDeck (changes |> toPatch) deck


undo : List Change -> Deck -> Result String Deck
undo changes deck =
    applyPatchToDeck (changes |> toPatch |> Json.invert) deck


toPatch : List Change -> Json.Patch
toPatch changes =
    changes |> List.map toOperation


asContextForError : String -> List Change -> Bool -> Html msg
asContextForError error changes undoing =
    let
        u =
            if undoing then
                Json.invert

            else
                identity
    in
    Html.div [ HtmlA.class "error-with-context" ]
        [ Html.span [ HtmlA.class "message" ] [ Html.text error ]
        , Html.span [ HtmlA.class "change" ]
            [ changes |> toPatch |> u |> Json.toPatch |> Json.Patch.encoder |> Json.encode 2 |> Html.text ]
        ]


fromEditor : CardEditor -> Result String (List Change)
fromEditor editor =
    let
        ifChanged wrap index old new =
            if old /= new then
                [ Replace index old new |> wrap ]

            else
                []
    in
    case editor of
        CallEditor index old new ->
            Call.editorToCall new |> Result.map (ifChanged CallChange index old)

        ResponseEditor index old new ->
            ifChanged ResponseChange index old new |> Ok

        NameEditor old new ->
            if old /= new then
                [ ChangeName old new ] |> Ok

            else
                [] |> Ok


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
