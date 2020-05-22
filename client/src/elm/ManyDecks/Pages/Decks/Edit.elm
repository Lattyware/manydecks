module ManyDecks.Pages.Decks.Edit exposing
    ( init
    , subscriptions
    , update
    , view
    )

import Cards.Call as Call exposing (Call(..))
import Cards.Card as GameCard
import Cards.Deck exposing (Deck)
import Cards.Response as Response exposing (Response(..))
import FontAwesome.Icon as Icon
import FontAwesome.Regular as RegularIcon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import List.Extra as List
import ManyDecks.Messages as Global
import ManyDecks.Pages.Decks.Deck as Deck
import ManyDecks.Pages.Decks.Edit.CallEditor as CallEditor
import ManyDecks.Pages.Decks.Edit.CallEditor.Model as CallEditor
import ManyDecks.Pages.Decks.Edit.Change as Change
import ManyDecks.Pages.Decks.Edit.Import as Import
import ManyDecks.Pages.Decks.Edit.Import.Model as Import
import ManyDecks.Pages.Decks.Edit.Model exposing (..)
import ManyDecks.Pages.Decks.Messages as Decks
import Material.Button as Button
import Material.Card as Card
import Material.IconButton as IconButton
import Material.Switch as Switch
import Material.TextField as TextField


