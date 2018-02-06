// TODO: Change to package name space when published
// var _futureworkz$elm_firebase$Native_ElmFirebase = function() {
var _user$project$Native_Firebase = function() {
  const listeners = {}

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

  function removeListener(path) {
    const listener = listeners[path]
    if (listener) listener()
  }

  function onDocSnapshot(path, sendMsg) {
    var db = firebase.firestore()
    listeners[path] = db
      .doc(path)
      .onSnapshot(
        function (doc) {
          const documentSnapshot = {
            id: doc.id,
            data:  JSON.stringify(doc.data())
          }
          _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", documentSnapshot))
        })
  }

  function onCollectionSnapshot(queries, path, sendMsg) {
    var db = firebase.firestore()
    var query = addQueries(queries, db.collection(path))
    listeners[path] =
      query
        .onSnapshot(
          snapshot => {
            const querySnapshot = {
              changes: snapshot.docChanges.map(function(change) {
                const doc = change.doc
                const changeDoc = {
                  doc: {
                    id: doc.id,
                    data:  JSON.stringify(doc.data())
                  }
                }

                changeDoc['type_'] = {
                    ctor: 'DocumentChangeType',
                    value: change.type
                  }

                return changeDoc
                }),
              data:  snapshot.docs.map(function (doc) {
                return {
                  id: doc.id,
                  data:  JSON.stringify(doc.data())
                }
              })
            }

            _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", querySnapshot))
          })
  }

  function addQueries(queries, ref) {
    console.log(queries)
    return ref
  }

  return {
    initializeApp: initializeApp,
    removeListener: removeListener,
    onDocSnapshot: F2(onDocSnapshot),
    onCollectionSnapshot: F3(onCollectionSnapshot)
  }
}()

function fromMaybe(maybe) {
  return maybe.ctor === 'Nothing' ? null : maybe._0;
}
