effect module Firebase.Auth
    where { subscription = SubMsg }
    exposing
        ( logIn
        , logOut
        , forgetPassword
        , updatePassword
        , register
        , onAuthStateChanged
        , User
        , ResponseError
        )

import Native.Auth
import Task exposing (Task)


type alias ResponseError =
    { code : String
    , message : String
    }


type alias LoginParams =
    { email : String
    , password : String
    }


type alias UpdatePasswordParams =
    { oldPassword : String
    , newPassword : String
    }


type alias RegisterParams =
    { displayName : String
    , email : Email
    , photoURL : String
    , password : String
    }


type alias User =
    { displayName : String
    , uid : String
    , email : Email
    , emailVerified : Bool
    , photoURL : String
    , isAnonymous : Bool
    }


type alias Email =
    String


logIn : LoginParams -> Task ResponseError User
logIn params =
    Native.Auth.logIn params


logOut : Task ResponseError ()
logOut =
    Native.Auth.logOut ()


forgetPassword : Email -> Task ResponseError ()
forgetPassword email =
    Native.Auth.forgetPassword email


updatePassword : UpdatePasswordParams -> Task ResponseError ()
updatePassword params =
    Native.Auth.updatePassword params


register : RegisterParams -> Task ResponseError User
register params =
    Native.Auth.register params



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
                listener =
                    \_ user ->
                        Platform.sendToSelf router (AuthStateChanged user)
            in
                Native.Auth.onAuthStateChanged listener
                    |> always (Task.succeed <| Initialized subs)

        Initialized _ ->
            Task.succeed (Initialized subs)


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router (AuthStateChanged user) state =
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
    Platform.sendToApp router (tagger user)