init : Deck -> Model
init deck =
    { deck = deck
    , editing = Nothing
    , changes = []
    , redoStack = []
    , errors = []
    , deletionEnabled = False
    , importer = Nothing
    }


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        Edit u ->
            case u of
                UpdateName newName ->
                    let
                        editing =
                            case model.editing of
                                Just (NameEditor old _) ->
                                    NameEditor old newName |> Just

                                other ->
                                    other
                    in
                    ( { model | editing = editing }, Cmd.none )

                UpdateResponse newResponse ->
                    let
                        editing =
                            case model.editing of
                                Just (ResponseEditor index old _) ->
                                    ResponseEditor index old newResponse |> Just

                                other ->
                                    other
                    in
                    ( { model | editing = editing }, Cmd.none )

                UpdateCall callEditorMsg ->
                    let
                        ( editing, cmd ) =
                            case model.editing of
                                Just (CallEditor index old m) ->
                                    let
                                        ( e, eCmd ) =
                                            m |> CallEditor.update callEditorMsg
                                    in
                                    ( e |> CallEditor index old |> Just, eCmd )

                                other ->
                                    ( other, Cmd.none )
                    in
                    ( { model | editing = editing }, cmd )

        StartEditing cardEditor ->
            let
                m =
                    endEditing model
            in
            ( { m | editing = Just cardEditor }, Cmd.none )

        EndEditing ->
            ( endEditing model, Cmd.none )

        Delete ->
            case model.editing of
                Just (CallEditor index old _) ->
                    ( model |> applyChanges [ Remove index old |> CallChange ], Cmd.none )

                Just (ResponseEditor index old _) ->
                    ( model |> applyChanges [ Remove index old |> ResponseChange ], Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ApplyChange change ->
            ( model |> applyChanges [ change ], Cmd.none )

        Undo ->
            case model.changes |> List.unconsLast of
                Just ( last, rest ) ->
                    case model.deck |> Change.undo [ last ] of
                        Ok deck ->
                            ( { model | changes = rest, deck = deck, redoStack = last :: model.redoStack }, Cmd.none )

                        Err error ->
                            ( addChangeError [ last ] error True model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        Redo ->
            case model.redoStack of
                first :: rest ->
                    case model.deck |> Change.apply [ first ] of
                        Ok deck ->
                            ( { model | changes = model.changes ++ [ first ], deck = deck, redoStack = rest }, Cmd.none )

                        Err error ->
                            ( addChangeError [ first ] error False model, Cmd.none )

                [] ->
                    ( model, Cmd.none )

        SetDeletionEnabled enabled ->
            ( { model | deletionEnabled = enabled }, Cmd.none )

        SetImportVisible visible ->
            let
                importer =
                    if visible then
                        Just Import.init

                    else
                        Nothing
            in
            ( { model | importer = importer }, Cmd.none )

        Import ->
            case model.importer of
                Just importer ->
                    let
                        cards =
                            importer |> Import.importedCards

                        toChangeAndApply card m =
                            let
                                change =
                                    case card of
                                        Import.ImportedCall c ->
                                            Add (m.deck.calls |> List.length) c |> CallChange

                                        Import.ImportedResponse r ->
                                            Add (m.deck.responses |> List.length) r |> ResponseChange
                            in
                            applyChanges [ change ] m

                        newModel =
                            cards |> List.foldl toChangeAndApply model
                    in
                    ( { newModel | importer = Nothing }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        UpdateImportText text ->
            case model.importer of
                Just importer ->
                    ( { model | importer = Just { importer | text = text } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )


wrap : Msg -> Global.Msg
wrap =
    Global.EditMsg


view : Deck.Code -> Model -> List (Html Global.Msg)
view code model =
    case model.importer of
        Just importer ->
            Import.view wrap importer

        Nothing ->
            let
                viewResponse r =
                    [ Response.view (UpdateResponse >> Edit >> wrap |> GameCard.Mutable) GameCard.Face r ]

                editing editor =
                    case editor of
                        CallEditor _ _ editorModel ->
                            inEditing [ CallEditor.view (UpdateCall >> Edit >> wrap) editorModel ] (Just editorModel) |> Just

                        ResponseEditor _ _ new ->
                            inEditing (viewResponse new) Nothing |> Just

                        NameEditor _ _ ->
                            Nothing

                inEditing c callEditor =
                    let
                        d =
                            IconButton.view (Icon.trash |> Icon.viewIcon) "Delete" (Delete |> wrap |> Just)

                        problems =
                            case callEditor of
                                Just editorModel ->
                                    CallEditor.problems editorModel

                                _ ->
                                    []

                        noProblems =
                            List.isEmpty problems

                        sAction =
                            if noProblems then
                                EndEditing |> wrap |> Just

                            else
                                Nothing

                        s =
                            IconButton.view (Icon.save |> Icon.viewIcon) "Save" sAction
                    in
                    [ Html.div [ HtmlA.class "overlay" ]
                        [ Html.div [ HtmlA.class "background", EndEditing |> wrap |> HtmlE.onClick ] []
                        , Card.view []
                            [ Html.div [ HtmlA.class "editing" ] c
                            , Html.div [ HtmlA.class "editing-controls" ] [ d, s ]
                            ]
                        ]
                    ]

                undoAction =
                    if List.isEmpty model.changes then
                        Nothing

                    else
                        Undo |> wrap |> Just

                redoAction =
                    if List.isEmpty model.redoStack then
                        Nothing

                    else
                        Redo |> wrap |> Just

                saveAction =
                    if List.isEmpty model.changes then
                        Nothing

                    else
                        Decks.Save code (model.changes |> Change.toPatch) |> Global.DecksMsg |> Just

                actions =
                    Html.div [ HtmlA.class "actions" ]
                        [ Button.view
                            Button.Standard
                            Button.Padded
                            "Back"
                            (Icon.arrowLeft |> Icon.viewIcon |> Just)
                            (Decks.BackFromEdit |> Global.DecksMsg |> Just)
                        , Button.view
                            Button.Standard
                            Button.Padded
                            "Import"
                            (Icon.fileImport |> Icon.viewIcon |> Just)
                            (True |> SetImportVisible |> wrap |> Just)
                        , Button.view
                            Button.Standard
                            Button.Padded
                            "Undo"
                            (Icon.undo |> Icon.viewIcon |> Just)
                            undoAction
                        , Button.view
                            Button.Standard
                            Button.Padded
                            "Redo"
                            (Icon.redo |> Icon.viewIcon |> Just)
                            redoAction
                        , Button.view
                            Button.Standard
                            Button.Padded
                            "Save"
                            (Icon.save |> Icon.viewIcon |> Just)
                            saveAction
                        ]

                errorView =
                    if model.errors |> List.isEmpty then
                        []

                    else
                        [ Html.div [ HtmlA.class "overlay" ]
                            [ Html.div [ HtmlA.class "background" ] []
                            , Card.view [ HtmlA.class "errors" ]
                                [ Html.ul [] (model.errors |> List.map (viewError model.deck)) ]
                            ]
                        ]

                deleteAction =
                    if model.deletionEnabled then
                        code |> Decks.Delete |> Global.DecksMsg |> Just

                    else
                        Nothing
            in
            List.concat
                [ [ Card.view [ HtmlA.class "edit" ]
                        [ actions
                        , details (model |> editingName |> Maybe.withDefault model.deck.name)
                        , Html.div [ HtmlA.class "cards" ]
                            [ calls model.deck.calls
                            , responses model.deck.responses
                            ]
                        , Html.div [ HtmlA.class "delete" ]
                            [ Switch.view
                                (Html.span []
                                    [ Html.text "I am sure I want to "
                                    , Html.strong [] [ Html.text "permanently" ]
                                    , Html.text " delete this deck."
                                    ]
                                )
                                model.deletionEnabled
                                (SetDeletionEnabled >> wrap |> Just)
                            , Button.view
                                Button.Raised
                                Button.Padded
                                "Delete"
                                (Icon.trash |> Icon.viewIcon |> Just)
                                deleteAction
                            ]
                        ]
                  ]
                , model.editing |> Maybe.andThen editing |> Maybe.withDefault []
                , errorView
                ]


subscriptions : Model -> Sub Global.Msg
subscriptions model =
    case model.editing of
        Just (CallEditor _ _ _) ->
            CallEditor.subscriptions (UpdateCall >> Edit >> wrap)

        _ ->
            Sub.none


viewError : Deck -> EditError -> Html Global.Msg
viewError deck error =
    let
        content =
            case error of
                ChangeError e changes undoing ->
                    [ Change.asContextForError e changes undoing ]
    in
    Html.li [ HtmlA.class "error" ] content


editingName : Model -> Maybe String
editingName model =
    case model.editing of
        Just (NameEditor _ new) ->
            Just new

        _ ->
            Nothing


details : String -> Html Global.Msg
details name =
    Html.div [ HtmlA.class "details" ]
        [ TextField.viewWithFocus "Title"
            TextField.Text
            name
            (UpdateName >> Edit >> wrap |> Just)
            (NameEditor name name |> StartEditing |> wrap)
            (EndEditing |> wrap)
        ]


calls : List Call -> Html Global.Msg
calls cs =
    let
        add =
            Button.view
                Button.Standard
                Button.Padded
                "New Call"
                (Icon.square |> Icon.viewIcon |> Just)
                (Add (cs |> List.length) Call.init |> CallChange |> ApplyChange |> wrap |> Just)

        content =
            (cs |> List.indexedMap call) ++ [ Html.li [ HtmlA.class "add" ] [ add ] ]
    in
    Html.ul [ HtmlA.class "calls" ] content


call : Int -> Call -> Html Global.Msg
call index c =
    Html.li [ CallEditor index c (Call.editor c) |> StartEditing |> wrap |> HtmlE.onClick ]
        [ c |> Call.toString "⏎" [] |> Html.text ]


responses : List Response -> Html Global.Msg
responses rs =
    let
        add =
            Button.view
                Button.Standard
                Button.Padded
                "New Response"
                (RegularIcon.square |> Icon.viewIcon |> Just)
                (Add (rs |> List.length) Response.init |> ResponseChange |> ApplyChange |> wrap |> Just)

        content =
            (rs |> List.indexedMap response) ++ [ Html.li [ HtmlA.class "add" ] [ add ] ]
    in
    Html.ul [ HtmlA.class "responses" ] content


response : Int -> Response -> Html Global.Msg
response index r =
    Html.li [ ResponseEditor index r r |> StartEditing |> wrap |> HtmlE.onClick ]
        [ r |> Response.toString |> Html.text ]


endEditing : Model -> Model
endEditing model =
    case model.editing of
        Just finished ->
            let
                changes =
                    finished |> Change.fromEditor
            in
            case changes of
                Ok cs ->
                    applyChanges cs model

                Err _ ->
                    model

        Nothing ->
            model


applyChanges : List Change -> Model -> Model
applyChanges changes model =
    case model.deck |> Change.apply changes of
        Ok deck ->
            { model | changes = model.changes ++ changes, deck = deck, editing = Nothing, redoStack = [] }

        Err error ->
            addChangeError changes error False model


addChangeError : List Change -> String -> Bool -> Model -> Model
addChangeError changes error undo model =
    { model | errors = ChangeError error changes undo :: model.errors }
