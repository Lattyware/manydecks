module ManyDecks.Error.Model exposing
    ( ApplicationError(..)
    , Error(..)
    , TransientError(..)
    , UserError(..)
    )

import Json.Decode as Json


type Error
    = Application ApplicationError
    | Transient TransientError
    | User UserError


type ApplicationError
    = InvalidUrl String
    | BadResponse Json.Error
    | BadPatch
    | BadDeck
    | ServerError


type TransientError
    = ServerDown
    | NetworkError
    | AuthFailure


type UserError
    = DeckNotFound
    | PatchTestFailed
    | NotAuthenticated
