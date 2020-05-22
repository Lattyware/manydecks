module ManyDecks.Messages exposing (Msg(..))

import ManyDecks.Error.Model exposing (Error)
import ManyDecks.Model exposing (Route)
import ManyDecks.Pages.Decks.Edit.Model as Edit exposing (Change)
import ManyDecks.Pages.Decks.Messages as Decks
import ManyDecks.Pages.Login.Messages as Login
import ManyDecks.Pages.Profile.Messages as Profile


type Msg
    = NoOp
    | OnRouteChanged Route
    | ChangePage Route
    | SetError Error
    | ClearError
    | LoginMsg Login.Msg
    | DecksMsg Decks.Msg
    | ProfileMsg Profile.Msg
    | EditMsg Edit.Msg
