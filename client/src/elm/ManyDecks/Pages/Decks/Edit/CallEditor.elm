module ManyDecks.Pages.Decks.Edit.CallEditor exposing
    ( editorToCall
    , init
    , problems
    , subscriptions
    , update
    , view
    )

import Cards.Call as Call exposing (Call(..))
import Cards.Call.Part as Part
import Cards.Call.Part.Model as Part exposing (Part)
import Cards.Call.Style as Style exposing (Style)
import Cards.Call.Transform as Transform exposing (Transform)
import Cards.Card as Card
import Diff
import FontAwesome.Icon as Icon
import FontAwesome.Layering as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode as Json
import List.Extra as List
import ManyDecks.Deck as Deck
import ManyDecks.Pages.Decks.Edit.CallEditor.Model exposing (..)
import ManyDecks.Ports as Ports
import Material.IconButton as IconButton


init : Call -> Model
init (Call parts) =
    { atoms = parts |> List.map (List.concatMap partToAtoms) |> List.intersperse [ NewLine ] |> List.concat
    , selection = { start = 0, end = 0 }
    , selecting = Nothing
    , moving = Nothing
    , control = False
    }


deleteSpan : Span -> Model -> Model
deleteSpan { start, end } model =
    let
        left =
            model.atoms |> List.take start

        right =
            model.atoms |> List.drop end
    in
    { model | atoms = List.concat [ left, right ], selection = span start start }


insertAt : List Atom -> Position -> Model -> Model
insertAt new position model =
    let
        ( left, right ) =
            model.atoms |> List.splitAt position

        atoms =
            List.concat [ left, new, right ]

        endPos =
            position + List.length new
    in
    { model | atoms = atoms, selection = span endPos endPos }


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        Enter position ->
            let
                selection =
                    case model.selecting of
                        Just start ->
                            let
                                end =
                                    if position <= start then
                                        position

                                    else
                                        position + 1
                            in
                            span start end

                        Nothing ->
                            if model.moving /= Nothing then
                                span position position

                            else
                                model.selection
            in
            if selection /= model.selection then
                ( { model | selection = selection }, Ports.setCallInputGhostSelection selection )

            else
                ( model, Cmd.none )

        StartSelection position ->
            let
                selection =
                    span position position
            in
            ( { model | selection = selection, selecting = Just position }
            , Ports.setCallInputGhostSelection selection
            )

        StartMoving position ->
            ( { model | moving = Just position }, Cmd.none )

        EndSelection position ->
            let
                s =
                    case model.selecting of
                        Just start ->
                            let
                                end =
                                    if position <= start then
                                        position

                                    else
                                        position + 1
                            in
                            span start end

                        Nothing ->
                            span position position

                m =
                    { model | selection = s, selecting = Nothing }

                newModel =
                    case m.moving of
                        Just from ->
                            if from == position then
                                { m | selection = span from (from + 1) }

                            else
                                let
                                    value =
                                        m.atoms
                                            |> List.getAt from
                                            |> Maybe.map (\v -> [ v ])
                                            |> Maybe.withDefault []

                                    original =
                                        if position < from then
                                            from + 1

                                        else
                                            from
                                in
                                m
                                    |> insertAt value position
                                    |> deleteSpan (span original (original + 1))

                        Nothing ->
                            m
            in
            ( { newModel | moving = Nothing }, Ports.setCallInputGhostSelection newModel.selection )

        AddSlot ->
            let
                newModel =
                    model
                        |> deleteSpan model.selection
                        |> insertAt [ Slot Transform.None Style.None ] model.selection.start
            in
            ( newModel, Ports.setCallInputGhostSelection newModel.selection )

        SetStyle style ->
            ( applyToSelection (setStyle style) model, Cmd.none )

        SetTransform transform ->
            let
                setTransform atom =
                    case atom of
                        Slot _ s ->
                            Slot transform s

                        _ ->
                            atom
            in
            ( applyToSelection setTransform model, Cmd.none )

        UpdateFromGhost str ->
            let
                old =
                    model.atoms |> List.map atomToChar

                new =
                    str |> String.toList

                diff =
                    Diff.diff old new

                folder change ( input, output ) =
                    case change of
                        Diff.NoChange _ ->
                            case input of
                                first :: rest ->
                                    ( rest, Just first :: output )

                                _ ->
                                    ( input, output )

                        Diff.Added char ->
                            let
                                previousStyle =
                                    case output of
                                        first :: _ ->
                                            first |> Maybe.andThen getStyle

                                        _ ->
                                            Nothing

                                setStyleIfPrevious =
                                    previousStyle |> Maybe.map (\s -> setStyle s) |> Maybe.withDefault identity
                            in
                            ( input, (char |> charToAtom |> setStyleIfPrevious |> Just) :: output )

                        Diff.Removed _ ->
                            case input of
                                _ :: rest ->
                                    ( rest, output )

                                _ ->
                                    ( input, output )

                ( _, updated ) =
                    List.foldl folder ( model.atoms, [] ) diff
            in
            ( { model | atoms = updated |> List.filterMap identity |> List.reverse }, Cmd.none )

        GhostSelectionChanged selection ->
            ( { model | selection = selection }, Cmd.none )


