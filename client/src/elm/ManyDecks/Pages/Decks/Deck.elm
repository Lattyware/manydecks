module ManyDecks.Pages.Decks.Deck exposing
    ( Call
    , Code
    , Details
    , EditableDeck
    , Line
    , Part(..)
    , Response
    , Style(..)
    , Summary
    , Transform(..)
    , codeDecoder
    , codeToString
    , detailsDecoder
    , editableDeckEncoder
    , summaryDecoder
    , viewCode
    )

import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode as Json
import Json.Decode.Pipeline as Json
import Json.Encode


type Code
    = Code String


codeDecoder : Json.Decoder Code
codeDecoder =
    Json.string |> Json.map Code


viewCode : (String -> msg) -> Code -> Html msg
viewCode copy (Code code) =
    Html.input
        [ code |> HtmlA.id
        , HtmlA.type_ "text"
        , HtmlA.readonly True
        , HtmlA.class "deck-code"
        , HtmlA.value code
        , code |> copy |> HtmlE.onClick
        ]
        []


codeToString : Code -> String
codeToString (Code code) =
    code


type Transform
    = NoTransform
    | UpperCase
    | Capitalize


type Style
    = NoStyle
    | Em


type Part
    = Text String Style
    | Slot Transform Style


type alias Line =
    List Part


type alias Call =
    List Line


type alias Response =
    String


type alias Details =
    { name : String
    , author : String
    , language : Maybe String
    }


detailsDecoder : Json.Decoder Details
detailsDecoder =
    Json.succeed Details
        |> Json.required "name" Json.string
        |> Json.required "author" Json.string
        |> Json.optional "language" (Json.string |> Json.map Just) Nothing


type alias Summary =
    { details : Details
    , calls : Int
    , responses : Int
    , version : Int
    }


summaryDecoder : Json.Decoder Summary
summaryDecoder =
    Json.succeed Summary
        |> Json.required "details" detailsDecoder
        |> Json.required "calls" Json.int
        |> Json.required "responses" Json.int
        |> Json.required "version" Json.int


type alias Deck =
    { details : Details
    , calls : List Call
    , responses : List Response
    , version : Int
    }


type alias EditableDeck =
    { name : String
    , language : String
    , calls : List Call
    , responses : List Response
    }


editableDeckEncoder : EditableDeck -> Json.Value
editableDeckEncoder { name, language, calls, responses } =
    Json.Encode.object
        [ ( "name", name |> Json.Encode.string )
        , ( "language", language |> Json.Encode.string )
        , ( "calls", calls |> Json.Encode.list encodeCall )
        , ( "responses", responses |> Json.Encode.list Json.Encode.string )
        ]


encodeCall : List (List Part) -> Json.Encode.Value
encodeCall =
    Json.Encode.list encodeLine


encodeLine : List Part -> Json.Encode.Value
encodeLine =
    Json.Encode.list encodePart


encodePart : Part -> Json.Encode.Value
encodePart part =
    let
        fields =
            case part of
                Text text style ->
                    [ text |> encodeText, style |> encodeStyle ]

                Slot transform style ->
                    [ transform |> encodeTransform, style |> encodeStyle ]
    in
    fields |> List.concat |> Json.Encode.object


encodeText : String -> List ( String, Json.Encode.Value )
encodeText text =
    [ ( "text", text |> Json.Encode.string ) ]


encodeStyle : Style -> List ( String, Json.Encode.Value )
encodeStyle style =
    case style of
        NoStyle ->
            []

        Em ->
            [ ( "style", "Em" |> Json.Encode.string ) ]


encodeTransform : Transform -> List ( String, Json.Encode.Value )
encodeTransform transform =
    case transform of
        NoTransform ->
            []

        Capitalize ->
            [ ( "transform", "Capitalize" |> Json.Encode.string ) ]

        UpperCase ->
            [ ( "transform", "UpperCase" |> Json.Encode.string ) ]
