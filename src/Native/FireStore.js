// TODO: Change to package name space when published
// var _futureworkz$elm_firebase$Native_FireStore = function() {
var _user$project$Native_FireStore = function() {
  // -- Doc functions
  function set(data, path) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(
      function(callback) {
        var db = firebase.firestore()
        data = replaceSpecialPlaceHolder(JSON.parse(data))

        try {
          db.doc(path)
            .set(data)
            .then(function(snapshot) {
              return callback(_elm_lang$core$Native_Scheduler.succeed())
            })
            .catch(function(error) {
              return callback(_elm_lang$core$Native_Scheduler.fail(elmFireStoreError(error)))
            })
        } catch (error) {
          return callback(_elm_lang$core$Native_Scheduler.fail(elmFireStoreError(error)))
        }
      }
    )}

  function update(data, path) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(
      function(callback) {
        var db = firebase.firestore()
        data = replaceSpecialPlaceHolder(JSON.parse(data))

        try {
          db.doc(path)
            .update(data) // add may throw an exception "invalid-argument" instead of rejecting
            .then(function() {
              return callback(_elm_lang$core$Native_Scheduler.succeed())
            })
            .catch(function(error) {
              return callback(_elm_lang$core$Native_Scheduler.fail(elmFireStoreError(error)))
            })
        } catch (error) {
          return callback(_elm_lang$core$Native_Scheduler.fail(elmFireStoreError(error)))
        }
      }
    )}

  function batchAndCommit(operations) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(
      function(callback) {
        const db = firebase.firestore()
        const batch = db.batch()

        try {
          operations.table.forEach(
            function(operation) {
              if (operation.ops === 'Set') {
                batch.set(
                  db.doc(operation.path),
                  replaceSpecialPlaceHolder(JSON.parse(operation.json))
                )
              } else if (operation.ops === 'Update') {
                batch.update(
                  db.doc(operation.path),
                  replaceSpecialPlaceHolder(JSON.parse(operation.json))
                )
              } else if (operation.ops === 'Delete') {
                batch.delete(
                  db.doc(operation.path)
                )
              } else {
                // do nothing for invalid ops
                console.error("elm-firebase: Invalid ops in batchAndCommit == " + operation.ops)
              }
            }
          )

          batch.commit()
            .then(function() {
              return callback(_elm_lang$core$Native_Scheduler.succeed())
            })
            .catch(function(error) {
              return callback(_elm_lang$core$Native_Scheduler.fail(elmFireStoreError(error)))
            })
        } catch (error) {
          return callback(_elm_lang$core$Native_Scheduler.fail(elmFireStoreError(error)))
        }
      }
    )
  }

  // -- Collection functions
  function add(data, path) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(
      function(callback) {
        var db = firebase.firestore()
        data = replaceSpecialPlaceHolder(JSON.parse(data))

        try {
          db.collection(path)
            .add(data) // add may throw an exception "invalid-argument" instead of rejecting
            .then(function(docRef) {
              const doc = {
                id: docRef.id,
                data: JSON.stringify(data)
              }
              return callback(_elm_lang$core$Native_Scheduler.succeed(doc))
            })
            .catch(function(error) {
              return callback(_elm_lang$core$Native_Scheduler.fail(elmFireStoreError(error)))
            })
        } catch (error) {
          return callback(_elm_lang$core$Native_Scheduler.fail(elmFireStoreError(error)))
        }
      }
    )}  

  // -- Subscriptions functions
  var listeners = {}

  function removeListener(path) {
    const listener = listeners[path]
    if (listener) {
      listener()
      delete listeners[path]
    }
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
          function (snapshot) {
            const querySnapshot = {
              docs: _elm_lang$core$Native_List.fromArray(
                snapshot.docs.map(elmDocSnapshot)
              ),

              changes: _elm_lang$core$Native_List.fromArray(
                snapshot.docChanges.map(function(change) {
                  const type = change.type
                  const documentChangeType = type[0].toUpperCase() + type.slice(1)

                  return {
                    type_: { ctor: documentChangeType },
                    doc: elmDocSnapshot(change.doc)
                  }
                })
              )
            }

            _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", querySnapshot))
          })
  }

  // -- Helpers
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

  function generateID() {
    return _elm_lang$core$Native_Scheduler.nativeBinding(
      function(callback) {
        const id = firebase.firestore().collection('/.SHOULD.NOT.EXISTS').doc().id
        return callback(_elm_lang$core$Native_Scheduler.succeed(id))
      }
    )
  }

  return {
    set: F2(set),
    add: F2(add),
    update: F2(update),
    batchAndCommit: batchAndCommit,
    removeListener: removeListener,
    onDocSnapshot: F2(onDocSnapshot),
    onCollectionSnapshot: F3(onCollectionSnapshot),
    pathString: pathString,
    generateID: generateID
  }
}()

function elmDocSnapshot(doc) {
  return {
    id: doc.id,
    data:  JSON.stringify(doc.data())
  }
}

function elmFireStoreError(error) {
  var fireStoreErrorCode = function() {
    switch (error.code) {
      case "cancelled":
        return "Cancelled"
      case "unknown":
        return "Unknown"
      case "invalid-argument":
        return "InvalidArgument"
      case "deadline-exceeded":
        return "DeadlineExceeded"
      case "not-found":
        return "NotFound"
      case "already-exists":
        return "AlreadyExists"
      case "permission-denied":
        return "PermissionDenied"
      case "resource-exhausted":
        return "ResourceExhausted"
      case "failed-precondition":
        return "FailedPrecondition"
      case "aborted":
        return "Aborted"
      case "out-of-range":
        return "OutOfRange"
      case "unimplemented":
        return "Unimplemented"
      case "internal":
        return "Internal"
      case "unavailable":
        return "Unavailable"
      case "data-loss":
        return "DataLoss"
      case "unauthenticated":
        return "Unauthenticated"

      default: 
        return "UndocumentedErrorByElmFirebase"
    }
  }()

  return {
    ctor: "FireStoreError",
    _0 : { ctor: fireStoreErrorCode },
    _1 : error.message
  }
}

function replaceSpecialPlaceHolder(data) {
  if (typeof data === 'object') {
    Object.keys(data).forEach(function(key) {
      if (data[key] === 'ELM-FIREBASE::ENCODED-SERVER-TIME-STAMP') {
        data[key] = firebase.firestore.FieldValue.serverTimestamp()
      } else if (typeof data[key] === 'object') {
        data[key] = replaceSpecialPlaceHolder(data[key])
      }
    })

    return data
  } else {
    return data
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
