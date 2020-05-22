module ManyDecks.Pages.Decks.Edit.Model exposing
    ( CardChange(..)
    , CardEditor(..)
    , Change(..)
    , EditError(..)
    , Model
    , Msg(..)
    , UpdateEditor(..)
    )

import Cards.Call exposing (Call)
import Cards.Deck as Deck exposing (Deck)
import Cards.Response exposing (Response)
import ManyDecks.Pages.Decks.Edit.CallEditor.Model as CallEditor
import ManyDecks.Pages.Decks.Edit.Import.Model as Import


type CardEditor
    = NameEditor String String
    | CallEditor Int Call CallEditor.Model
    | ResponseEditor Int Response Response


type Msg
    = StartEditing CardEditor
    | Edit UpdateEditor
    | EndEditing
    | Delete
    | Undo
    | Redo
    | SetDeletionEnabled Bool
    | ApplyChange Change
    | SetImportVisible Bool
    | Import
    | UpdateImportText String


type alias Model =
    { deck : Deck
    , editing : Maybe CardEditor
    , changes : List Change
    , redoStack : List Change
    , errors : List EditError
    , deletionEnabled : Bool
    , importer : Maybe Import.Model
    }


type UpdateEditor
    = UpdateName String
    | UpdateCall CallEditor.Msg
    | UpdateResponse Response


type Change
    = ChangeName String String
    | CallChange (CardChange Call)
    | ResponseChange (CardChange Response)


type CardChange value
    = Add Int value
    | Replace Int value value
    | Remove Int value


type EditError
    = ChangeError String (List Change) Bool
