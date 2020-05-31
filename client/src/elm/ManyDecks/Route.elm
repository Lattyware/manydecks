module ManyDecks.Route exposing
    ( fromUrl
    , onRouteChanged
    , redirectTo
    , toUrl
    )

import Browser.Navigation as Navigation
import ManyDecks.Api as Api
import ManyDecks.Auth.Twitch as Twitch
import ManyDecks.Deck as Deck exposing (Deck)
import ManyDecks.Messages exposing (Msg(..))
import ManyDecks.Model exposing (..)
import ManyDecks.Pages.Decks.Browse.Messages as Browse
import ManyDecks.Pages.Decks.Browse.Model as Browse
import ManyDecks.Pages.Decks.Messages as Decks
import ManyDecks.Pages.Decks.Route as Decks
import ManyDecks.Pages.Login.Messages as Login
import Task
import Url exposing (Url)
import Url.Builder as Url
import Url.Parser exposing (..)


onRouteChanged : Route -> Model -> ( Model, Cmd Msg )
onRouteChanged route oldModel =
    let
        model =
            { oldModel | route = route }
    in
    case route of
        Login fragment ->
            case fragment of
                Just frag ->
                    let
                        parsedPayload =
                            Twitch.authPayload frag

                        signIn payload =
                            Api.signIn payload (Login.SetAuth >> LoginMsg)
                    in
                    ( model
                    , parsedPayload
                        |> Maybe.map signIn
                        |> Maybe.withDefault (Api.getAuthMethods (Login.ReceiveMethods >> LoginMsg))
                    )

                Nothing ->
                    case model.auth of
                        Just auth ->
                            ( model, redirectTo model.navKey (auth.id |> Decks.List |> Decks) )

                        Nothing ->
                            ( model, Api.getAuthMethods (Login.ReceiveMethods >> LoginMsg) )

        Profile ->
            case model.auth of
                Just _ ->
                    ( model, Cmd.none )

                Nothing ->
                    ( model, redirectTo model.navKey (Login Nothing) )

        Decks decksRoute ->
            case decksRoute of
                Decks.List id ->
                    ( model, Api.getDecks id (model.auth |> Maybe.map .token) (Decks.ReceiveDecks >> DecksMsg) )

                Decks.View code ->
                    let
                        getDeck =
                            getExistingDeck oldModel code
                                |> Maybe.map fakeApiCall
                                |> Maybe.withDefault (Api.getDeck code)
                    in
                    ( model, getDeck (\deck -> Decks.ViewDeck code (Just deck) |> DecksMsg) )

                Decks.Edit code ->
                    case model.auth of
                        Just _ ->
                            let
                                getDeck =
                                    getExistingDeck oldModel code
                                        |> Maybe.map fakeApiCall
                                        |> Maybe.withDefault (Api.getDeck code)
                            in
                            ( model, getDeck (\deck -> Decks.EditDeck code (Just deck) |> DecksMsg) )

                        Nothing ->
                            ( model, redirectTo model.navKey (Login Nothing) )

                Decks.Browse query ->
                    ( model
                    , Api.browseDecks query (Browse.Page query >> Browse.ReceiveDecks >> BrowseMsg)
                    )

        NotFound _ ->
            ( model, Cmd.none )


fakeApiCall : Deck -> (Deck -> Msg) -> Cmd Msg
fakeApiCall deck wrap =
    deck |> Task.succeed |> Task.perform wrap


getExistingDeck : Model -> Deck.Code -> Maybe Deck
getExistingDeck oldModel code =
    case oldModel.route of
        Decks (Decks.View oldCode) ->
            if oldCode == code then
                oldModel.edit |> Maybe.map .deck

            else
                Nothing

        Decks (Decks.Edit oldCode) ->
            if oldCode == code then
                oldModel.edit |> Maybe.map .deck

            else
                Nothing

        _ ->
            Nothing


redirectTo : Navigation.Key -> Route -> Cmd Msg
redirectTo navKey route =
    route |> toUrl |> Navigation.pushUrl navKey


toUrl : Route -> String
toUrl route =
    case route of
        Login _ ->
            Url.absolute [ "sign-in" ] []

        Profile ->
            Url.absolute [ "profile" ] []

        Decks decksRoute ->
            Decks.toUrl decksRoute

        NotFound requested ->
            Url.absolute [ requested ] []


fromUrl : Url -> Route
fromUrl url =
    parse parser url |> Maybe.withDefault (NotFound url.path)


parser : Parser (Route -> c) c
parser =
    oneOf
        [ top |> map (Browse.Query 1 Nothing Nothing |> Decks.Browse |> Decks)
        , s "sign-in" </> fragment Login
        , s "profile" |> map Profile
        , s "decks" </> Decks.parser |> map Decks
        ]
