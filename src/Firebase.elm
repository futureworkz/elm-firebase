module Firebase exposing (..)

import Task exposing (Task)
import Native.SDK.Firebase
import Native.SDK.FireStore
import Native.Firebase


type alias Config =
    { apiKey : String
    , projectId : String
    , authDomain : Maybe String
    , databaseURL : Maybe String
    , storageBucket : Maybe String
    , messagingSenderId : Maybe String
    }


type App
    = App


type Error
    = Error ErrorCode String


type ErrorCode
    = FailedPrecondition
    | Unimplemented
    | UndocumentedErrorByElmFirebase


initializeApp : Config -> App
initializeApp config =
    Native.Firebase.initializeApp config


initializeAppWithPersistence : Config -> Task Error App
initializeAppWithPersistence config =
    Native.Firebase.initializeAppWithPersistence config
