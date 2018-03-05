// TODO: Change to package name space when published
// var _futureworkz$elm_firebase$Native_Firebase = function() {
var _user$project$Native_Auth = function() {
  function logIn(params) {
    const email = params.email
    const password = params.password

    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth()
        .signInAndRetrieveDataWithEmailAndPassword(email, password)
        .then(function(snapshot) {
          const data = snapshot.user
          const user = dataToUser(data)
          return callback(
            _elm_lang$core$Native_Scheduler.succeed(user)
          )
        })
        .catch(function(error) {
          return callback(
            _elm_lang$core$Native_Scheduler.fail({ code: error.code, message: error.message })
          )
        })
    })
  }

  function logOut() {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth().signOut().then(function() {
        return callback(
          _elm_lang$core$Native_Scheduler.succeed()
        )
      }, function(error) {
        return callback(
          _elm_lang$core$Native_Scheduler.fail({ code: error.code, message: error.message })
        )
      })
    })
  }
  
  function forgetPassword(email) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth()
        .sendPasswordResetEmail(email)
        .then(function(_) {
          return callback(
            _elm_lang$core$Native_Scheduler.succeed()
          )
        })
        .catch(function(error) {
          return callback(
            _elm_lang$core$Native_Scheduler.fail({ code: error.code, message: error.message })
          )
        })
    })
  }
  
  function updatePassword(params) {
    const oldPassword = params.oldPassword
    const newPassword = params.newPassword

    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      const user = firebase.auth().currentUser

      if (user == null) {
        // Todo: User error like FireStore
        return callback(
          _elm_lang$core$Native_Scheduler.fail({
            code: 'auth/user-not-login',
            message: 'User is not login.'
          })
        )
      }

      const email = user.email
      firebase.auth()
        .signInAndRetrieveDataWithEmailAndPassword(email, oldPassword)
        .then(function(credential) { return credential.user })
        .then(function(user) { return user.updatePassword(newPassword) })
        .then(function(_) {
          return callback(
            _elm_lang$core$Native_Scheduler.succeed()
          )
        })
        .catch(function(error) {
          return callback(
            _elm_lang$core$Native_Scheduler.fail({ code: error.code, message: error.message })
          )
        })
    })
  }

  function register(params) {
    const displayName = params.displayName
    const email = params.email
    const password = params.password
    const photoURL = params.photoURL

    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      firebase.auth().createUserWithEmailAndPassword(email, password)
        .then(function(firebaseUser){
          return firebaseUser
            .updateProfile({ displayName: displayName, photoURL: photoURL })
            .then(_ => firebaseUser)
        })
        .then(function(data){
          const user = dataToUser(data)
          return callback(
            _elm_lang$core$Native_Scheduler.succeed(user)
          )
        })
        .catch(function(error) {
          return callback(
            _elm_lang$core$Native_Scheduler.fail({ code: error.code, message: error.message })
          )
        })
    })
  }

  let unsubscribeAuth = null
  function onAuthStateChanged(sendMsg) {
    if (unsubscribeAuth) unsubscribeAuth()

    // TODO: 
    // Prevent first fired - Iker need to do
    unsubscribeAuth = firebase.auth().onAuthStateChanged(function(data) {
      if (data) {
        const user = dataToUser(data)
        _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", _elm_lang$core$Maybe$Just(user)))
      } else {
        _elm_lang$core$Native_Scheduler.rawSpawn(A2(sendMsg, "", _elm_lang$core$Maybe$Nothing))
      }
    })
  }

  function dataToUser(data) {
    return { 
      displayName: data.displayName,
      uid: data.uid,
      email: data.email,
      emailVerified: data.emailVerified,
      photoURL: data.photoURL,
      isAnonymous: data.isAnonymous
    }
  }

  return {
    logIn: logIn,
    logOut: logOut,
    forgetPassword: forgetPassword,
    updatePassword: updatePassword,
    register: register,
    onAuthStateChanged: onAuthStateChanged
  }
}()
