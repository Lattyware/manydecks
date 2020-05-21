module ManyDecks.Pages.Edit.Import.Model exposing (ImportedCard(..), Model)

import Cards.Call exposing (Call)
import Cards.Response exposing (Response)


type alias Model =
    { text : String }


type ImportedCard
    = ImportedCall Call
    | ImportedResponse Response
