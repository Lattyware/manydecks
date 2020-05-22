module ManyDecks.Pages.Login exposing
    ( update
    , view
    )

import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import ManyDecks.Api as Api
import ManyDecks.Auth.Google as Google
import ManyDecks.Auth.Guest as Guest
import ManyDecks.Auth.Methods as Auth
import ManyDecks.Messages as Global
import ManyDecks.Model exposing (Model, Route(..))
import ManyDecks.Pages.Decks.Route as Decks
import ManyDecks.Pages.Login.Messages exposing (..)
import ManyDecks.Ports as Ports
import ManyDecks.Route as Route
import Material.Button as Button
import Material.Card as Card


update : Msg -> Model -> ( Model, Cmd Global.Msg )
update msg model =
    case msg of
        ReceiveMethods methods ->
            ( { model | authMethods = Just methods }, Cmd.none )

        TryGoogleSignIn method ->
            ( model, Ports.tryGoogleAuth method.id )

        GoogleAuthResult code ->
            ( model, Api.signIn (Google.authPayload code) (SetAuth >> Global.LoginMsg) )

        TryGuestSignIn _ ->
            ( model, Api.signIn Guest.authPayload (SetAuth >> Global.LoginMsg) )

        SetAuth auth ->
            ( { model | auth = Just auth, usernameField = auth.name }
            , Cmd.batch
                [ auth |> Just |> Ports.storeAuth
                , Route.redirectTo (Decks Decks.List) model.navKey
                ]
            )

        SignOut ->
            ( { model | auth = Nothing }, Route.redirectTo Login model.navKey )


view : Model -> List (Html Global.Msg)
view model =
    [ Card.view [ HtmlA.class "log-in" ]
        [ Html.h1 [] [ Icon.boxOpen |> Icon.viewIcon, Html.text "Many Decks" ]
        , Html.span [ HtmlA.class "version" ] [ Html.text "alpha" ]
        , Html.p []
            [ Html.text "Create decks for "
            , Html.a [ HtmlA.target "_blank", HtmlA.href "https://md.rereadgames.com" ] [ Html.text "Massive Decks" ]
            , Html.text "."
            ]
        , Html.p []
            [ Html.text "This is a very early version, produced quickly in response to Cardcast's demise, there will "
            , Html.text "likely be bugs. Please report any you find "
            , Html.a [ HtmlA.target "_blank", HtmlA.href "https://github.com/Lattyware/manydecks" ]
                [ Html.text "on GitHub" ]
            ]
        , Html.p []
            [ Html.text "Currently the data for this service is not backed up! Please keep local copies of your "
            , Html.text "decks as well, just in case something goes wrong."
            ]
        , Html.div [] (model.authMethods |> Maybe.map viewMethods |> Maybe.withDefault [])
        ]
    ]


viewMethods : Auth.Methods -> List (Html Global.Msg)
viewMethods methods =
    List.filterMap identity
        [ methods.google |> Maybe.map google
        , methods.guest |> Maybe.map guest
        ]


google : Google.Method -> Html Global.Msg
google method =
    Html.div [ HtmlA.id "google-sign-in" ]
        [ Button.view Button.Raised
            Button.Padded
            "Sign in with Google"
            (Html.div [ HtmlA.class "google-icon" ] [] |> Just)
            (method |> TryGoogleSignIn |> Global.LoginMsg |> Just)
        ]


guest : Guest.Method -> Html Global.Msg
guest method =
    Html.div [ HtmlA.id "guest-sign-in" ]
        [ Button.view Button.Raised
            Button.Padded
            "Sign in as a Guest"
            (Icon.userSecret |> Icon.viewIcon |> Just)
            (method |> TryGuestSignIn |> Global.LoginMsg |> Just)
        ]
