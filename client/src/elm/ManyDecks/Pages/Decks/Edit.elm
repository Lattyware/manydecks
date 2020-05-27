module ManyDecks.Pages.Decks.Edit exposing
    ( init
    , subscriptions
    , update
    , view
    )

import Cards.Call as Call exposing (Call(..))
import Cards.Card as GameCard
import Cards.Response as Response exposing (Response(..))
import FontAwesome.Attributes as Icon
import FontAwesome.Icon as Icon
import FontAwesome.Regular as RegularIcon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode as Json
import ManyDecks.Deck as Deck exposing (Deck)
import ManyDecks.Messages as Global
import ManyDecks.Pages.Decks.Edit.CallEditor as CallEditor
import ManyDecks.Pages.Decks.Edit.Change as Change
import ManyDecks.Pages.Decks.Edit.Import as Import
import ManyDecks.Pages.Decks.Edit.Import.Model as Import
import ManyDecks.Pages.Decks.Edit.Model exposing (..)
import ManyDecks.Pages.Decks.Messages as Decks
import ManyDecks.Ports as Ports
import Material.Button as Button
import Material.Card as Card
import Material.IconButton as IconButton
import Material.Switch as Switch
import Material.TextField as TextField
import Time


init : Deck -> Model
init deck =
    { deck = deck
    , editing = Nothing
    , changes = []
    , undoStack = []
    , redoStack = []
    , errors = []
    , deletionEnabled = False
    , importer = Nothing
    , saving = False
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

                focus =
                    case cardEditor of
                        NameEditor _ _ ->
                            Cmd.none

                        CallEditor _ _ _ ->
                            "call-input-ghost" |> Ports.focus

                        ResponseEditor _ _ _ ->
                            "response-input" |> Ports.focus
            in
            ( { m | editing = Just cardEditor }, focus )

        EndEditing ->
            ( endEditing model, Cmd.none )

        Delete ->
            case model.editing of
                Just (CallEditor index old _) ->
                    ( model |> applyChange (Remove index old |> CallChange), Cmd.none )

                Just (ResponseEditor index old _) ->
                    ( model |> applyChange (Remove index old |> ResponseChange), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ApplyChange change ->
            ( model |> applyChange change, Cmd.none )

        Undo ->
            case model.undoStack of
                first :: rest ->
                    case model.deck |> Change.apply [ first ] Revert of
                        Ok deck ->
                            ( { model
                                | changes = model.changes ++ [ ( first, Revert ) ]
                                , undoStack = rest
                                , deck = deck
                                , redoStack = first :: model.redoStack
                              }
                            , Cmd.none
                            )

                        Err error ->
                            ( addChangeError first error Revert model, Cmd.none )

                [] ->
                    ( model, Cmd.none )

        Redo ->
            case model.redoStack of
                first :: rest ->
                    case model.deck |> Change.apply [ first ] Perform of
                        Ok deck ->
                            ( { model
                                | changes = model.changes ++ [ ( first, Perform ) ]
                                , undoStack = first :: model.undoStack
                                , deck = deck
                                , redoStack = rest
                              }
                            , Cmd.none
                            )

                        Err error ->
                            ( addChangeError first error Perform model, Cmd.none )

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
                                deck =
                                    m.deck

                                change =
                                    case card of
                                        Import.ImportedCall c ->
                                            Add (deck.calls |> List.length) c |> CallChange

                                        Import.ImportedResponse r ->
                                            Add (deck.responses |> List.length) r |> ResponseChange
                            in
                            applyChange change m

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

        ClearErrors ->
            ( { model | errors = [] }, Cmd.none )


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
                deck =
                    model.deck

                source =
                    { name = deck.name, url = Nothing }

                onKeyPress k =
                    if k == 13 then
                        EndEditing |> wrap

                    else
                        Global.NoOp

                viewResponse r =
                    let
                        mutable msg =
                            GameCard.Mutable msg
                                [ HtmlA.id "response-input"
                                , HtmlA.placeholder "type a response here"
                                , HtmlE.keyCode |> Json.map onKeyPress |> HtmlE.on "keydown"
                                ]
                    in
                    [ Response.view (UpdateResponse >> Edit >> wrap |> mutable) GameCard.Face source r ]

                editing editor =
                    case editor of
                        CallEditor _ _ editorModel ->
                            inEditing [ CallEditor.view (UpdateCall >> Edit >> wrap) source editorModel ]
                                (Just editorModel)
                                |> Just

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
                    if List.isEmpty model.undoStack then
                        Nothing

                    else
                        Undo |> wrap |> Just

                redoAction =
                    if List.isEmpty model.redoStack then
                        Nothing

                    else
                        Redo |> wrap |> Just

                ( saveText, saveIcon, saveAction ) =
                    if model.saving then
                        ( "Saving…", Icon.spinner |> Icon.viewStyled [ Icon.spin ], Nothing )

                    else if List.isEmpty model.changes then
                        ( "Saved", Icon.check |> Icon.viewIcon, Nothing )

                    else
                        let
                            action =
                                Decks.Save code (model.changes |> Change.manyToPatch) |> Global.DecksMsg |> Just
                        in
                        ( "Save", Icon.save |> Icon.viewIcon, action )

                actions =
                    Html.div [ HtmlA.class "actions" ]
                        [ Button.view
                            Button.Standard
                            Button.Padded
                            "Import"
                            (Icon.fileImport |> Icon.viewIcon |> Just)
                            (True |> SetImportVisible |> wrap |> Just)
                        , Button.view Button.Standard
                            Button.Padded
                            "Download"
                            (Icon.fileDownload |> Icon.viewIcon |> Just)
                            (deck |> Decks.DownloadDeck |> Global.DecksMsg |> Just)
                        , Html.div [ HtmlA.class "undo-redo" ]
                            [ Button.view
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
                            ]
                        , Html.div [ HtmlA.class "save" ]
                            [ Button.view Button.Standard Button.Padded saveText (saveIcon |> Just) saveAction
                            ]
                        ]

                errorView =
                    if model.errors |> List.isEmpty then
                        []

                    else
                        [ Html.div [ HtmlA.class "overlay" ]
                            [ Html.div [ HtmlA.class "background" ] []
                            , Card.view [ HtmlA.class "errors" ]
                                [ Html.ul [] (model.errors |> List.map viewError)
                                , Button.view Button.Standard
                                    Button.Padded
                                    "Dismiss"
                                    (Icon.times |> Icon.viewIcon |> Just)
                                    (ClearErrors |> wrap |> Just)
                                ]
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
                        , details (model |> editingName |> Maybe.withDefault deck.name) model.deck.public
                        , Html.div [ HtmlA.class "cards" ]
                            [ calls deck.calls
                            , responses deck.responses
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


subscriptions : Deck.Code -> Model -> Sub Global.Msg
subscriptions code model =
    let
        editor =
            case model.editing of
                Just (CallEditor _ _ _) ->
                    CallEditor.subscriptions (UpdateCall >> Edit >> wrap)

                _ ->
                    Sub.none

        autoSave =
            if not model.saving && (model.changes |> List.isEmpty |> not) then
                (Decks.Save code (model.changes |> Change.manyToPatch) |> Global.DecksMsg |> always)
                    |> Time.every 5000

            else
                Sub.none
    in
    Sub.batch [ editor, autoSave ]


viewError : EditError -> Html Global.Msg
viewError error =
    let
        content =
            case error of
                ChangeError e c direction ->
                    [ Change.asContextForError e c direction ]
    in
    Html.li [ HtmlA.class "error" ] content


editingName : Model -> Maybe String
editingName model =
    case model.editing of
        Just (NameEditor _ new) ->
            Just new

        _ ->
            Nothing


details : String -> Bool -> Html Global.Msg
details name public =
    let
        change =
            ChangePublic >> ApplyChange >> wrap |> Just
    in
    Html.div [ HtmlA.class "details" ]
        [ TextField.viewWithFocus "Title"
            TextField.Text
            name
            (UpdateName >> Edit >> wrap |> Just)
            (NameEditor name name |> StartEditing |> wrap)
            (EndEditing |> wrap)
        , Html.p []
            [ Switch.view (Html.span [] [ Html.text "Listed: Show this deck publicly for people to find." ]) public change ]
        , Html.p []
            [ Icon.exclamationTriangle |> Icon.viewIcon
            , Html.text " Note that being unlisted doesn't mean the deck is private: people with the code can still "
            , Html.text "use it, and it is possible for people to guess the code."
            ]
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
    Html.li [ CallEditor index c (CallEditor.init c) |> StartEditing |> wrap |> HtmlE.onClick ]
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
                change =
                    finished |> Change.fromEditor
            in
            case change of
                Ok (Just c) ->
                    model |> applyChange c

                Ok Nothing ->
                    { model | editing = Nothing }

                Err _ ->
                    model

        Nothing ->
            model


applyChange : Change -> Model -> Model
applyChange change model =
    case model.deck |> Change.apply [ change ] Perform of
        Ok deck ->
            { model
                | changes = model.changes ++ [ ( change, Perform ) ]
                , undoStack = change :: model.undoStack
                , deck = deck
                , editing = Nothing
                , redoStack = []
            }

        Err error ->
            addChangeError change error Perform model


addChangeError : Change -> String -> Direction -> Model -> Model
addChangeError change error direction model =
    { model | errors = ChangeError error change direction :: model.errors }
