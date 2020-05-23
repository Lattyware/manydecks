module ManyDecks.Model exposing
    ( Model
    , Route(..)
    )

import Browser.Navigation as Navigation
import ManyDecks.Auth exposing (Auth)
import ManyDecks.Auth.Methods as Auth
import ManyDecks.Error.Model exposing (Error)
import ManyDecks.Pages.Decks.Edit.Model as Edit
import ManyDecks.Pages.Decks.Model as Decks
import ManyDecks.Pages.Decks.Route as Decks


type Route
    = Login (Maybe String)
    | Profile
    | Decks Decks.Route
    | NotFound String


type alias Model =
    { navKey : Navigation.Key
    , route : Route
    , error : Maybe Error
    , origin : String

    -- Login
    , auth : Maybe Auth
    , authMethods : Maybe Auth.Methods

    -- Profile
    , usernameField : String
    , profileDeletionEnabled : Bool

    -- Decks List
    , decks : Maybe (List Decks.CodeAndSummary)

    -- Decks Edit
    , edit : Maybe Edit.Model
    }
