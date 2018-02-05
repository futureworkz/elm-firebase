// TODO: Change to package name space when published
// var _futureworkz$elm_firebase$Native_ElmFirebase = function() {
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

  function onSnapshot(ref, send) {
    var db = firebase.firestore()
    var path = ref._0
    db
      .doc(path)
      .onSnapshot(
        doc => {
          const elmSnapshot = {
            id: doc.id,
            data:  doc.data()
          }
          _elm_lang$core$Native_Scheduler.rawSpawn(A2(send, "", elmSnapshot))
        })
  }

  return {
    initializeApp: initializeApp,
    onSnapshot: F2(onSnapshot)
  }
}()

function fromMaybe(maybe) {
  return maybe.ctor === 'Nothing' ? null : maybe._0;
}
