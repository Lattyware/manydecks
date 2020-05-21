module ManyDecks.Pages.Profile.Model exposing
    ( Model
    , Msg(..)
    , init
    )

import Http
import ManyDecks.Auth exposing (Auth)


type Msg
    = SetUsername String
    | SetViewingProfile Bool
    | SetDeletionEnabled Bool
    | Delete
    | Save String
    | Error Http.Error


type alias Model =
    { viewing : Bool
    , deletionEnabled : Bool
    , name : String
    }


init : Auth -> Model
init auth =
    { viewing = False
    , deletionEnabled = False
    , name = auth.name
    }
