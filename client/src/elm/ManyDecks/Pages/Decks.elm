module ManyDecks.Pages.Decks exposing (..)

import Bytes exposing (Bytes)
import Cards.Deck as Deck exposing (Deck)
import FontAwesome.Attributes as Icon
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Html.Keyed as HtmlK
import Http
import Json.Decode as Json
import Json.Encode
import Json.Patch
import Json.Patch.Invertible as Json
import ManyDecks.Messages exposing (Msg(..))
import ManyDecks.Pages.Decks.Deck as Deck exposing (codeDecoder)
import ManyDecks.Pages.Decks.Model exposing (..)
import Material.Button as Button
import Material.Card as Card


view : Maybe (List CodeAndSummary) -> List (Html Msg)
view decks =
    let
        renderedDecks =
            case decks of
                Just d ->
                    d |> List.map deck |> HtmlK.ul []

                Nothing ->
                    Icon.spinner |> Icon.viewStyled [ Icon.spin ]

        newDeck =
            Button.view Button.Raised
                Button.Padded
                "New Deck"
                (Icon.plus |> Icon.viewIcon |> Just)
                (Deck.empty |> NewDeck |> Just)

        uploadDeck =
            Button.view Button.Raised
                Button.Padded
                "Upload Deck"
                (Icon.upload |> Icon.viewIcon |> Just)
                (Just UploadDeck)

        controls =
            Html.div [ HtmlA.class "controls" ] [ uploadDeck, newDeck ]
    in
    [ Card.view [ HtmlA.class "decks" ] [ renderedDecks, controls ] ]


deck : CodeAndSummary -> ( String, Html Msg )
deck { code, summary } =
    ( code |> Deck.codeToString
    , Html.li [ HtmlA.class "deck" ]
        [ Deck.viewCode Copy code
        , Html.div [ HtmlA.class "details", EditDeck code Nothing False |> HtmlE.onClick ]
            [ Html.span [ HtmlA.class "name", HtmlA.title summary.details.name ] [ Html.text summary.details.name ]
            , Html.span [ HtmlA.class "language" ] [ summary.details.language |> Maybe.withDefault "" |> Html.text ]
            ]
        , Html.div [ HtmlA.class "cards" ]
            [ Html.span [ HtmlA.class "calls", HtmlA.title "Calls" ]
                [ summary.calls |> String.fromInt |> Html.text ]
            , Html.span [ HtmlA.class "responses", HtmlA.title "Responses" ]
                [ summary.responses |> String.fromInt |> Html.text ]
            ]
        ]
    )


getDeck : Deck.Code -> (Result Http.Error Deck -> msg) -> Cmd msg
getDeck code toMsg =
    Http.get
        { url = "/api/decks/" ++ (code |> Deck.codeToString)
        , expect = Http.expectJson toMsg Deck.decode
        }


getDecks : String -> (Result Http.Error (List CodeAndSummary) -> msg) -> Cmd msg
getDecks token toMsg =
    Http.post
        { url = "/api/decks"
        , body = [ ( "token", token |> Json.Encode.string ) ] |> Json.Encode.object |> Http.jsonBody
        , expect = Http.expectJson toMsg (summaryAndCodeDecoder |> Json.list)
        }


createDeck : String -> Deck.Deck -> (Result Http.Error Deck.Code -> msg) -> Cmd msg
createDeck token d toMsg =
    Http.post
        { url = "/api/decks"
        , body =
            [ ( "token", token |> Json.Encode.string )
            , ( "initial", d |> Deck.encode )
            ]
                |> Json.Encode.object
                |> Http.jsonBody
        , expect = Http.expectJson toMsg codeDecoder
        }


deleteDeck : String -> Deck.Code -> Cmd Msg
deleteDeck token code =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = "/api/decks/" ++ Deck.codeToString code
        , body = [ ( "token", token |> Json.Encode.string ) ] |> Json.Encode.object |> Http.jsonBody
        , expect = Http.expectWhatever (always NoOp)
        , timeout = Nothing
        , tracker = Nothing
        }


save : String -> Deck.Code -> Json.Patch -> (Result Http.Error () -> msg) -> Cmd msg
save token code patch toMsg =
    Http.request
        { method = "PATCH"
        , headers = []
        , url = "/api/decks/" ++ Deck.codeToString code
        , body =
            [ ( "token", token |> Json.Encode.string )
            , ( "patch", patch |> Json.toPatch |> Json.Patch.encoder )
            ]
                |> Json.Encode.object
                |> Http.jsonBody
        , expect = Http.expectWhatever toMsg
        , timeout = Nothing
        , tracker = Nothing
        }


backup : String -> (Result Http.Error Bytes -> msg) -> Cmd msg
backup token toMsg =
    Http.post
        { url = "/api/backup"
        , body =
            [ ( "token", token |> Json.Encode.string ) ]
                |> Json.Encode.object
                |> Http.jsonBody
        , expect = Http.expectBytesResponse toMsg resolve
        }


resolve : Http.Response Bytes -> Result Http.Error Bytes
resolve response =
    case response of
        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata _ ->
            Err (Http.BadStatus metadata.statusCode)

        Http.GoodStatus_ _ body ->
            Ok body
