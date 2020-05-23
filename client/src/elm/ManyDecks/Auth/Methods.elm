module ManyDecks.Auth.Methods exposing (..)

import Json.Decode as Json
import Json.Decode.Pipeline as Json
import ManyDecks.Auth.Google as Google
import ManyDecks.Auth.Guest as Guest
import ManyDecks.Auth.Twitch as Twitch


type alias Methods =
    { google : Maybe Google.Method
    , twitch : Maybe Twitch.Method
    , guest : Maybe Guest.Method
    }


decode : Json.Decoder Methods
decode =
    Json.succeed Methods
        |> Json.optional "google" (Google.decode |> Json.map Just) Nothing
        |> Json.optional "twitch" (Twitch.decode |> Json.map Just) Nothing
        |> Json.optional "guest" (Guest.decode |> Json.map Just) Nothing
