module ManyDecks exposing (..)

import Browser
import Browser.Navigation as Navigation
import Cards.Deck as FileDeck
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import FontAwesome.Styles as Icon
import Html
import Html.Attributes as HtmlA
import Json.Decode as Json
import ManyDecks.Auth as Auth exposing (Auth)
import ManyDecks.Auth.Google as Google
import ManyDecks.Deck as Deck
import ManyDecks.Error as Error
import ManyDecks.Error.Model as Error exposing (Error)
import ManyDecks.Messages exposing (..)
import ManyDecks.Model exposing (..)
import ManyDecks.Pages.Decks as Decks
import ManyDecks.Pages.Decks.Browse as Browse
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
    { auth : Maybe Json.Value }


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
        auth =
            flags.auth |> Maybe.andThen (Json.decodeValue Auth.decoder >> Result.toMaybe)

        model =
            { navKey = key
            , route = Route.fromUrl url
            , origin = { url | path = "", query = Nothing, fragment = Nothing } |> Url.toString
            , error = Nothing
            , auth = auth
            , authMethods = Nothing
            , usernameField = auth |> Maybe.map .name |> Maybe.withDefault ""
            , decks = Nothing
            , profileDeletionEnabled = False
            , edit = Nothing
            , browse = Nothing
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

                Ok (Err _) ->
                    Error.AuthFailure |> Error.Transient |> SetError

                Err error ->
                    error |> Error.BadResponse |> Error.Application |> SetError

        json5DecodedToMessage value =
            case model.auth of
                Just a ->
                    case value |> Json.decodeValue FileDeck.decode of
                        Ok fileDeck ->
                            fileDeck |> Deck.fromFileDeck a |> Decks.NewDeck |> DecksMsg

                        Err error ->
                            error |> Error.BadResponse |> Error.Application |> SetError

                _ ->
                    NoOp

        edit =
            case model.route of
                Decks (DecksRoute.Edit code) ->
                    model.edit |> Maybe.map (Edit.subscriptions code) |> Maybe.withDefault Sub.none

                _ ->
                    Sub.none
    in
    Sub.batch
        [ Ports.googleAuthResult googleAuthResultToMessage
        , Ports.json5Decoded json5DecodedToMessage
        , edit
        ]


onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest request =
    case request of
        Browser.Internal url ->
            LoadLink url

        Browser.External _ ->
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
            ( model, Route.redirectTo model.navKey route )

        LoadLink url ->
            ( model, url |> Url.toString |> Navigation.load )

        SetError error ->
            case error of
                Error.Transient Error.AuthFailure ->
                    ( { model | auth = Nothing }
                    , Cmd.batch
                        [ Ports.storeAuth Nothing
                        , Route.redirectTo model.navKey (Login Nothing)
                        ]
                    )

                Error.User Error.NotAuthenticated ->
                    ( { model | auth = Nothing }
                    , Cmd.batch
                        [ Ports.storeAuth Nothing
                        , Route.redirectTo model.navKey (Login Nothing)
                        ]
                    )

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

        Copy id ->
            ( model, Ports.copy id )

        NoOp ->
            ( model, Cmd.none )

        BrowseMsg browseMsg ->
            Browse.update browseMsg model


view : Model -> Browser.Document Msg
view model =
    let
        error =
            Error.view model.error

        body =
            case model.route of
                Login _ ->
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
    let
        title =
            Html.h1 [] [ Icon.boxOpen |> Icon.viewIcon, Html.text " Many Decks" ]

        changePageIfNot page =
            if model.route == page then
                Nothing

            else
                page |> ChangePage |> Just

        publicDecks =
            Button.view Button.Standard
                Button.Padded
                "Decks"
                (Icon.search |> Icon.viewIcon |> Just)
                (DecksRoute.Browse 1 Nothing |> Decks |> changePageIfNot)

        parts =
            case model.auth of
                Just auth ->
                    [ publicDecks
                    , title
                    , Html.div []
                        [ Button.view Button.Standard
                            Button.Padded
                            "My Decks"
                            (Icon.list |> Icon.viewIcon |> Just)
                            (auth.id |> DecksRoute.List |> Decks |> changePageIfNot)
                        , Button.view Button.Standard
                            Button.Padded
                            "Profile"
                            (Icon.userCircle |> Icon.viewIcon |> Just)
                            (Profile |> changePageIfNot)
                        , Button.view Button.Standard
                            Button.Padded
                            "Sign Out"
                            (Icon.signOutAlt |> Icon.viewIcon |> Just)
                            (Login.SignOut |> LoginMsg |> Just)
                        ]
                    ]

                Nothing ->
                    [ publicDecks
                    , title
                    , Button.view Button.Standard
                        Button.Padded
                        "Sign In"
                        (Icon.signInAlt |> Icon.viewIcon |> Just)
                        (Login Nothing |> changePageIfNot)
                    ]
    in
    Html.nav [] parts
