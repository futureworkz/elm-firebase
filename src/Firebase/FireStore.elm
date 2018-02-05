effect module Firebase.FireStore where { subscription = MySub } exposing (..)

import Task exposing (Task)
import Native.Firebase


type Reference
    = Reference String


type alias Snapshot =
    { id : String
    , data : String
    }


document : String -> Reference
document location =
    Reference location


onSnapshot : (Snapshot -> msg) -> Reference -> Sub msg
onSnapshot tagger ref =
    subscription (OnSnapshotSub ref tagger)



-- Managing effects


type MySub msg
    = OnSnapshotSub Reference (Snapshot -> msg)


type Msg
    = OnSnapshot Snapshot


type alias State msg =
    List (MySub msg)


init : Task Never (State msg)
init =
    Task.succeed []


subMap : (a -> b) -> MySub a -> MySub b
subMap func sub =
    case sub of
        OnSnapshotSub ref tagger ->
            OnSnapshotSub ref (tagger >> func)


onEffects : Platform.Router msg Msg -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router newSubs oldState =
    case ( oldState, newSubs ) of
        ( [], subs ) ->
            -- only handle one sub for now
            setupSnapshots router newSubs
                |> \_ -> Task.succeed (oldState ++ newSubs)

        ( _, _ ) ->
            Task.succeed oldState


setupSnapshots router newSubs =
    case newSubs of
        sub :: rest ->
            setupSnapshot router sub
                |> always (sub :: setupSnapshots router rest)

        [] ->
            []


setupSnapshot router sub =
    case sub of
        OnSnapshotSub ref tagger ->
            Native.Firebase.onSnapshot ref <|
                \_ snapshot -> Platform.sendToSelf router (OnSnapshot snapshot)


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router msg state =
    case msg of
        OnSnapshot snapshot ->
            state
                |> List.map
                    (\msg ->
                        case msg of
                            OnSnapshotSub _ tagger ->
                                Platform.sendToApp router (tagger snapshot)
                    )
                |> Task.sequence
                |> Task.andThen (always (Task.succeed state))
