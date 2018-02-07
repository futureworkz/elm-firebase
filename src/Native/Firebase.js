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
          _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", elmDocSnapshot(doc)))
        })
  }

  function onCollectionSnapshot(queries, path, sendMsg) {
    var db = firebase.firestore()
    var query = addQueries(queries.table, db.collection(path))
    listeners[path] =
      query
        .onSnapshot(
          snapshot => {
            const querySnapshot = {
              docs: _elm_lang$core$Native_List.fromArray(
                snapshot.docs.map(elmDocSnapshot)
              ),

              changes: _elm_lang$core$Native_List.fromArray(
                snapshot.docChanges.map(function(change) {
                  const changeDoc = {
                    doc: elmDocSnapshot(change.doc)
                  }

                  changeDoc['type_'] = {
                      ctor: 'DocumentChangeType',
                      value: change.type
                    }

                  return changeDoc
                })
              )
            }

            _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", querySnapshot))
          })
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

function elmDocSnapshot(doc) {
  return {
    id: doc.id,
    data:  JSON.stringify(doc.data())
  }
}

function addQueries(queries, ref) {
  if (queries.length === 0) {
    return ref
  }

  const query = queries[0]

  switch(query.ctor) {
    case "Where":
      ref = ref.where(query._0, opString(query._1.ctor), query._2)
      break

    case "Limit":
      ref = ref.limit(query._0)
      break

    case "OrderBy":
      ref = ref.orderBy(query._0, directionString(query._1.ctor))
      break
  }

  return addQueries(queries.splice(1), ref)
}

function opString(op) {
  switch(op) {
    case "Gt":
      return ">"
    case "Gte":
      return ">="
    case "Eq":
      return "=="
    case "Lt":
      return "<"
    case "Lte":
      return "<="
  }
}

function directionString(direction) {
  switch(direction) {
    case "Asc":
      return "asc"
    case "Desc":
      return "Desc"
  }
}
