module ManyDecks.Messages exposing (Msg(..))

import ManyDecks.Error.Model exposing (Error)
import ManyDecks.Model exposing (Route)
import ManyDecks.Pages.Decks.Browse.Messages as Browse
import ManyDecks.Pages.Decks.Edit.LanguageSelector as LanguageSelector
import ManyDecks.Pages.Decks.Edit.Model as Edit exposing (Change)
import ManyDecks.Pages.Decks.Messages as Decks
import ManyDecks.Pages.Login.Messages as Login
import ManyDecks.Pages.Profile.Messages as Profile
import Url exposing (Url)


type Msg
    = NoOp
    | OnRouteChanged Route
    | ChangePage Route
    | SetError Error
    | ClearError
    | LoginMsg Login.Msg
    | DecksMsg Decks.Msg
    | BrowseMsg Browse.Msg
    | ProfileMsg Profile.Msg
    | EditMsg Edit.Msg
    | LoadLink Url
    | Copy String
    | SetLanguages (List String)
    | UpdateLanguageDescription LanguageSelector.Tag
