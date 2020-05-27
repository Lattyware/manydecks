module ManyDecks.Pages.Decks.Messages exposing (..)

import File exposing (File)
import Json.Patch.Invertible as Json
import ManyDecks.Auth exposing (Auth)
import ManyDecks.Deck as Deck exposing (Deck)
import ManyDecks.Pages.Decks.Model exposing (CodeAndSummary)


type Msg
    = ReceiveDecks (List CodeAndSummary)
    | UploadDeck
    | UploadedDeck File
    | Json5Parse String
    | DownloadDeck Deck
    | NewDeck Deck
    | EditDeck Deck.Code (Maybe Deck)
    | ViewDeck Deck.Code (Maybe Deck)
    | Save Deck.Code Json.Patch
    | DeckSaved Auth Deck.Code Deck
    | Delete Deck.Code
    | DeckDeleted Deck.Code
