module ManyDecks.Pages.Edit.CallEditor exposing
    ( problems
    , subscriptions
    , update
    , view
    )

import Browser.Events as Browser
import Cards.Call as Call
import Cards.Call.Style as Style
import Cards.Call.Transform as Transform
import Cards.Card as Card
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode as Json
import List.Extra as List
import ManyDecks.Pages.Edit.CallEditor.Model exposing (..)


deleteSpan : Span -> Model -> Model
deleteSpan { start, end } model =
    let
        left =
            model.atoms |> List.take start

        right =
            model.atoms |> List.drop end
    in
    { model | atoms = List.concat [ left, right ], selection = Nothing, cursor = start }


insertAt : List Atom -> Position -> Model -> Model
insertAt new position model =
    let
        ( left, right ) =
            model.atoms |> List.splitAt position

        atoms =
            List.concat [ left, new, right ]
    in
    { model | atoms = atoms, cursor = position + List.length new }


moveCursor : (Position -> Position) -> Model -> Model
moveCursor move model =
    let
        afterLast =
            List.length model.atoms

        cursor =
            min afterLast (max (model.cursor |> move) 0)

        selection =
            case model.selecting of
                Just start ->
                    selectionOf start cursor

                Nothing ->
                    Nothing
    in
    { model | cursor = cursor, selection = selection }


moveRow : Int -> Model -> Model
moveRow diff model =
    let
        applyNTimes n f value =
            if n > 0 then
                value |> f |> applyNTimes (n - 1) f

            else
                value

        atoms =
            model.atoms
    in
    if diff > 0 then
        model |> applyNTimes diff (moveCursor (\p -> p + toEndOfLine atoms p + 1))

    else
        model |> applyNTimes -diff (moveCursor (\p -> p - toStartOfLine atoms p - 1))


toEndOfLine : List Atom -> Position -> Int
toEndOfLine atoms p =
    atoms
        |> List.drop p
        |> List.findIndex ((==) NewLine)
        |> Maybe.withDefault (List.length atoms)


toStartOfLine : List Atom -> Position -> Int
toStartOfLine atoms p =
    let
        pRev =
            List.length atoms - p
    in
    atoms
        |> List.reverse
        |> List.drop pRev
        |> List.findIndex ((==) NewLine)
        |> Maybe.withDefault p


update : Msg -> Model -> Model
update msg model =
    case msg of
        KeyUp key ->
            case key of
                Control "Shift" ->
                    { model | selecting = Nothing }

                Control "Control" ->
                    { model | control = False }

                _ ->
                    model

        KeyDown key ->
            let
                cursor =
                    model.cursor

                op =
                    case key of
                        Control "Delete" ->
                            case model.selection of
                                Nothing ->
                                    deleteSpan (span cursor (cursor + 1))

                                Just selection ->
                                    deleteSpan selection

                        Control "Backspace" ->
                            case model.selection of
                                Nothing ->
                                    deleteSpan (span (cursor - 1) cursor)

                                Just selection ->
                                    deleteSpan selection

                        Control "Enter" ->
                            case model.selection of
                                Nothing ->
                                    insertAt [ NewLine ] cursor

                                Just selection ->
                                    deleteSpan selection >> (\m -> insertAt [ NewLine ] m.cursor m)

                        Control "ArrowLeft" ->
                            moveCursor (\c -> c - 1)

                        Control "ArrowRight" ->
                            moveCursor (\c -> c + 1)

                        Control "ArrowUp" ->
                            moveRow -1

                        Control "ArrowDown" ->
                            moveRow 1

                        Control "End" ->
                            moveCursor (\p -> p + toEndOfLine model.atoms p)

                        Control "Home" ->
                            moveCursor (\p -> p - toStartOfLine model.atoms p)

                        Control "Shift" ->
                            \m -> { m | selecting = Just m.cursor }

                        Control "Control" ->
                            \m -> { m | control = True }

                        Character char ->
                            if model.control then
                                identity

                            else
                                case model.selection of
                                    Nothing ->
                                        insertAt [ Letter char ] cursor

                                    Just selection ->
                                        deleteSpan selection >> insertAt [ Letter char ] selection.start

                        _ ->
                            identity
            in
            op model

        Enter position ->
            let
                ( selection, cursor ) =
                    case model.selecting of
                        Just start ->
                            let
                                end =
                                    if position <= start then
                                        position

                                    else
                                        position + 1
                            in
                            ( selectionOf start end, end )

                        Nothing ->
                            let
                                c =
                                    if model.moving /= Nothing then
                                        position

                                    else
                                        model.cursor
                            in
                            ( model.selection, c )
            in
            { model | hover = Just position, selection = selection, cursor = cursor }

        Leave position ->
            let
                hover =
                    if model.hover == Just position then
                        Nothing

                    else
                        model.hover
            in
            { model | hover = hover }

        StartSelection position ->
            { model
                | selection = Nothing
                , selecting = Just position
                , cursor = position
            }

        StartMoving position ->
            { model | moving = Just position }

        EndSelection position ->
            let
                ( s, cursor ) =
                    case model.selecting of
                        Just start ->
                            let
                                end =
                                    if position <= start then
                                        position

                                    else
                                        position + 1
                            in
                            ( selectionOf start end, end )

                        Nothing ->
                            ( Nothing, position )

                m =
                    { model | selection = s, selecting = Nothing, cursor = cursor }

                newModel =
                    case m.moving of
                        Just from ->
                            if from == position then
                                { m | selection = span from (from + 1) |> Just }

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
            { newModel | moving = Nothing }

        AddSlot ->
            model |> insertAt [ Slot Transform.None Style.None ] model.cursor


