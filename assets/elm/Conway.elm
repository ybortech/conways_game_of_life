module Conway exposing (..)

import Html.App as App
import Html exposing (..)
import Html.Attributes exposing (..)
import String exposing (concat)
import Array exposing (Array, toList, fromList)
import List exposing (map)
import Phoenix.Socket
import Phoenix.Channel
import Json.Encode as JE
import Json.Decode as JD exposing (..)


main : Program Never
main =
    App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias CellStatus =
    Bool


type alias Model =
    { state : Array (Array CellStatus)
    , phxSocket : Phoenix.Socket.Socket Msg
    }


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | SetBoard JE.Value
    | SetCell JE.Value


socketServer : String
socketServer =
    "ws://localhost:4000/socket/websocket"


initPhxSocket : ( Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg) )
initPhxSocket =
    let
        socket =
            Phoenix.Socket.init socketServer
                |> Phoenix.Socket.withDebug
                |> Phoenix.Socket.on "update_board" "conway:lobby" SetBoard
                |> Phoenix.Socket.on "update_cell" "conway:lobby" SetCell

        channel =
            Phoenix.Channel.init "conway:lobby"
                |> Phoenix.Channel.onJoin SetBoard
    in
        Phoenix.Socket.join channel socket


init : ( Model, Cmd Msg )
init =
    let
        ( phxSocket, phxCmd ) =
            initPhxSocket
    in
        ( { state = fromList ([ fromList ([]) ]), phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd )


type alias JoinMessage =
    { state : Array (Array CellStatus) }


boardDecoder : JD.Decoder JoinMessage
boardDecoder =
    JD.object1 JoinMessage
        ("state" := JD.array (JD.array JD.bool))


type alias CellMessage =
    { row : Int, column : Int, value : CellStatus }


cellDecoder =
    JD.object3 CellMessage
        ("row" := JD.int)
        ("column" := JD.int)
        ("value" := JD.bool)


updateCell : CellMessage -> Array (Array CellStatus) -> Array (Array CellStatus)
updateCell cellMessage state =
    case Array.get cellMessage.row state of
        Just row ->
            let
                newRow =
                    Array.set cellMessage.column cellMessage.value row
            in
                Array.set cellMessage.row newRow state

        Nothing ->
            state


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetCell raw ->
            case JD.decodeValue cellDecoder raw of
                Ok cellMessage ->
                    let
                        newState =
                            updateCell cellMessage model.state
                    in
                        ( { model | state = newState }
                        , Cmd.none
                        )

                Err error ->
                    ( model, Cmd.none )

        SetBoard raw ->
            case JD.decodeValue boardDecoder raw of
                Ok board ->
                    ( { model | state = board.state }
                    , Cmd.none
                    )

                Err error ->
                    ( model, Cmd.none )

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg


cellSize =
    14


board array =
    let
        list =
            toList (array)
    in
        table [] (List.map row list)


row array =
    let
        list =
            toList (array)
    in
        tr [] (List.map cell list)


cell status =
    td
        [ height cellSize
        , width cellSize
        , cellStyle status
        ]
        []


cellStyle status =
    style
        [ ( "border", "1px solid black" )
        , ( "backgroundColor", color status )
        ]


color status =
    case status of
        True ->
            "black"

        False ->
            "white"


view model =
    board model.state
