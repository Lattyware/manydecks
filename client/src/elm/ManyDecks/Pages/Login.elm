module ManyDecks.Pages.Login exposing
    ( update
    , view
    )

import Browser.Navigation as Navigation
import FontAwesome.Brands as Icon
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import ManyDecks.Api as Api
import ManyDecks.Auth as Auth
import ManyDecks.Auth.Google as Google
import ManyDecks.Auth.Guest as Guest
import ManyDecks.Auth.Methods as Auth
import ManyDecks.Auth.Twitch as Twitch
import ManyDecks.Messages as Global
import ManyDecks.Meta as Meta
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

        TryTwitchSignIn method ->
            ( model, method |> Twitch.requestUrl model.origin |> Navigation.load )

        SetAuth auth ->
            ( { model | auth = Just auth, usernameField = auth.name }
            , Cmd.batch
                [ auth |> Just |> Auth.store
                , Route.redirectTo model.navKey (auth.id |> Decks.List |> Decks)
                ]
            )

        SignOut ->
            ( { model | auth = Nothing }
            , Cmd.batch
                [ Ports.storeAuth Nothing
                , Route.redirectTo model.navKey (Login Nothing)
                ]
            )


view : Model -> List (Html Global.Msg)
view model =
    [ Card.view [ HtmlA.class "page log-in" ]
        [ Html.h1 [] [ Icon.boxOpen |> Icon.viewIcon, Html.text "Many Decks" ]
        , Html.span [ HtmlA.class "version" ] [ Html.text "alpha" ]
        , Html.p []
            [ Html.text "Create decks for "
            , Html.a [ HtmlA.target "_blank", HtmlA.href Meta.massiveDecksUrl ] [ Html.text "Massive Decks" ]
            , Html.text "."
            ]
        , Html.p []
            [ Html.text "This is a very early version, produced quickly in response to Cardcast's demise, there will "
            , Html.text "likely be bugs. Please report any you find "
            , Html.a [ HtmlA.target "_blank", HtmlA.href Meta.issuesUrl ]
                [ Html.text "on GitHub" ]
            ]
        , Html.p []
            [ Html.text "Currently the data for this service is not backed up! Please keep local copies of your "
            , Html.text "decks as well, just in case something goes wrong."
            ]
        , Html.div [ HtmlA.class "methods" ] (model.authMethods |> Maybe.map viewMethods |> Maybe.withDefault [])
        ]
    , Html.div [ HtmlA.id "project-link" ]
        [ Html.a [ HtmlA.target "_blank", Meta.projectUrl |> HtmlA.href ]
            [ Icon.boxOpen |> Icon.viewIcon, Html.text " on ", Icon.github |> Icon.viewIcon ]
        ]
    ]


viewMethods : Auth.Methods -> List (Html Global.Msg)
viewMethods methods =
    List.filterMap identity
        [ methods.google |> Maybe.map google
        , methods.twitch |> Maybe.map twitch
        , methods.guest |> Maybe.map guest
        ]


google : Google.Method -> Html Global.Msg
google method =
    Html.div [ HtmlA.id "google-sign-in" ]
        [ Button.view Button.Raised
            Button.Padded
            "Sign in with Google"
            (Icon.google |> Icon.viewIcon |> Just)
            (method |> TryGoogleSignIn |> Global.LoginMsg |> Just)
        ]


twitch : Twitch.Method -> Html Global.Msg
twitch method =
    Html.div [ HtmlA.id "twitch-sign-in" ]
        [ Button.view Button.Raised
            Button.Padded
            "Sign in with Twitch"
            (Icon.twitch |> Icon.viewIcon |> Just)
            (method |> TryTwitchSignIn |> Global.LoginMsg |> Just)
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
