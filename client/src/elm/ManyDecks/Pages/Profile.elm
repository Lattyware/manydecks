module ManyDecks.Pages.Profile exposing
    ( update
    , view
    )

import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Http
import Json.Encode
import ManyDecks.Auth as Auth exposing (Auth)
import ManyDecks.Pages.Profile.Model exposing (..)
import Material.Button as Button
import Material.Card as Card
import Material.Switch as Switch
import Material.TextField as TextField


update : msg -> (Auth -> msg) -> (Msg -> msg) -> String -> Msg -> Model -> ( Model, Cmd msg )
update signOut updateAuth wrap token msg model =
    case msg of
        SetUsername username ->
            ( { model | name = username }, Cmd.none )

        SetViewingProfile viewing ->
            ( { model | viewing = viewing }, Cmd.none )

        SetDeletionEnabled enabled ->
            ( { model | deletionEnabled = enabled }, Cmd.none )

        Save newName ->
            let
                handle result =
                    case result of
                        Ok newAuth ->
                            updateAuth newAuth

                        Err error ->
                            Error error |> wrap
            in
            ( model, save token newName handle )

        Delete ->
            ( model, delete signOut token )

        Error error ->
            ( model, Cmd.none )


view : (Msg -> msg) -> msg -> Auth -> Model -> List (Html msg)
view wrap backup auth model =
    [ Card.view [ HtmlA.class "profile" ]
        [ editSection wrap auth model
        , backupSection backup
        , deleteSection wrap model
        ]
    ]


editSection : (Msg -> msg) -> Auth -> Model -> Html msg
editSection wrap auth { name } =
    let
        title =
            Html.h2 [] [ Html.text "Profile" ]

        editName =
            TextField.view "Username" TextField.Text name (SetUsername >> wrap |> Just)

        description =
            Html.p [] [ Html.text "This name will be displayed publicly as the author of any deck you create." ]

        saveAction =
            if name /= auth.name then
                name |> Save |> wrap |> Just

            else
                Nothing

        button =
            Button.view Button.Raised Button.Padded "Save" (Icon.save |> Icon.viewIcon |> Just) saveAction
    in
    Html.div [ HtmlA.class "edit section" ] [ title, editName, description, button ]


backupSection : msg -> Html msg
backupSection backup =
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
                (backup |> Just)
    in
    Html.div [ HtmlA.class "backup section" ] [ title, description, button ]


deleteSection : (Msg -> msg) -> Model -> Html msg
deleteSection wrap { deletionEnabled } =
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
                deletionEnabled
                (SetDeletionEnabled >> wrap |> Just)

        deleteAction =
            if deletionEnabled then
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


save : String -> String -> (Result Http.Error Auth.Auth -> msg) -> Cmd msg
save token name toMsg =
    Http.post
        { url = "/api/users"
        , body =
            [ ( "token", token |> Json.Encode.string )
            , ( "name", name |> Json.Encode.string )
            ]
                |> Json.Encode.object
                |> Http.jsonBody
        , expect = Http.expectJson toMsg Auth.decoder
        }


delete : msg -> String -> Cmd msg
delete signOut token =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = "/api/users"
        , body = [ ( "token", token |> Json.Encode.string ) ] |> Json.Encode.object |> Http.jsonBody
        , expect = Http.expectWhatever (always signOut)
        , timeout = Nothing
        , tracker = Nothing
        }
