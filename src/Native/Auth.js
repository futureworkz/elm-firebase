// TODO: Change to package name space when published
// var _futureworkz$elm_firebase$Native_Firebase = function() {
var _user$project$Native_Auth = function() {
  function signInWithEmailAndPassword(email, password) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth()
        .signInWithEmailAndPassword(email, password)
        .then(function(user) {
          return callback(
            _elm_lang$core$Native_Scheduler.succeed(toUserType(user))
          )
        })
        .catch(function(error) {
          return callback( _elm_lang$core$Native_Scheduler.fail(elmFirebaseError(error)))
        })
    })
  }

  function signInAndRetrieveDataWithEmailAndPassword(email, password) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth().signInAndRetrieveDataWithEmailAndPassword(email, password)
        .then(function(snapshot) {
          return callback(
            _elm_lang$core$Native_Scheduler.succeed(toUserType(snapshot.user))
          )
        })
        .catch(function(error) {
          return callback( _elm_lang$core$Native_Scheduler.fail(elmFirebaseError(error)))
        })
    })
  }

  function signInAnonymously() {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth().signInAnonymously().then(function(user) {
        return callback( _elm_lang$core$Native_Scheduler.succeed(toUserType(user)))
      }).catch(function(error) {
        // The only possible error is OperationNotAllowed which means developer
        // has not enabled anonymous sign in in Firebase Auth Console
        console.error(error)
      })
    })
  }

  function signOut() {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth().signOut().then(function() {
        return callback( _elm_lang$core$Native_Scheduler.succeed())
      }, function(error) {
        return callback( _elm_lang$core$Native_Scheduler.fail(elmFirebaseError(error)))
      })
    })
  }
  
  function sendPasswordResetEmail(email) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth()
        .sendPasswordResetEmail(email)
        .then(function(_) {
          return callback( _elm_lang$core$Native_Scheduler.succeed())
        })
        .catch(function(error) {
          return callback( _elm_lang$core$Native_Scheduler.fail(elmFirebaseError(error)))
        })
    })
  }
  
  function updatePassword(password) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth().currentUser.updatePassword(password)
        .then(function(_) {
          return callback( _elm_lang$core$Native_Scheduler.succeed())
        })
        .catch(function(error) {
          return callback( _elm_lang$core$Native_Scheduler.fail(elmFirebaseError(error)))
        })
    })
  }
  
  function updateProfile(displayName, photoURL) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth().currentUser.updateProfile({
          displayName: displayName,
          photoURL: photoURL
        })
        .then(function(_) {
          return callback( _elm_lang$core$Native_Scheduler.succeed())
        })
        .catch(function(error) {
          return callback( _elm_lang$core$Native_Scheduler.fail(elmFirebaseError(error)))
        })
    })
  }

  function createUserWithEmailAndPassword(email, password) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth().createUserWithEmailAndPassword(email, password)
        .then(function(data){
          return callback( _elm_lang$core$Native_Scheduler.succeed(toUserType(data.user)))
        })
        .catch(function(error) {
          return callback( _elm_lang$core$Native_Scheduler.fail(elmFirebaseError(error)))
        })
    })
  }

  function sendEmailVerification() {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth().currentUser.sendEmailVerification()
        .then(function() {
          return callback( _elm_lang$core$Native_Scheduler.succeed())
        })
        .catch(function(error) {
          return callback( _elm_lang$core$Native_Scheduler.fail(elmFirebaseError(error)))
        })
    })
  }

  function currentUser() {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      // firebase.auth().currentUser returns null if auth is not initialised
      // See: https://firebase.google.com/docs/auth/web/manage-users
      const unsubscribe = firebase.auth().onAuthStateChanged(function(user) {
        if (user) {
          const justUser = {
            ctor: 'Just',
            _0: toUserType(user)
          }
          callback( _elm_lang$core$Native_Scheduler.succeed(justUser))
        } else {
          callback( _elm_lang$core$Native_Scheduler.succeed({ ctor: 'Nothing' }))
        }

        unsubscribe()
      })
    })
  }

  var unsubscribeAuth = null
  function onAuthStateChanged(sendMsg) {
    if (unsubscribeAuth) unsubscribeAuth()

    // TODO: Prevent first fired - Iker need to do
    unsubscribeAuth = firebase.auth().onAuthStateChanged(function(data) {
      if (data) {
        _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", _elm_lang$core$Maybe$Just(toUserType(data))))
      } else {
        _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", _elm_lang$core$Maybe$Nothing))
      }
    })
  }

  function toUserType(data) {
    return { 
      displayName: data.displayName,
      uid: data.uid,
      email: data.email,
      emailVerified: data.emailVerified,
      photoURL: data.photoURL,
      isAnonymous: data.isAnonymous
    }
  }

  function deleteAuthUser() {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth().currentUser.delete()
        .then(function(_) {
          return callback( _elm_lang$core$Native_Scheduler.succeed())
        })
        .catch(function(error) {
          return callback( _elm_lang$core$Native_Scheduler.fail(elmFirebaseError(error)))
        })
    })
  }

  return {
    signInWithEmailAndPassword: F2(signInWithEmailAndPassword),
    signInAndRetrieveDataWithEmailAndPassword: F2(signInAndRetrieveDataWithEmailAndPassword),
    signInAnonymously: signInAnonymously,
    signOut: signOut,
    sendPasswordResetEmail: sendPasswordResetEmail,
    updatePassword: updatePassword,
    updateProfile: F2(updateProfile),
    createUserWithEmailAndPassword: F2(createUserWithEmailAndPassword),
    sendEmailVerification: sendEmailVerification,
    currentUser: currentUser,
    onAuthStateChanged: onAuthStateChanged,
    deleteAuthUser: deleteAuthUser
  }
}()

function elmFirebaseError(error) {
  var firebaseErrorCode = function() {
    switch (error.code) {
      case "auth/invalid-email":
        return "InvalidEmail"
      case "auth/user-disabled":
        return "UserDisabled"
      case "auth/user-not-found":
        return "UserNotFound"
      case "auth/wrong-password":
        return "WrongPassword"
      case "auth/missing-android-pkg-name":
        return "MissingAndroidPkgName"
      case "auth/missing-continue-uri":
        return "MissingContinueUri"
      case "auth/missing-ios-bundle-id":
        return "MissingIosBundleID"
      case "auth/invalid-continue-uri":
        return "InvalidContinueUri"
      case "auth/unauthorized-continue-uri":
        return "UnauthorizedContinueUri"
      case "auth/weak-password":
        return "WeakPassword"
      case "auth/requires-recent-login":
        return "RequiresRecentLogin"
      case "auth/email-already-in-use":
        return "EmailAlreadyInUse"
      case "auth/operation-not-allowed":
        return "OperationNotAllowed"

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
