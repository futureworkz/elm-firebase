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


type Msg msg
    = AuthStateChanged (Maybe User)


type alias State msg =
    List (SubMsg msg)


init : Task Never (State msg)
init =
    Task.succeed []


onAuthStateChanged : (Maybe User -> msg) -> Sub msg
onAuthStateChanged tagger =
    subscription (OnAuthStateChanged tagger)


subMap : (a -> b) -> SubMsg a -> SubMsg b
subMap func sub =
    case sub of
        OnAuthStateChanged tagger ->
            OnAuthStateChanged (tagger >> func)


onEffects : Platform.Router msg (Msg msg) -> List (SubMsg msg) -> State msg -> Task Never (State msg)
onEffects router subs state =
    case List.isEmpty state of
        True ->
            let
                listener =
                    \_ snapshot ->
                        Platform.sendToSelf router (AuthStateChanged snapshot)
            in
                Native.Firebase.onAuthStateChanged listener
                    |> always (Task.succeed subs)

        False ->
            Task.succeed subs


onSelfMsg : Platform.Router msg (Msg msg) -> Msg msg -> State msg -> Task Never (State msg)
onSelfMsg router msg state =
    case msg of
        AuthStateChanged snapshot ->
            sendUserDataToApp router snapshot state state


sendUserDataToApp : Platform.Router msg (Msg msg) -> Maybe User -> State msg -> State msg -> Task Never (State msg)
sendUserDataToApp router snapshot rest state =
    case rest of
        sub :: rest ->
            case sub of
                OnAuthStateChanged tagger ->
                    Platform.sendToApp router (tagger snapshot)
                        |> Task.andThen (always (sendUserDataToApp router snapshot rest state))

        [] ->
            Task.succeed state
