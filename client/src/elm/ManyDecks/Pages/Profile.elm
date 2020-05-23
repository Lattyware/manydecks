module ManyDecks.Pages.Profile exposing
    ( update
    , view
    )

import File.Download as File
import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import ManyDecks.Api as Api
import ManyDecks.Auth as Auth exposing (Auth)
import ManyDecks.Messages as Global
import ManyDecks.Model exposing (Model, Route(..))
import ManyDecks.Pages.Profile.Messages exposing (..)
import ManyDecks.Ports as Ports
import ManyDecks.Route as Route
import Material.Button as Button
import Material.Card as Card
import Material.Switch as Switch
import Material.TextField as TextField


update : Msg -> Model -> ( Model, Cmd Global.Msg )
update msg model =
    case msg of
        SetUsername username ->
            ( { model | usernameField = username }, Cmd.none )

        SetDeletionEnabled enabled ->
            ( { model | profileDeletionEnabled = enabled }, Cmd.none )

        Save newName ->
            case model.auth of
                Just auth ->
                    ( model, Api.saveProfile auth.token newName (ProfileUpdated >> Global.ProfileMsg) )

                Nothing ->
                    ( model, Cmd.none )

        ProfileUpdated auth ->
            ( { model | auth = Just auth, usernameField = auth.name }, auth |> Just |> Ports.storeAuth )

        Delete ->
            case model.auth of
                Just auth ->
                    ( model, Api.deleteProfile auth.token (ProfileDeleted |> Global.ProfileMsg |> always) )

                Nothing ->
                    ( model, Cmd.none )

        ProfileDeleted ->
            ( { model | auth = Nothing }
            , Cmd.batch
                [ Ports.storeAuth Nothing, Route.redirectTo (Login Nothing) model.navKey ]
            )

        Backup ->
            case model.auth of
                Just auth ->
                    ( model, Api.backup auth.token (DownloadBytes >> wrap) )

                Nothing ->
                    ( model, Cmd.none )

        DownloadBytes bytes ->
            ( model, File.bytes "backup.zip" "application/zip" bytes )


view : Model -> List (Html Global.Msg)
view model =
    [ Card.view [ HtmlA.class "profile" ]
        [ editSection model
        , backupSection
        , deleteSection model
        ]
    ]


editSection : Model -> Html Global.Msg
editSection { auth, usernameField } =
    let
        title =
            Html.h2 [] [ Html.text "Profile" ]

        editName =
            TextField.view "Username" TextField.Text usernameField (SetUsername >> wrap |> Just)

        description =
            Html.p [] [ Html.text "This name will be displayed publicly as the author of any deck you create." ]

        saveAction =
            if Just usernameField /= (auth |> Maybe.map .name) then
                usernameField |> Save |> wrap |> Just

            else
                Nothing

        button =
            Button.view Button.Raised Button.Padded "Save" (Icon.save |> Icon.viewIcon |> Just) saveAction
    in
    Html.div [ HtmlA.class "edit section" ] [ title, editName, description, button ]


backupSection : Html Global.Msg
backupSection =
    let
        title =
            Html.h3 [] [ Html.text "Backup" ]

        description =
            Html.p [] [ Html.text "Download a zip archive of all of your decks." ]

        button =
            Button.view
                Button.Raised
                Button.Padded
                "Backup Decks"
                (Icon.download |> Icon.viewIcon |> Just)
                (Backup |> wrap |> Just)
    in
    Html.div [ HtmlA.class "backup section" ] [ title, description, button ]


deleteSection : Model -> Html Global.Msg
deleteSection { profileDeletionEnabled } =
    let
        title =
            Html.h3 [] [ Html.text "Deletion" ]

        warning =
            Html.p []
                [ Html.text "This will "
                , Html.strong [] [ Html.text "permanently delete" ]
                , Html.text " your profile and "
                , Html.em [] [ Html.text "all your decks" ]
                , Html.text ". Once done, there is "
                , Html.em [] [ Html.text "no way" ]
                , Html.text " to recover that data. We highly recommend you do a backup before this."
                ]

        sureSwitch =
            Switch.view
                (Html.span [] [ Html.text "I am sure that I want to permanently delete my profile and all my decks." ])
                profileDeletionEnabled
                (SetDeletionEnabled >> wrap |> Just)

        deleteAction =
            if profileDeletionEnabled then
                Delete |> wrap |> Just

            else
                Nothing

        deleteButton =
            Button.view
                Button.Unelevated
                Button.Padded
                "Delete Profile"
                (Icon.trash |> Icon.viewIcon |> Just)
                deleteAction
    in
    Html.div [ HtmlA.class "delete section" ]
        [ title, warning, sureSwitch, deleteButton ]


wrap : Msg -> Global.Msg
wrap =
    Global.ProfileMsg
