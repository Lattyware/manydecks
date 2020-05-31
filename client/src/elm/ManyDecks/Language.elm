module ManyDecks.Language exposing
    ( Described
    , description
    )


type alias Described =
    { code : String
    , description : String
    }


description : List Described -> String -> String
description knownLanguages code =
    knownLanguages
        |> List.filter (\lang -> lang.code == code)
        |> List.head
        |> Maybe.map .description
        |> Maybe.withDefault code
