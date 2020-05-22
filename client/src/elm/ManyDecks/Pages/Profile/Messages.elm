module ManyDecks.Pages.Profile.Messages exposing (Msg(..))

import Bytes exposing (Bytes)
import ManyDecks.Auth exposing (Auth)


type Msg
    = SetUsername String
    | SetDeletionEnabled Bool
    | Save String
    | ProfileUpdated Auth
    | Delete
    | ProfileDeleted
    | Backup
    | DownloadBytes Bytes
