module Firebase exposing (..)

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


initializeApp : Config -> App
initializeApp config =
    Native.Firebase.initializeApp config
