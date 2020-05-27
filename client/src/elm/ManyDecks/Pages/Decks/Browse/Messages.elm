module ManyDecks.Pages.Decks.Browse.Messages exposing (Msg(..))

import ManyDecks.Pages.Decks.Browse.Model as Browse


type Msg
    = SetSearchQuery String
    | DoSearch String
    | ReceiveDecks Browse.Page
