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

  function onAuthStateChanged(sendMsg) {
    var firebaseAuth = firebase.auth()
    firebaseAuth.onAuthStateChanged(user => {
      if (user) {
        const { uid, email, emailVerified, displayName } = user
        const data = JSON.stringify({ uid, email, emailVerified, displayName })
        _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", _elm_lang$core$Maybe$Just(data)))
      } else {
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
