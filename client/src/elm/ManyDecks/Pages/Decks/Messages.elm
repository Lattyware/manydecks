module ManyDecks.Pages.Decks.Messages exposing (..)

import Cards.Deck exposing (Deck)
import File exposing (File)
import Json.Patch.Invertible as Json
import ManyDecks.Pages.Decks.Deck as Deck
import ManyDecks.Pages.Decks.Model exposing (CodeAndSummary)


type Msg
    = ReceiveDecks (List CodeAndSummary)
    | UploadDeck
    | UploadedDeck File
    | Json5Parse String
    | NewDeck Deck
    | EditDeck Deck.Code (Maybe Deck)
    | ViewDeck Deck.Code (Maybe Deck)
    | BackFromEdit
    | Save Deck.Code Json.Patch
    | DeckSaved Deck.Code Deck.Versioned
    | Delete Deck.Code
    | DeckDeleted Deck.Code
