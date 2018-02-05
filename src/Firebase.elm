module Firebase exposing (..)

import Native.FirebaseSDK
import Native.FireStore
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


initializeApp : Config -> App
initializeApp config =
    Native.Firebase.initializeApp config


callme : String -> String -> String -> App
callme a b c =
    Native.Firebase.callme a b c
