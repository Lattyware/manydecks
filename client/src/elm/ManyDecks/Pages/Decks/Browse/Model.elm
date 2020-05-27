module ManyDecks.Pages.Decks.Browse.Model exposing
    ( Model
    , Page
    )

import ManyDecks.Pages.Decks.Model as Decks


type alias Page =
    { search : Maybe String
    , index : Int
    , decks : List Decks.CodeAndSummary
    }


type alias Model =
    { searchQuery : String
    , page : Page
    }
