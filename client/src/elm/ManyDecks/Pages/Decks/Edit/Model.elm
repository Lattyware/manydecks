module ManyDecks.Pages.Decks.Edit.Model exposing
    ( CardChange(..)
    , CardEditor(..)
    , Change(..)
    , Direction(..)
    , EditError(..)
    , Model
    , Msg(..)
    , UpdateEditor(..)
    )

import Cards.Call exposing (Call)
import Cards.Response exposing (Response)
import ManyDecks.Deck exposing (Deck)
import ManyDecks.Pages.Decks.Edit.CallEditor.Model as CallEditor
import ManyDecks.Pages.Decks.Edit.Import.Model as Import
import ManyDecks.Pages.Decks.Edit.LanguageSelector as LanguageSelector


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
    | LanguageSelectorMsg LanguageSelector.Msg
    | ClearErrors


type alias Model =
    { deck : Deck
    , editing : Maybe CardEditor
    , changes : List ( Change, Direction )
    , undoStack : List Change
    , redoStack : List Change
    , errors : List EditError
    , deletionEnabled : Bool
    , importer : Maybe Import.Model
    , saving : Bool
    , languageSelector : LanguageSelector.Model
    }


type UpdateEditor
    = UpdateName String
    | UpdateCall CallEditor.Msg
    | UpdateResponse Response


type Change
    = ChangeName String String
    | ChangePublic Bool
    | ChangeLanguage (Maybe String) (Maybe String)
    | CallChange (CardChange Call)
    | ResponseChange (CardChange Response)


type Direction
    = Perform
    | Revert


type CardChange value
    = Add Int value
    | Replace Int value value
    | Remove Int value


type EditError
    = ChangeError String Change Direction
