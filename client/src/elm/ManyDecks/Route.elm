module ManyDecks.Route exposing
    ( fromUrl
    , onRouteChanged
    , redirectTo
    , toUrl
    )

import Browser.Navigation as Navigation
import ManyDecks.Api as Api
import ManyDecks.Messages exposing (Msg(..))
import ManyDecks.Model exposing (..)
import ManyDecks.Pages.Decks.Messages as Decks
import ManyDecks.Pages.Decks.Route as Decks
import ManyDecks.Pages.Login.Messages as Login
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
        Login ->
            case model.auth of
                Just _ ->
                    ( model, redirectTo (Decks Decks.List) model.navKey )

                Nothing ->
                    ( model, Api.getAuthMethods (Login.ReceiveMethods >> LoginMsg) )

        Profile ->
            case model.auth of
                Just _ ->
                    ( model, Cmd.none )

                Nothing ->
                    ( model, redirectTo Login model.navKey )

        Decks decksRoute ->
            case decksRoute of
                Decks.List ->
                    case model.auth of
                        Just auth ->
                            ( model, Api.getDecks auth.token (Decks.ReceiveDecks >> DecksMsg) )

                        Nothing ->
                            ( model, redirectTo Login model.navKey )

                Decks.Edit code ->
                    ( model, Api.getDeck code (\deck -> Decks.EditDeck code (Just deck) |> DecksMsg) )

        NotFound _ ->
            ( model, Cmd.none )


redirectTo : Route -> Navigation.Key -> Cmd Msg
redirectTo route navKey =
    route |> toUrl |> Navigation.pushUrl navKey


toUrl : Route -> String
toUrl route =
    case route of
        Login ->
            Url.absolute [] []

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
        [ top |> map Login
        , s "profile" |> map Profile
        , s "decks" </> Decks.parser |> map Decks
        ]