subscriptions : (Msg -> msg) -> Sub msg
subscriptions wrap =
    Sub.batch
        [ Browser.onKeyDown (keyDecoder |> Json.map (KeyDown >> wrap))
        , Browser.onKeyUp (keyDecoder |> Json.map (KeyUp >> wrap))
        ]


lines : List Atom -> List (List ( Int, Atom ))
lines =
    List.indexedMap (\i a -> ( i, a ))
        >> List.groupWhile (\( _, a ) _ -> a /= NewLine)
        >> List.map (\( f, r ) -> f :: r)


view : (Msg -> msg) -> Model -> Html msg
view wrap model =
    let
        content =
            model.atoms ++ [ NewLine ] |> lines |> List.map (viewLine wrap model)
    in
    Html.div [] [ Card.view Call.type_ Card.Immutable content Card.Face ]


problems : Model -> List String
problems model =
    if model.atoms |> List.any isSlot then
        []

    else
        [ "Calls must contain at least one slot." ]


selectionOf : Position -> Position -> Maybe Span
selectionOf start end =
    if start /= end then
        span start end |> Just

    else
        Nothing


viewLine : (Msg -> msg) -> Model -> List ( Int, Atom ) -> Html msg
viewLine wrap model line =
    Html.p [] (line |> List.map (viewAtom wrap model))


viewAtom : (Msg -> msg) -> Model -> ( Int, Atom ) -> Html msg
viewAtom wrap model ( position, atom ) =
    let
        attrs =
            [ position |> Enter |> wrap |> HtmlE.onMouseEnter
            , position |> Leave |> wrap |> HtmlE.onMouseLeave
            , position |> EndSelection |> wrap |> HtmlE.onMouseUp
            , HtmlA.classList
                [ ( "cursor", model.cursor == position )
                , ( "selected", model.selection |> Maybe.map (inSpan position) |> Maybe.withDefault False )
                ]
            ]
    in
    case atom of
        Letter char ->
            Html.span
                ([ position |> StartSelection |> wrap |> HtmlE.onMouseDown ] ++ attrs)
                [ char |> String.fromChar |> Html.text ]

        Slot _ _ ->
            let
                slotAttrs =
                    [ HtmlA.class "slot empty", position |> StartMoving |> wrap |> HtmlE.onMouseDown ]
            in
            Html.span (slotAttrs ++ attrs) []

        NewLine ->
            Html.span ([ HtmlA.class "spacer" ] ++ attrs) []


span : Position -> Position -> Span
span a b =
    if a < b then
        Span a b

    else
        Span b a


inSpan : Position -> Span -> Bool
inSpan position { start, end } =
    position >= start && position < end


keyDecoder : Json.Decoder Key
keyDecoder =
    Json.map toKey (Json.field "key" Json.string)


toKey : String -> Key
toKey string =
    case String.uncons string of
        Just ( char, "" ) ->
            Character char

        _ ->
            Control string


isSlot : Atom -> Bool
isSlot atom =
    case atom of
        Slot _ _ ->
            True

        _ ->
            False
