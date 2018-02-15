effect module Firebase.Auth
    where { subscription = SubMsg }
    exposing
        ( onAuthStateChanged
        , User
        )

import Task exposing (Task)


type alias User =
    { displayName : String
    , uid : String
    , email : String
    , emailVerified : Bool
    , photoURL : String
    , isAnonymous : Bool
    }



-- Create Subscriptions


type SubMsg msg
    = OnAuthStateChanged (Maybe User -> msg)


type Msg
    = AuthStateChanged (Maybe User)


type State msg
    = Uninitialized
    | Initialized (List (SubMsg msg))


init : Task Never (State msg)
init =
    Task.succeed Uninitialized


onAuthStateChanged : (Maybe User -> msg) -> Sub msg
onAuthStateChanged tagger =
    subscription (OnAuthStateChanged tagger)


subMap : (a -> b) -> SubMsg a -> SubMsg b
subMap func (OnAuthStateChanged tagger) =
    OnAuthStateChanged (tagger >> func)


onEffects : Platform.Router msg Msg -> List (SubMsg msg) -> State msg -> Task Never (State msg)
onEffects router subs state =
    case state of
        Uninitialized ->
            let
                _ =
                    Debug.log "onEffects Uninitialized" subs

                listener =
                    \_ user ->
                        Platform.sendToSelf router (AuthStateChanged user)
            in
                Native.Firebase.onAuthStateChanged listener
                    |> always (Task.succeed <| Initialized subs)

        Initialized _ ->
            let
                _ =
                    Debug.log "onEffects Initialized" subs
            in
                Task.succeed (Initialized subs)


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router (AuthStateChanged user) state =
    let
        _ =
            Debug.log "onSelfMsg" state
    in
        case state of
            Uninitialized ->
                Task.succeed state

            Initialized subs ->
                List.map (sendUserDataToApp router user) subs
                    |> Task.sequence
                    |> Task.andThen (always <| Task.succeed state)


sendUserDataToApp : Platform.Router msg Msg -> Maybe User -> SubMsg msg -> Task x ()
sendUserDataToApp router user (OnAuthStateChanged tagger) =
    -- Platform.sendToApp will trigger onEffects again
    let
        _ =
            Debug.log "sendUserDataToApp" tagger
    in
        Platform.sendToApp router (tagger user)
