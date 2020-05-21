module ManyDecks.Messages exposing (Msg(..))

import Bytes exposing (Bytes)
import Cards.Deck as Deck
import File exposing (File)
import Json.Patch.Invertible as Json
import ManyDecks.Auth exposing (Auth)
import ManyDecks.Error exposing (Error)
import ManyDecks.Pages.Decks.Deck as Deck
import ManyDecks.Pages.Decks.Model as Decks
import ManyDecks.Pages.Edit.Model as Edit exposing (Change)
import ManyDecks.Pages.Profile.Model as Profile


type Msg
    = NoOp
    | SetError Error
    | TryGoogleAuth
    | GoogleAuthResult String
    | MdAuthResult Auth
    | ReceiveDecks (List Decks.CodeAndSummary)
    | UploadDeck
    | UploadedDeck File
    | Json5Parse String
    | NewDeck Deck.Deck
    | EditDeck Deck.Code (Maybe Deck.Deck) Bool
    | BackFromEdit
    | Copy String
    | ProfileMsg Profile.Msg
    | EditMsg Edit.Msg
    | Backup
    | DownloadBytes Bytes
    | UpdateAuth Auth
    | Delete Deck.Code
    | Save Deck.Code Json.Patch
    | SignOut
    | Error String
