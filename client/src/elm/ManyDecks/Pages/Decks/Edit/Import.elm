module ManyDecks.Pages.Decks.Edit.Import exposing
    ( importedCards
    , init
    , view
    )

import Cards.Call as Call exposing (Call)
import Cards.Response as Response exposing (Response)
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import ManyDecks.Pages.Decks.Edit.Import.Model exposing (..)
import ManyDecks.Pages.Decks.Edit.Model exposing (Msg(..))
import Material.Button as Button
import Material.Card as Card


init : Model
init =
    { text = "" }


view : (Msg -> msg) -> Model -> List (Html msg)
view wrap model =
    let
        importAction =
            if String.isEmpty model.text then
                Nothing

            else
                Import |> wrap |> Just
    in
    [ Card.view [ HtmlA.class "import" ]
        [ Html.p []
            [ Html.text "Each line will be a different card. Single underscores (“_”) represent slots. If a card "
            , Html.text "has a slot it will be a call, otherwise a response."
            ]
        , Html.textarea [ HtmlA.value model.text, HtmlE.onInput (UpdateImportText >> wrap) ] []
        , Html.div [ HtmlA.class "actions" ]
            [ Button.view Button.Standard
                Button.Padded
                "Cancel"
                (Icon.arrowLeft |> Icon.viewIcon |> Just)
                (False |> SetImportVisible |> wrap |> Just)
            , Button.view Button.Standard
                Button.Padded
                "Import"
                (Icon.fileImport |> Icon.viewIcon |> Just)
                importAction
            ]
        ]
    ]


importedCards : Model -> List ImportedCard
importedCards model =
    let
        lineToChange line =
            case String.split "_" line of
                first :: [] ->
                    Response.fromString first |> ImportedResponse

                other ->
                    Call.fromStrings other |> ImportedCall
    in
    model.text |> String.lines |> List.map lineToChange
