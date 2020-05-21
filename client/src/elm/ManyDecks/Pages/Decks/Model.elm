module ManyDecks.Pages.Decks.Model exposing (..)

import Json.Decode as Json
import Json.Decode.Pipeline as Json
import ManyDecks.Pages.Decks.Deck as Deck


type alias CodeAndSummary =
    { code : Deck.Code
    , summary : Deck.Summary
    }


summaryAndCodeDecoder : Json.Decoder CodeAndSummary
summaryAndCodeDecoder =
    Json.succeed CodeAndSummary
        |> Json.required "code" Deck.codeDecoder
        |> Json.required "summary" Deck.summaryDecoder
