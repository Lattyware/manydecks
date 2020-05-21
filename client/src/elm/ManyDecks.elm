module ManyDecks exposing (..)

import Browser
import Browser.Navigation as Navigation
import Cards.Deck as Deck
import File
import File.Download as File
import File.Select as File
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import FontAwesome.Styles as Icon
import Html
import Html.Attributes as HtmlA
import Http
import Json.Decode as Json
import ManyDecks.Auth exposing (Auth)
import ManyDecks.Error as Error exposing (Error)
import ManyDecks.Google as Google
import ManyDecks.Messages exposing (Msg(..))
import ManyDecks.Pages.Decks as Decks
import ManyDecks.Pages.Decks.Model as Decks
import ManyDecks.Pages.Edit as Edit
import ManyDecks.Pages.Edit.Model as Edit
import ManyDecks.Pages.Login as Login
import ManyDecks.Pages.Profile as Profile
import ManyDecks.Pages.Profile.Model as Profile
import ManyDecks.Ports as Ports
import Material.Button as Button
import Task
import Url exposing (Url)


type alias Flags =
    { auth : Maybe Auth }


type alias Model =
    { core : Maybe CoreModel
    , error : Maybe Error
    }


type alias CoreModel =
    { auth : Auth
    , decks : Maybe (List Decks.CodeAndSummary)
    , profile : Profile.Model
    , edit : Maybe Edit.Model
    }


