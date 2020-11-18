module ManyDecks.Language exposing
    ( Described
    , description
    )


type alias Described =
    { code : String -- The full language code.
    , description : String -- A description of the language.
    }


description : List Described -> String -> String
description knownLanguages code =
    knownLanguages
        |> List.filter (\lang -> lang.code == code)
        |> List.head
        |> Maybe.map .description
        |> Maybe.withDefault code
