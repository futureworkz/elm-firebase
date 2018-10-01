// TODO: Change to package name space when published
// var _futureworkz$elm_firebase$Native_Firebase = function() {
var _user$project$Native_Firebase = function() {
  function initializeApp(config) {
    _initializeFirebaseApp(config)
  }

  function initializeAppWithPersistence(config) {
    _initializeFirebaseApp(config)

    return _elm_lang$core$Native_Scheduler.nativeBinding(
      function(callback) {
        firebase.firestore().enablePersistence()
          .then(function() {
            return callback(_elm_lang$core$Native_Scheduler.succeed())
          })
          .catch(function(err) {
            return callback(_elm_lang$core$Native_Scheduler.fail(elmFirebaseError(error)))
          })
      }
    )
  }

  function _initializeFirebaseApp(config) {
    firebase.initializeApp({
      apiKey: config.apiKey,
      projectId: config.projectId,
      authDomain: fromMaybe(config.authDomain),
      databaseURL: fromMaybe(config.databaseURL),
      storageBucket: fromMaybe(config.storageBucket),
      messagingSenderId: fromMaybe(config.messagingSenderId),
    })

    // Must be enabled in firebase 5
    firebase.firestore().settings({ timestampsInSnapshots: true })
  }

  return {
    initializeApp: initializeApp,
    initializeAppWithPersistence: initializeAppWithPersistence
  }
}()

function fromMaybe(maybe) {
  return maybe.ctor === 'Nothing' ? null : maybe._0;
}

function elmFirebaseError(error) {
  var firebaseErrorCode = function() {
    switch (error.code) {
      case "failed-precondition":
        // Multiple tabs open, persistence can only be enabled in one tab at a a time...
        return "FailedPrecondition"
      case "unimplemented":
        // The current browser does not support all of the features required to enable persistence
        return "Unimplemented"

      default: 
        return "UndocumentedErrorByElmFirebase"
    }
  }()

  return {
    ctor: "FirebaseError",
    _0 : { ctor: firebaseErrorCode },
    _1 : error.message
  }
}
