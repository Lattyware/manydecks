module ManyDecks.Error exposing (..)

import Html exposing (Html)
import Html.Attributes as HtmlA
import Http
import Json.Decode as Json
import Material.Card as Card


type Error
    = Http Http.Error
    | Json Json.Error


view : Maybe Error -> Html msg
view error =
    case error of
        Just e ->
            Html.div [ HtmlA.class "core-error" ]
                [ Card.view []
                    [ Html.p [] [ Html.text "Sorry, there appears to have been a problem, please try refreshing the page." ]
                    , Html.p [] [ e |> message |> Html.text ]
                    ]
                ]

        Nothing ->
            Html.text ""


message : Error -> String
message error =
    case error of
        Http e ->
            case e of
                Http.BadUrl url ->
                    "Application bug: Tried to access “" ++ url ++ "” which isn't a valid URL."

                Http.Timeout ->
                    "Timed out trying to connect to the server, it is probably down. Try again after a short delay."

                Http.NetworkError ->
                    "Could not connect to the server. Please check your internet connection and try again."

                Http.BadStatus status ->
                    if status == 504 || status == 502 then
                        "The server appears to be down. Try again after a short delay."

                    else if status >= 400 && status < 500 then
                        "The server rejected that, please check for problems."

                    else if status >= 500 && status < 600 then
                        "There was a problem with the server."

                    else
                        "The server returned an expected response."

                Http.BadBody description ->
                    "We got a response we didn't expect from the server: " ++ description

        Json e ->
            e |> Json.errorToString