applyToSelection : (Atom -> Atom) -> Model -> Model
applyToSelection f model =
    { model | atoms = model.atoms |> applyToSpan model.selection f }


applyToSpan : Span -> (Atom -> Atom) -> List Atom -> List Atom
applyToSpan s f =
    List.updateIfIndex (\i -> inSpan i s) f


subscriptions : (Msg -> msg) -> Sub msg
subscriptions wrap =
    Ports.getCallInputGhostSelection (GhostSelectionChanged >> wrap)


lines : List Atom -> List (List ( Int, Atom ))
lines =
    List.indexedMap (\i a -> ( i, a ))
        >> List.groupWhile (\( _, a ) _ -> a /= NewLine)
        >> List.map (\( f, r ) -> f :: r)


view : (Msg -> msg) -> Card.Source -> Model -> Html msg
view wrap source model =
    let
        stringVersion =
            model.atoms
                |> List.map atomToChar
                |> String.fromList

        callInputGhost =
            Html.textarea
                [ HtmlA.id "call-input-ghost"
                , HtmlA.value stringVersion
                , HtmlE.onInput (UpdateFromGhost >> wrap)
                , onSelect (GhostSelectionChanged >> wrap)
                ]
                []

        content =
            callInputGhost :: (model.atoms ++ [ NewLine ] |> lines |> List.map (viewLine wrap model))

        selection =
            model.selection

        ( ( selectedStyle, styleEnabled ), ( selectedTransform, transformEnabled ) ) =
            let
                selected =
                    model.atoms |> List.drop selection.start |> List.take (selection.end - selection.start)

                allSame parts =
                    case parts |> List.filterMap identity of
                        first :: rest ->
                            if rest |> List.all ((==) first) then
                                Just first

                            else
                                Nothing

                        [] ->
                            Nothing
            in
            ( ( selected |> List.map getStyle |> allSame, True )
            , ( selected |> List.map getTransform |> allSame, selected |> List.any isSlot )
            )

        buttonFor icon value flipIf disableValue description act enabled =
            let
                ( action, fullIcon ) =
                    if flipIf == Just value then
                        ( act disableValue, [ icon, Icon.slash |> Icon.viewIcon ] )

                    else
                        ( act value, [ icon ] )

                finalAction =
                    if enabled then
                        Just action

                    else
                        Nothing
            in
            IconButton.view (Icon.layers [] fullIcon) description finalAction

        controls =
            Html.div [ HtmlA.class "call-controls" ]
                [ IconButton.view (Icon.plusCircle |> Icon.viewIcon)
                    "Add Slot"
                    (AddSlot |> wrap |> Just)
                , Html.div []
                    [ buttonFor (Icon.text [] "Aa")
                        Transform.Capitalize
                        selectedTransform
                        Transform.None
                        "Capitalize"
                        (SetTransform >> wrap)
                        transformEnabled
                    , buttonFor (Icon.text [] "AA")
                        Transform.UpperCase
                        selectedTransform
                        Transform.None
                        "Uppercase"
                        (SetTransform >> wrap)
                        transformEnabled
                    ]
                , Html.div []
                    [ buttonFor (Icon.italic |> Icon.viewIcon)
                        Style.Em
                        selectedStyle
                        Style.None
                        "Emphasize"
                        (SetStyle >> wrap)
                        styleEnabled
                    ]
                ]

        ps =
            problems model

        problemsView =
            if ps |> List.isEmpty then
                Html.text ""

            else
                Html.ul [ HtmlA.class "problems" ]
                    (ps |> List.map (\p -> Html.li [] [ Html.text p ]))

        slotCount atom =
            if isSlot atom then
                1

            else
                0

        instructions =
            model.atoms |> List.map slotCount |> List.sum |> Deck.defaultInstructions
    in
    Html.div []
        [ controls
        , Card.view Call.type_ Card.Immutable source content (Call.viewInstructions instructions) Card.Face
        , problemsView
        ]


onSelect : (Span -> msg) -> Html.Attribute msg
onSelect wrap =
    let
        decoder =
            Json.map2 (\s e -> span s e |> wrap)
                (Json.at [ "target", "selectionStart" ] Json.int)
                (Json.at [ "target", "selectionEnd" ] Json.int)
    in
    HtmlE.on "select" decoder


