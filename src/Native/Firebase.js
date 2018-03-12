// TODO: Change to package name space when published
// var _futureworkz$elm_firebase$Native_Firebase = function() {
var _user$project$Native_Firebase = function() {
  // attach firebase to global window
  // so other user can use it in their ports
  window.firebase = firebase

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

  return {
    initializeApp: initializeApp
  }
}()

function fromMaybe(maybe) {
  return maybe.ctor === 'Nothing' ? null : maybe._0;
}
