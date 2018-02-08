// TODO: Change to package name space when published
// var _futureworkz$elm_firebase$Native_FireStore = function() {
var _user$project$Native_FireStore = function() {
  const listeners = {}

  function removeListener(path) {
    path = getPathValue(path)
    const listener = listeners[path]
    if (listener) {
      listener()
      delete listeners[path]
    }
  }

  function onDocSnapshot(path, sendMsg) {
    var db = firebase.firestore()
    path = getPathValue(path)
    listeners[path] = db
      .doc(path)
      .onSnapshot(
        function (doc) {
          _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", elmDocSnapshot(doc)))
        })
  }

  function onCollectionSnapshot(queries, path, sendMsg) {
    var db = firebase.firestore()
    path = getPathValue(path)
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

  function pathString(fields) {
    /***
     * Hackish function to generate the full path based on fields
     * which is an elm piped function eg. .users >> .profiles >> docID "123" >> .username
     ***/
    var path = ""

    // Monkey patch docID function to get path IDs
    var oldDocID = _user$project$Firebase_FireStore$docID
    _user$project$Firebase_FireStore$docID = F2(
      function (id, collection) {
        if (path) {
          path = path + "/" + id
        }
        return A2(oldDocID, id, collection)
      }
    )

    // Use JS Proxy to overwrite the default get behavior of {}
    var schemaProxy = new Proxy({}, {
      get: function (func, name) {
        if (name !== '_1') { // caused by oldDocID
          path = path + "/" + name
        }
        return schemaProxy
      }
    })

    fields(schemaProxy)
    return path
  }

  return {
    removeListener: removeListener,
    onDocSnapshot: F2(onDocSnapshot),
    onCollectionSnapshot: F3(onCollectionSnapshot),
    pathString: pathString
  }
}()

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

function getPathValue(path) {
  if (path.ctor !== 'Path') {
    console.error("#getPathValue: Value is not of type Path")
  }

  return path._0
}
