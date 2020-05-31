module ManyDecks.Pages.Decks.Browse.Model exposing
    ( Model
    , Page
    , Query
    )

import ManyDecks.Pages.Decks.Model as Decks


type alias Query =
    { page : Int
    , language : Maybe String
    , search : Maybe String
    }


type alias Page =
    { query : Query
    , decks : List Decks.CodeAndSummary
    }


type alias Model =
    { searchQuery : String
    , page : Page
    }
