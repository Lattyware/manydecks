module ManyDecks.Meta exposing (..)

import Url.Builder as Url


projectUrl : String
projectUrl =
    Url.crossOrigin "https://github.com" [ "Lattyware", "manydecks" ] []


issuesUrl : String
issuesUrl =
    Url.crossOrigin "https://github.com" [ "Lattyware", "manydecks", "issues" ] []


massiveDecksUrl : String
massiveDecksUrl =
    Url.crossOrigin "https://md.rereadgames.com" [] []