atomToChar : Atom -> Char
atomToChar atom =
    case atom of
        Letter char _ ->
            char

        Slot _ _ ->
            '_'

        NewLine ->
            '\n'


charToAtom : Char -> Atom
charToAtom char =
    case char of
        '_' ->
            Slot Transform.None Style.None

        '\n' ->
            NewLine

        _ ->
            Letter char Style.None


problems : Model -> List String
problems model =
    if model.atoms |> List.any isSlot then
        []

    else
        [ "Calls must contain at least one slot." ]


viewLine : (Msg -> msg) -> Model -> List ( Int, Atom ) -> Html msg
viewLine wrap model line =
    Html.p [] (line |> clusterAtoms |> List.map (viewClusters (viewAtom wrap model)))


clusterAtoms : List ( a, Atom ) -> List ( ( a, Atom ), List ( a, Atom ) )
clusterAtoms line =
    let
        ifBroken c =
            if c == ' ' then
                False

            else
                True

        isCluster ( _, a ) ( _, b ) =
            case a of
                Letter c _ ->
                    case b of
                        Letter _ _ ->
                            ifBroken c

                        Slot _ _ ->
                            ifBroken c

                        _ ->
                            False

                Slot _ _ ->
                    case b of
                        Letter c _ ->
                            ifBroken c

                        _ ->
                            False

                _ ->
                    False
    in
    line |> List.groupWhile isCluster


viewClusters : (( Int, Atom ) -> Html msg) -> ( ( Int, Atom ), List ( Int, Atom ) ) -> Html msg
viewClusters v ( single, rest ) =
    case rest of
        [] ->
            v single

        _ ->
            let
                content =
                    single :: rest

                attrs =
                    if content |> List.any ((\( _, a ) -> a) >> isSlot) then
                        [ HtmlA.class "affixed-slot" ]

                    else
                        []
            in
            Html.span attrs (content |> List.map v)


viewAtom : (Msg -> msg) -> Model -> ( Int, Atom ) -> Html msg
viewAtom wrap model ( position, atom ) =
    let
        attrs =
            [ position |> Enter |> wrap |> HtmlE.onMouseEnter
            , position |> EndSelection |> wrap |> HtmlE.onMouseUp
            , HtmlA.classList
                [ ( "cursor", model.selection == Span position position )
                , ( "selected", model.selection |> inSpan position )
                ]
            ]
    in
    case atom of
        Letter char style ->
            Style.toNode style
                ([ position |> StartSelection |> wrap |> HtmlE.onMouseDown ] ++ attrs)
                [ char |> String.fromChar |> Html.text ]

        Slot transform style ->
            let
                slotAttrs =
                    HtmlA.class "slot empty"
                        :: (position |> StartMoving |> wrap |> HtmlE.onMouseDown)
                        :: Transform.toAttributes transform
            in
            Style.toNode style (slotAttrs ++ attrs) []

        NewLine ->
            Html.span ([ HtmlA.class "spacer" ] ++ attrs) []


getStyle : Atom -> Maybe Style
getStyle atom =
    case atom of
        Letter _ s ->
            Just s

        Slot _ s ->
            Just s

        _ ->
            Nothing


setStyle : Style -> Atom -> Atom
setStyle style atom =
    case atom of
        Letter c _ ->
            Letter c style

        Slot t _ ->
            Slot t style

        _ ->
            atom


getTransform : Atom -> Maybe Transform
getTransform atom =
    case atom of
        Slot t _ ->
            Just t

        _ ->
            Nothing


span : Position -> Position -> Span
span a b =
    if a < b then
        Span a b

    else
        Span b a


inSpan : Position -> Span -> Bool
inSpan position { start, end } =
    position >= start && position < end


isSlot : Atom -> Bool
isSlot atom =
    case atom of
        Slot _ _ ->
            True

        _ ->
            False


partToAtoms : Part -> List Atom
partToAtoms part =
    let
        textToAtoms ( text, style ) =
            text |> String.toList |> List.map (\c -> Letter c style)
    in
    case part of
        Part.Text text style ->
            textToAtoms ( text, style )

        Part.Slot transform style ->
            [ Slot transform style ]


editorToCall : Model -> Result String Call
editorToCall { atoms } =
    let
        parts =
            atoms |> List.groupWhile (\_ b -> b /= NewLine) |> List.map atomsToParts
    in
    if parts |> List.any (List.any Part.isSlot) then
        parts |> Call |> Ok

    else
        "Calls must contain at least one slot." |> Err


atomsToParts : ( Atom, List Atom ) -> List Part
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
