module ManyDecks.Pages.Decks.Edit.LanguageSelector exposing
    ( Model
    , Msg
    , SubTag
    , Tag
    , decodeExpanded
    , init
    , subscriptions
    , update
    , value
    , view
    )

import FontAwesome.Icon as Icon
import FontAwesome.Solid as Icon
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Html.Keyed as HtmlK
import Json.Decode as Json
import Json.Decode.Pipeline as Json
import ManyDecks.Ports as Ports
import Material.IconButton as IconButton
import Material.TextField as TextField


type SubTag
    = Language SubTagDetails
    | Region SubTagDetails


decodeSubTagConstructor : Json.Decoder (SubTagDetails -> SubTag)
decodeSubTagConstructor =
    let
        byName name =
            case name of
                "language" ->
                    Json.succeed Language

                "region" ->
                    Json.succeed Region

                _ ->
                    Json.fail "Unknown tag type."
    in
    Json.string |> Json.andThen byName


type alias SubTagDetails =
    { code : String
    , description : String
    }


decodeSubTag : Json.Decoder SubTag
decodeSubTag =
    let
        construct constructor =
            Json.succeed (\c d -> SubTagDetails c d |> constructor)
                |> Json.required "code" Json.string
                |> Json.required "description" Json.string
    in
    Json.field "type" decodeSubTagConstructor |> Json.andThen construct


decodeExpanded : List Json.Value -> Tag
decodeExpanded values =
    values
        |> List.filterMap (Json.decodeValue decodeSubTag >> Result.toMaybe)
        |> List.foldl set { language = Nothing, region = Nothing }


type alias Tag =
    { language : Maybe SubTagDetails
    , region : Maybe SubTagDetails
    }


placeholder : String -> Tag
placeholder code =
    case code |> String.split "-" of
        lang :: region :: _ ->
            Tag (Just { code = lang, description = "" }) (Just { code = region, description = "" })

        lang :: _ ->
            Tag (Just { code = lang, description = "" }) Nothing

        _ ->
            Tag Nothing Nothing


type alias Model =
    { search : String
    , results : List SubTag
    , selected : Tag
    }


type Msg
    = UpdateSearch String
    | UpdateResults (List SubTag)
    | Select SubTag
    | Remove SubTag
    | GetExpanded Tag


init : Maybe String -> ( Model, Cmd msg )
init code =
    let
        ( selected, cmd ) =
            case code of
                Just c ->
                    ( placeholder c, Ports.languageExpand c )

                Nothing ->
                    ( Tag Nothing Nothing, Cmd.none )
    in
    ( { search = ""
      , results = []
      , selected = selected
      }
    , cmd
    )


value : Model -> Maybe String
value { selected } =
    case selected.language of
        Just lang ->
            let
                region =
                    case selected.region of
                        Just { code } ->
                            "-" ++ code

                        Nothing ->
                            ""
            in
            lang.code ++ region |> Just

        Nothing ->
            Nothing


subscriptions : (Json.Error -> msg) -> (Msg -> msg) -> Sub msg
subscriptions handleError wrap =
    let
        handleInbound result =
            case result of
                Ok results ->
                    results |> UpdateResults |> wrap

                Err error ->
                    handleError error
    in
    Sub.batch
        [ Ports.languageResults (Json.decodeValue (Json.list decodeSubTag) >> handleInbound)
        , Ports.languageExpanded (decodeExpanded >> GetExpanded >> wrap)
        ]


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        UpdateSearch search ->
            ( { model | search = search }, Ports.languageSearch search )

        UpdateResults results ->
            ( { model | results = results }, Cmd.none )

        Select subTag ->
            ( { model | selected = model.selected |> set subTag, search = "", results = [] }, Cmd.none )

        Remove subTag ->
            ( { model | selected = model.selected |> remove subTag }, Cmd.none )

        GetExpanded selected ->
            ( { model | selected = selected }, Cmd.none )


view : (Msg -> msg) -> Model -> Html msg
view wrap { search, results, selected } =
    let
        removeButton subTag =
            IconButton.view (Icon.timesCircle |> Icon.viewIcon) "Remove" (subTag |> Remove |> wrap |> Just)

        viewResult tag =
            ( tag |> subTagDetails |> .code
            , Html.li [ tag |> Select |> wrap |> HtmlE.onClick ] [ viewSubTag (Html.text "" |> always) tag ]
            )

        subTags =
            [ selected.language |> Maybe.map Language
            , selected.region |> Maybe.map Region
            ]

        editor =
            (subTags |> (removeButton |> viewSubTag |> Maybe.map |> List.filterMap))
                ++ [ TextField.view "Language" TextField.Search search (UpdateSearch >> wrap |> Just) ]
    in
    Html.div [ HtmlA.class "language-selector" ]
        [ Html.div [ HtmlA.class "sub-tags editor" ] editor
        , Html.div [ HtmlA.class "scroll" ]
            [ results |> List.map viewResult |> HtmlK.ol [ HtmlA.class "sub-tags search-results" ] ]
        ]


set : SubTag -> Tag -> Tag
set subTag selected =
    case subTag of
        Language details ->
            { selected | language = Just details }

        Region details ->
            { selected | region = Just details }


remove : SubTag -> Tag -> Tag
remove subTag selected =
    case subTag of
        Language details ->
            if selected.language == Just details then
                { selected | language = Nothing }

            else
                selected

        Region details ->
            if selected.region == Just details then
                { selected | region = Nothing }

            else
                selected


subTagDetails : SubTag -> SubTagDetails
subTagDetails subTag =
    case subTag of
        Language details ->
            details

        Region details ->
            details


viewSubTag : (SubTag -> Html msg) -> SubTag -> Html msg
viewSubTag action subTag =
    let
        ( subtagType, icon, { code, description } ) =
            case subTag of
                Language details ->
                    ( "language", Icon.language, details )

                Region details ->
                    ( "region", Icon.flag, details )
    in
    Html.span [ HtmlA.class "sub-tag", HtmlA.class subtagType ]
        [ icon |> Icon.viewIcon
        , description |> Html.text
        , Html.span [ HtmlA.class "code" ] [ Html.text code ]
        , action subTag
        ]
