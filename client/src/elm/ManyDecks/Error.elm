module ManyDecks.Error exposing
    ( decode
    , view
    )

import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Json.Decode as Json
import ManyDecks.Error.Model exposing (..)
import ManyDecks.Messages exposing (Msg(..))
import Material.Button as Button
import Material.Card as Card


decode : Json.Decoder Error
decode =
    let
        byName name =
            case name of
                "PatchTestFailed" ->
                    PatchTestFailed |> User |> Json.succeed

                "BadDeck" ->
                    BadDeck |> Application |> Json.succeed

                "BadPatch" ->
                    BadPatch |> Application |> Json.succeed

                "DeckNotFound" ->
                    DeckNotFound |> User |> Json.succeed

                "AuthFailure" ->
                    AuthFailure |> Transient |> Json.succeed

                "InternalServerError" ->
                    ServerError |> Application |> Json.succeed

                "NotAuthenticated" ->
                    NotAuthenticated |> User |> Json.succeed

                _ ->
                    Json.fail ("Unrecognised error: " ++ name)
    in
    Json.field "error" Json.string |> Json.andThen byName


view : Maybe Error -> Html Msg
view error =
    case error of
        Just e ->
            Html.div [ HtmlA.class "core-error" ]
                [ Card.view []
                    [ Html.p [] [ Html.text "Sorry, there appears to have been a problem, please try refreshing the page." ]
                    , Html.p [] [ e |> message |> Html.text ]
                    , Button.view Button.Standard Button.Padded "Dismiss" (Icon.times |> Icon.viewIcon |> Just) (ClearError |> Just)
                    ]
                ]

        Nothing ->
            Html.text ""


message : Error -> String
message error =
    case error of
        Application ae ->
            case ae of
                InvalidUrl url ->
                    "Tried to access “" ++ url ++ "” which isn't a valid URL."

                BadResponse e ->
                    "Unable to decode the response from the server: " ++ (e |> Json.errorToString)

                BadPatch ->
                    "The patch was invalid or produced invalid data."

                BadDeck ->
                    "The deck was invalid."

                ServerError ->
                    "The server encountered an error."

        Transient te ->
            case te of
                ServerDown ->
                    "The server appears to be down."

                NetworkError ->
                    "Could not connect to the server. Please check your internet connection and try again."

                AuthFailure ->
                    "Could not authenticate you. There may be an issue with the provider, please try again."

        User ue ->
            case ue of
                DeckNotFound ->
                    "The deck you tried to access wasn't found."

                PatchTestFailed ->
                    "The change you tried to make failed because the deck had already changed, and you might overwrite changes. Please check you aren't editing from two places at once."

                NotAuthenticated ->
                    "You need to be authenticated for that, but are not, please sign in."
