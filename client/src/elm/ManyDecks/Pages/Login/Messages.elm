module ManyDecks.Pages.Login.Messages exposing (..)

import ManyDecks.Auth exposing (Auth)
import ManyDecks.Auth.Google as Google
import ManyDecks.Auth.Guest as Guest
import ManyDecks.Auth.Methods as Auth


type Msg
    = ReceiveMethods Auth.Methods
    | TryGoogleSignIn Google.Method
    | GoogleAuthResult String
    | TryGuestSignIn Guest.Method
    | SetAuth Auth
    | SignOut
