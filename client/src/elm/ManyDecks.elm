module ManyDecks exposing (..)

import Browser
import Browser.Navigation as Navigation
import Cards.Deck as Deck
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import FontAwesome.Styles as Icon
import Html
import Html.Attributes as HtmlA
import Json.Decode as Json
import ManyDecks.Auth exposing (Auth)
import ManyDecks.Auth.Google as Google
import ManyDecks.Error as Error
import ManyDecks.Error.Model as Error exposing (Error)
import ManyDecks.Messages exposing (..)
import ManyDecks.Model exposing (..)
import ManyDecks.Pages.Decks as Decks
import ManyDecks.Pages.Decks.Edit as Edit
import ManyDecks.Pages.Decks.Messages as Decks
import ManyDecks.Pages.Decks.Route as DecksRoute
import ManyDecks.Pages.Login as Login
import ManyDecks.Pages.Login.Messages as Login
import ManyDecks.Pages.NotFound as NotFound
import ManyDecks.Pages.Profile as Profile
import ManyDecks.Ports as Ports
import ManyDecks.Route as Route
import Material.Button as Button
import Url exposing (Url)


type alias Flags =
    { auth : Maybe Auth }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        }


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        model =
            { navKey = key
            , route = Route.fromUrl url
            , error = Nothing
            , auth = flags.auth
            , authMethods = Nothing
            , usernameField = flags.auth |> Maybe.map .name |> Maybe.withDefault ""
            , decks = Nothing
            , profileDeletionEnabled = False
            , edit = Nothing
            }
    in
    Route.onRouteChanged model.route model


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        googleAuthResultToMessage value =
            case value |> Json.decodeValue Google.authResult of
                Ok (Ok code) ->
                    code |> Login.GoogleAuthResult |> LoginMsg

                Ok (Err error) ->
                    Error.AuthFailure |> Error.Transient |> SetError

                Err error ->
                    error |> Error.BadResponse |> Error.Application |> SetError

        json5DecodedToMessage value =
            case value |> Json.decodeValue Deck.decode of
                Ok deck ->
                    deck |> Decks.NewDeck |> DecksMsg

                Err error ->
                    error |> Error.BadResponse |> Error.Application |> SetError
    in
    Sub.batch
        [ Ports.googleAuthResult googleAuthResultToMessage
        , Ports.json5Decoded json5DecodedToMessage
        , model.edit |> Maybe.map Edit.subscriptions |> Maybe.withDefault Sub.none
        ]


onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest _ =
    NoOp


onUrlChange : Url -> Msg
onUrlChange url =
    url |> Route.fromUrl |> OnRouteChanged


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnRouteChanged newRoute ->
            Route.onRouteChanged newRoute model

        ChangePage route ->
            ( model, Route.redirectTo route model.navKey )

        SetError error ->
            case error of
                Error.Transient Error.AuthFailure ->
                    ( { model | auth = Nothing }, Route.redirectTo Login model.navKey )

                Error.User Error.NotAuthenticated ->
                    ( { model | auth = Nothing }, Route.redirectTo Login model.navKey )

                _ ->
                    ( { model | error = Just error }, Cmd.none )

        ClearError ->
            ( { model | error = Nothing }, Cmd.none )

        LoginMsg loginMsg ->
            Login.update loginMsg model

        DecksMsg decksMsg ->
            Decks.update decksMsg model

        ProfileMsg profileMsg ->
            Profile.update profileMsg model

        EditMsg editMsg ->
            case model.edit of
                Just e ->
                    let
                        ( newE, cmd ) =
                            Edit.update editMsg e
                    in
                    ( { model | edit = Just newE }, cmd )

                Nothing ->
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    let
        error =
            Error.view model.error

        body =
            case model.route of
                Login ->
                    Login.view model

                Profile ->
                    Profile.view model

                Decks route ->
                    Decks.view route model

                NotFound requested ->
                    NotFound.view requested model
    in
    { title = "Many Decks"
    , body =
        [ Icon.css
        , error
        , generalNav model
        , Html.div [ HtmlA.class "content" ] body
        ]
    }


generalNav model =
    case model.auth of
        Just auth ->
            let
                viewProfile =
                    if model.route == Profile then
                        ChangePage (Decks DecksRoute.List)

                    else
                        ChangePage Profile
            in
            Html.nav []
                [ Html.div [ HtmlA.id "sign-out" ]
                    [ Button.view Button.Standard
                        Button.Padded
                        "Sign Out"
                        (Icon.signOutAlt |> Icon.viewIcon |> Just)
                        (Login.SignOut |> LoginMsg |> Just)
                    ]
                , Html.div [ HtmlA.id "view-profile" ]
                    [ Button.view Button.Standard
                        Button.Padded
                        (auth.name ++ "'s Profile")
                        (Icon.userCircle |> Icon.viewIcon |> Just)
                        (Just viewProfile)
                    ]
                ]

        Nothing ->
            Html.text ""
