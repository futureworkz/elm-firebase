effect module Firebase.Auth
    where { subscription = SubMsg }
    exposing
        ( signInWithEmailAndPassword
        , signInAndRetrieveDataWithEmailAndPassword
        , signOut
        , sendPasswordResetEmail
        , updatePassword
        , updateProfile
        , createUserWithEmailAndPassword
        , sendEmailVerification
        , onAuthStateChanged
        , User
        , Error(Error)
        , ErrorCode(..)
        )

import Native.Auth
import Task exposing (Task)


type Error
    = Error ErrorCode String


type ErrorCode
    = InvalidEmail
    | UserDisabled
    | UserNotFound
    | WrongPassword
    | MissingAndroidPkgName
    | MissingContinueUri
    | MissingIosBundleID
    | InvalidContinueUri
    | UnauthorizedContinueUri
    | WeakPassword
    | RequiresRecentLogin
    | EmailAlreadyInUse
    | OperationNotAllowed
    | UndocumentedErrorByElmFirebase


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


type alias Password =
    String


type alias DisplayName =
    String


type alias PhotoURL =
    String


signInWithEmailAndPassword : Email -> Password -> Task Error User
signInWithEmailAndPassword email password =
    Native.Auth.signInWithEmailAndPassword email password


signInAndRetrieveDataWithEmailAndPassword : Email -> Password -> Task Error User
signInAndRetrieveDataWithEmailAndPassword email password =
    Native.Auth.signInAndRetrieveDataWithEmailAndPassword email password


signOut : Task Error ()
signOut =
    Native.Auth.signOut ()


sendPasswordResetEmail : Email -> Task Error ()
sendPasswordResetEmail email =
    Native.Auth.sendPasswordResetEmail email


updatePassword : Password -> Task Error ()
updatePassword password =
    Native.Auth.updatePassword password


updateProfile : DisplayName -> PhotoURL -> Task Error ()
updateProfile displayName photoURL =
    Native.Auth.updateProfile displayName photoURL


createUserWithEmailAndPassword : Email -> Password -> Task Error User
createUserWithEmailAndPassword email password =
    Native.Auth.createUserWithEmailAndPassword email password


sendEmailVerification : Task Error ()
sendEmailVerification =
    Native.Auth.sendEmailVerification ()



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