initCore auth =
    { auth = auth, decks = Nothing, profile = Profile.init auth, edit = Nothing }


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
    ( { core = flags.auth |> Maybe.map initCore, error = Nothing }
    , case flags.auth of
        Just auth ->
            Decks.getDecks auth.token decksFromResult

        Nothing ->
            Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        googleAuthResultToMessage value =
            case value |> Json.decodeValue Google.authResult of
                Ok (Ok code) ->
                    GoogleAuthResult code

                Ok (Err error) ->
                    error |> Error

                Err error ->
                    error |> Json.errorToString |> Error

        json5DecodedToMessage value =
            case value |> Json.decodeValue Deck.decode of
                Ok deck ->
                    NewDeck deck

                Err error ->
                    error |> Json.errorToString |> Error
    in
    Sub.batch
        [ Ports.googleAuthResult googleAuthResultToMessage
        , Ports.json5Decoded json5DecodedToMessage
        , model.core |> Maybe.andThen .edit |> Maybe.map (Edit.subscriptions EditMsg) |> Maybe.withDefault Sub.none
        ]


onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest urlRequest =
    NoOp


onUrlChange : Url -> Msg
onUrlChange url =
    NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetError error ->
            ( { model | error = Just error }, Cmd.none )

        TryGoogleAuth ->
            ( model, Ports.tryGoogleAuth () )

        GoogleAuthResult code ->
            let
                authFromGoogleCode result =
                    case result of
                        Ok token ->
                            MdAuthResult token

                        Err error ->
                            error |> Error.Http |> SetError
            in
            ( model, Google.signIn code authFromGoogleCode )

        MdAuthResult auth ->
            ( { model | core = auth |> initCore |> Just }
            , Cmd.batch
                [ Decks.getDecks auth.token decksFromResult
                , auth |> Just |> Ports.storeAuth
                ]
            )

        ReceiveDecks decks ->
            let
                add m =
                    { m | decks = Just decks }
            in
            ( { model | core = model.core |> Maybe.map add }, Cmd.none )

        UploadDeck ->
            ( model, File.file [ ".deck.json5" ] UploadedDeck )

        UploadedDeck file ->
            ( model, file |> File.toString |> Task.perform Json5Parse )

        Json5Parse raw ->
            ( model, Ports.json5Decode raw )

        NewDeck d ->
            let
                token =
                    model.core |> Maybe.map (.auth >> .token) |> Maybe.withDefault ""

                newDeck result =
                    case result of
                        Ok code ->
                            EditDeck code (Just d) True

                        Err error ->
                            error |> Error.Http |> SetError
            in
            ( model, Decks.createDeck token d newDeck )

        EditDeck code deck needsToBeAdded ->
            case deck of
                Just d ->
                    case model.core of
                        Just m ->
                            let
                                decks =
                                    if needsToBeAdded then
                                        let
                                            summary =
                                                { details =
                                                    { name = d.name
                                                    , author = d.author |> Maybe.withDefault m.auth.name
                                                    , language = d.language
                                                    }
                                                , calls = d.calls |> List.length
                                                , responses = d.responses |> List.length
                                                , version = 0
                                                }
                                        in
                                        m.decks |> Maybe.map (\ds -> ds ++ [ { code = code, summary = summary } ])

                                    else
                                        m.decks
                            in
                            ( { model | core = Just { m | edit = Edit.init code d |> Just, decks = decks } }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    let
                        handle result =
                            case result of
                                Ok d ->
                                    EditDeck code (Just d) needsToBeAdded

                                Err error ->
                                    error |> Error.Http |> SetError
                    in
                    ( model, Decks.getDeck code handle )

        BackFromEdit ->
            case model.core of
                Just m ->
                    ( { model | core = Just { m | edit = Nothing } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        Delete code ->
            case model.core of
                Just m ->
                    let
                        newDecks =
                            m.decks |> Maybe.map (List.filter (\d -> d.code /= code))
                    in
                    ( { model | core = Just { m | decks = newDecks, edit = Nothing } }
                    , Decks.deleteDeck m.auth.token code
                    )

                Nothing ->
                    ( model, Cmd.none )

        Save code patch ->
            case model.core of
                Just m ->
                    let
                        handle result =
                            case result of
                                Ok () ->
                                    BackFromEdit

                                Err error ->
                                    error |> Error.Http |> SetError
                    in
                    ( model, Decks.save m.auth.token code patch handle )

                Nothing ->
                    ( model, Cmd.none )

        Copy id ->
            ( model, Ports.copy id )

        ProfileMsg profileMsg ->
            case model.core of
                Just m ->
                    let
                        ( newP, cmd ) =
                            m.profile |> Profile.update SignOut UpdateAuth ProfileMsg m.auth.token profileMsg
                    in
                    ( { model | core = Just { m | profile = newP } }, cmd )

                Nothing ->
                    ( model, Cmd.none )

        EditMsg editMsg ->
            case model.core of
                Just m ->
                    case m.edit of
                        Just e ->
                            let
                                ( newE, cmd ) =
                                    Edit.update editMsg e
                            in
                            ( { model | core = Just { m | edit = Just newE } }, cmd )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        Backup ->
            let
                handleResult result =
                    case result of
                        Ok file ->
                            DownloadBytes file

                        Err error ->
                            error |> Error.Http |> SetError

                cmd =
                    model.core |> Maybe.map (\m -> Decks.backup m.auth.token handleResult) |> Maybe.withDefault Cmd.none
            in
            ( model, cmd )

        DownloadBytes bytes ->
            ( model, File.bytes "backup.zip" "application/zip" bytes )

        UpdateAuth newAuth ->
            case model.core of
                Just m ->
                    ( { model | core = Just { m | auth = newAuth } }, newAuth |> Just |> Ports.storeAuth )

                Nothing ->
                    ( model, Cmd.none )

        SignOut ->
            ( { model | core = Nothing }, Ports.storeAuth Nothing )

        Error _ ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    let
        error =
            Error.view model.error

        body =
            case model.core of
                Nothing ->
                    [ Html.div [ HtmlA.class "content" ] [ Login.view ] ]

                Just m ->
                    let
                        content =
                            if m.profile.viewing then
                                Profile.view ProfileMsg Backup m.auth m.profile

                            else
                                case m.edit of
                                    Just edit ->
                                        Edit.view BackFromEdit Save Delete EditMsg edit

                                    Nothing ->
                                        Decks.view m.decks
                    in
                    [ generalNav m
                    , Html.div [ HtmlA.class "content" ] content
                    ]
    in
    { title = "Many Decks"
    , body = Icon.css :: error :: body
    }


generalNav model =
    let
        viewProfile =
            model.profile.viewing |> not |> Profile.SetViewingProfile |> ProfileMsg
    in
    Html.nav []
        [ Html.div [ HtmlA.id "sign-out" ]
            [ Button.view Button.Standard
                Button.Padded
                "Sign Out"
                (Icon.signOutAlt |> Icon.viewIcon |> Just)
                (Just SignOut)
            ]
        , Html.div [ HtmlA.id "view-profile" ]
            [ Button.view Button.Standard
                Button.Padded
                (model.auth.name ++ "'s Profile")
                (Icon.userCircle |> Icon.viewIcon |> Just)
                (Just viewProfile)
            ]
        ]


decksFromResult : Result Http.Error (List Decks.CodeAndSummary) -> Msg
decksFromResult result =
    case result of
        Ok token ->
            ReceiveDecks token

        Err error ->
            error |> Error.Http |> SetError
