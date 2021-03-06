// TODO: Change to package name space when published
// var _futureworkz$elm_firebase$Native_FireStore = function() {
var _user$project$Native_FireStore = function() {
  // -- Doc functions
  function get(path) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(
      function(callback) {
        var db = firebase.firestore()

        try {
          db.doc(path)
            .get()
            .then(function(doc) {
              if (doc.exists) {
                return callback(_elm_lang$core$Native_Scheduler.succeed(
                  elmDocSnapshot(doc)
                ))
              } else {
                return callback(_elm_lang$core$Native_Scheduler.fail(
                  elmFireStoreError({
                    code: "doc-not-found"
                  })
                ))
              }
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
    )
  }

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
    )
  }

  function delete_(path) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(
      function(callback) {
        var db = firebase.firestore()

        try {
          db.doc(path)
            .delete()
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
  function getCollection(queries, path) {
    var db = firebase.firestore()
    var query = addQueries(queries.table, db.collection(path))
    return _elm_lang$core$Native_Scheduler.nativeBinding(
      function(callback) {
        try {
          query
            .get()
            .then(function(querySnapshot) {
              const docs = []
              querySnapshot.forEach(function(doc) {
                docs.push(elmDocSnapshot(doc))
              })
              return callback(_elm_lang$core$Native_Scheduler.succeed(
                _elm_lang$core$Native_List.fromArray(docs)
              ))
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

  function add(data, path) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(
      function(callback) {
        var db = firebase.firestore()
        data = replaceSpecialPlaceHolder(JSON.parse(data))

        try {
          db.collection(path)
            .add(data) // add may throw an exception "invalid-argument" instead of rejecting
            .then(function(docRef) {
              return callback(_elm_lang$core$Native_Scheduler.succeed(docRef.id))
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

  // -- Subscriptions functions
  var listeners = {}

  function removeListener(listenerID) {
    const listener = listeners[listenerID]
    if (listener) {
      listener()
      delete listeners[listenerID]
    }
  }

  function onDocSnapshot(listenerID, path, sendMsg) {
    var db = firebase.firestore()
    listeners[listenerID] = db
      .doc(path)
      .onSnapshot(
        function(doc) {
          _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", elmDocSnapshot(doc)))
        })
  }

  function onCollectionSnapshot(listenerID, queries, path, sendMsg) {
    onCollectionSnapshotWithOptions(listenerID, queries, {
      includeMetadataChanges: false
    }, path, sendMsg)
  }

  function onCollectionSnapshotWithOptions(listenerID, queries, options, path, sendMsg) {
    var db = firebase.firestore()
    var query = addQueries(queries.table, db.collection(path))
    listeners[listenerID] =
      query
      .onSnapshot(options, function(snapshot) {
        const querySnapshot = {
          docs: _elm_lang$core$Native_List.fromArray(
            snapshot.docs.map(elmDocSnapshot)
          ),

          changes: _elm_lang$core$Native_List.fromArray(
            snapshot.docChanges().map(function(change) {
              const type = change.type
              const documentChangeType = type[0].toUpperCase() + type.slice(1)

              return {
                type_: {
                  ctor: documentChangeType
                },
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

    if (typeof Proxy === 'function') {
      // Monkey patch docID function to get path IDs
      var oldDocID = _user$project$Firebase_FireStore$docID
      _user$project$Firebase_FireStore$docID = F2(
        function(id, collection) {
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

      // Collect the path
      fields(schemaProxy)

      // Release the memory
      _user$project$Firebase_FireStore$docID = oldDocID
    } else {
      // Proxy is not supported
      // Note that we are only targetting PhantomJS in this method
      // so that Google Indexing will work
  
      // Monkey patch docID function to get path IDs
      var oldDocID = _user$project$Firebase_FireStore$docID
      _user$project$Firebase_FireStore$docID = F2(
        function(id, collection) {
          return collection[id]
        }
      )

      path = getPathViaTryCatch(undefined, [], fields, 0)

      // Release the memory
      _user$project$Firebase_FireStore$docID = oldDocID
    }

    return path
  }

  function getPathViaTryCatch(obj, paths, fields) {
    try {
      fields(obj)
    } catch (error) {
      // Extract the path fragment from the error message
      const regExp = /\'([^)]+)\'/
      const pathFragment = regExp.exec(error.message)[1]

      // creates a new object with a structure as per the paths
      // so that we can call fields again on the obj and get the next error
      var newObj = {}
      paths.slice(0).reverse().forEach(function(field) {
        newObj[field] = newObj
      })

      // saves our new-found field in the paths
      paths.push(pathFragment)

      // recurse to get the next error with the newObj
      return getPathViaTryCatch(newObj, paths, fields)
    }

    return paths.join('/')
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
    getCollection: F2(getCollection),
    get: get,
    set: F2(set),
    add: F2(add),
    update: F2(update),
    delete_: delete_,
    batchAndCommit: batchAndCommit,
    removeListener: removeListener,
    onDocSnapshot: F3(onDocSnapshot),
    onCollectionSnapshot: F4(onCollectionSnapshot),
    onCollectionSnapshotWithOptions: F5(onCollectionSnapshotWithOptions),
    pathString: pathString,
    generateID: generateID
  }
}()

function elmDocSnapshot(doc) {
  const convertedData = convertFirebaseTimestampToDate(doc.data())

  return {
    id: doc.id,
    data: JSON.stringify(convertedData),
    metadata: doc.metadata
  }
}

// Since Firebase 5, Date is now stored as a Firebase Timestamp object
// We convert it into JS Date for consistency
function convertFirebaseTimestampToDate(docData) {
  Object.keys(docData || {}).forEach(function(fieldName) {
    const value = docData[fieldName]
    // typeof null is an object!!!!!
    if (value != null && typeof value == "object" && typeof value.toDate == "function") {
      docData[fieldName] = value.toDate()
    } else {
      if (value != null && typeof value == "object" && Object.keys(value).length > 0){
        convertFirebaseTimestampToDate(value)
      }
    }
  })
  
  return docData
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
      case "doc-not-found":
        return "DocumentNotFound"

      default:
        return "UndocumentedErrorByElmFirebase"
    }
  }()

  return {
    ctor: "FireStoreError",
    _0: {
      ctor: fireStoreErrorCode
    },
    _1: error.message
  }
}

function replaceSpecialPlaceHolder(data) {
  if (typeof data === 'object') {
    Object.keys(data).forEach(function(key) {
      var value = data[key]
      if (typeof value === 'string') {
        if (value === 'ELM-FIREBASE::ENCODED-SERVER-TIME-STAMP') {
          data[key] = firebase.firestore.FieldValue.serverTimestamp()
        } else if (value.startsWith('ELM-FIREBASE::ENCODED-DATE|')) {
          data[key] = new Date(parseInt(value.split('|')[1]))
        }
      } else if (typeof data[key] === 'object') {
        data[key] = replaceSpecialPlaceHolder(data[key])
      } else {
        // do nothing
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

  switch (query.ctor) {
    case "Where":
      ref = ref.where(query._0, opString(query._1.ctor), query._2)
      break

    case "WhereDate":
      ref = ref.where(query._0, opString(query._1.ctor), query._2)
      break
    
    case "WhereBool":
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
  switch (op) {
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
    case "ArrayContains":
      return "array-contains"
  }
}

function directionString(direction) {
  switch (direction) {
    case "Asc":
      return "asc"
    case "Desc":
      return "desc"
  }
}
