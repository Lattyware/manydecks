module Cards.Deck exposing
    ( Deck
    , decode
    , empty
    , encode
    )

import Cards.Call as Call exposing (Call)
import Cards.Response as Response exposing (Response)
import Json.Decode as Json
import Json.Decode.Pipeline as Json
import Json.Encode


type alias Deck =
    { name : String
    , language : Maybe String
    , author : Maybe String
    , calls : List Call
    , responses : List Response
    }


empty : Deck
empty =
    { name = "New Deck"
    , language = Nothing
    , author = Nothing
    , calls = []
    , responses = []
    }


encode : Deck -> Json.Value
encode deck =
    let
        maybeField field =
            case field of
                ( n, Just v ) ->
                    Just ( n, v )

                ( _, Nothing ) ->
                    Nothing

        maybeObject =
            List.filterMap maybeField >> Json.Encode.object
    in
    maybeObject
        [ ( "name", Json.Encode.string deck.name |> Just )
        , ( "language", deck.language |> Maybe.map Json.Encode.string )
        , ( "author", deck.author |> Maybe.map Json.Encode.string )
        , ( "calls", deck.calls |> Json.Encode.list Call.encode |> Just )
        , ( "responses", deck.responses |> Json.Encode.list Response.encode |> Just )
        ]


decode : Json.Decoder Deck
decode =
    Json.succeed Deck
        |> Json.required "name" Json.string
        |> Json.optional "language" (Json.string |> Json.map Just) Nothing
        |> Json.optional "author" (Json.string |> Json.map Just) Nothing
        |> Json.required "calls" (Json.list Call.decode)
        |> Json.required "responses" (Json.list Response.decode)
