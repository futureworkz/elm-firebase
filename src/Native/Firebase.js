// TODO: Change to package name space when published
// var _futureworkz$elm_firebase$Native_Firebase = function() {
var _user$project$Native_Firebase = function() {
  function initializeApp(config) {
    firebase.initializeApp({
      apiKey: config.apiKey,
      projectId: config.projectId,
      authDomain: fromMaybe(config.authDomain),
      databaseURL: fromMaybe(config.databaseURL),
      storageBucket: fromMaybe(config.storageBucket),
      messagingSenderId: fromMaybe(config.messagingSenderId),
    })
  }

  let unsubscribeAuth = null
  function onAuthStateChanged(sendMsg) {
    if (unsubscribeAuth) unsubscribeAuth()

    // TODO: This function is not triggering
    // Steven thinks it could be because of the different firebase app initialization
    unsubscribeAuth = firebase.auth().onAuthStateChanged(user => {
      if (user) {
        console.log("Fire sendToSelf with user")
        _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", _elm_lang$core$Maybe$Just(user)))
      } else {
        console.log("Fire sendToSelf with nothing")
        _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", _elm_lang$core$Maybe$Nothing ))
      }
    })
  }

  return {
    initializeApp: initializeApp,
    onAuthStateChanged: onAuthStateChanged
  }
}()

function fromMaybe(maybe) {
  return maybe.ctor === 'Nothing' ? null : maybe._0;
}
