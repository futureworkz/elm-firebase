effect module Firebase.Auth
    where { subscription = CreateSubMsg }
    exposing
        ( onAuthStateChanged
        , User
        )

import Task exposing (Task)


type alias User =
    JsonString


type alias JsonString =
    String



-- Create Subscriptions


onAuthStateChanged : (Maybe User -> msg) -> Sub msg
onAuthStateChanged tagger =
    subscription (OnAuthStateChanged "authStateChanged" tagger)


type CreateSubMsg msg
    = OnAuthStateChanged Event (Maybe User -> msg)


type Msg msg
    = AuthStateChanged (Maybe User -> msg) (Maybe User)


type alias State =
    List Event


type alias Event =
    String


init : Task Never State
init =
    Task.succeed []


subMap : (a -> b) -> CreateSubMsg a -> CreateSubMsg b
subMap func sub =
    case sub of
        OnAuthStateChanged event tagger ->
            OnAuthStateChanged event (tagger >> func)


onEffects : Platform.Router msg (Msg msg) -> List (CreateSubMsg msg) -> State -> Task Never State
onEffects router subs state =
    case subs of
        sub :: rest ->
            createSub router sub state
                |> Task.andThen (onEffects router rest)

        [] ->
            Task.succeed state


onSelfMsg : Platform.Router msg (Msg msg) -> Msg msg -> State -> Task Never State
onSelfMsg router msg state =
    case msg of
        AuthStateChanged tagger snapshot ->
            Platform.sendToApp router (tagger snapshot)
                |> Task.andThen (always (Task.succeed state))


createSub : Platform.Router msg (Msg msg) -> CreateSubMsg msg -> State -> Task Never State
createSub router sub state =
    case sub of
        OnAuthStateChanged event tagger ->
            case List.member event state of
                True ->
                    Task.succeed state

                False ->
                    let
                        listener =
                            \_ snapshot ->
                                Platform.sendToSelf router (AuthStateChanged tagger snapshot)

                        newState =
                            event :: state
                    in
                        Native.Firebase.onAuthStateChanged listener
                            |> always (Task.succeed newState)
