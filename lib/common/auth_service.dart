import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_twitter_login/flutter_twitter_login.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;

  // Initialize GoogleSignIn with the scopes you want:
  final GoogleSignIn googleSignIn = GoogleSignIn(
    signInOption: SignInOption.standard,
    scopes: [
      'email',
      // 'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );
  final FacebookAuth facebookSignIn = FacebookAuth.instance;

  AuthenticationService(this._firebaseAuth);

  Stream<User> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<String> signUp({@required String email, @required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      return "";
    } on FirebaseAuthException catch (e) {
      return getSignUpErrorMessage(e.code);
    }
  }

  Future<String> signIn({@required String email, @required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return "";
    } on FirebaseAuthException catch (e) {
      return getSignInErrorMessage(e.code);
    }
  }

  Future<void> signInWithGoogle() async {
    // процесс входа в гугл акк на web и мобилках разный
    if (kIsWeb) {
      // Create a new provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
      googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

      // Once signed in, return the UserCredential
      await _firebaseAuth.signInWithPopup(googleProvider);

      // Or use signInWithRedirect
      // await _firebaseAuth.signInWithRedirect(googleProvider);
    } else {
      final GoogleSignInAccount googleUser = await googleSignIn.signIn();
      // Trigger the authentication flow

      if (googleUser != null) {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Once signed in, return the UserCredential
        await _firebaseAuth.signInWithCredential(credential);
      }
    }
  }

  Future<void> signInWithFacebook() async {
    if (kIsWeb) {
      // Create a new provider
      FacebookAuthProvider facebookProvider = FacebookAuthProvider();

      facebookProvider.addScope('email');
      facebookProvider.setCustomParameters({
        'display': 'popup',
      });

      // Once signed in, return the UserCredential
      await _firebaseAuth.signInWithPopup(facebookProvider);

      // Or use signInWithRedirect
      // return await _firebaseAuth.signInWithRedirect(facebookProvider);
    } else {
      // Trigger the sign-in flow
      final LoginResult result = await facebookSignIn.login();

      if (result.status == LoginStatus.success) {
        // Create a credential from the access token
        final facebookAuthCredential = FacebookAuthProvider.credential(result.accessToken.token);
        // Once signed in, return the UserCredential
        await _firebaseAuth.signInWithCredential(facebookAuthCredential);
      }
    }
  }

  Future<void> signInWithTwitter() async {
    if (kIsWeb) {
      // Create a new provider
      TwitterAuthProvider twitterProvider = TwitterAuthProvider();

      // Once signed in, return the UserCredential
      await _firebaseAuth.signInWithPopup(twitterProvider);

      // Or use signInWithRedirect
      //  await _firebaseAuth.signInWithRedirect(twitterProvider);
    } else {
      // Create a TwitterLogin instance
      final TwitterLogin twitterLogin = new TwitterLogin(
        consumerKey: '<your consumer key>',
        consumerSecret: ' <your consumer secret>',
      );

      // Trigger the sign-in flow
      final TwitterLoginResult loginResult = await twitterLogin.authorize();

      // Get the Logged In session
      final TwitterSession twitterSession = loginResult.session;

      // Create a credential from the access token
      final twitterAuthCredential = TwitterAuthProvider.credential(
        accessToken: twitterSession.token,
        secret: twitterSession.secret,
      );

      // Once signed in, return the UserCredential
      await _firebaseAuth.signInWithCredential(twitterAuthCredential);
    }
  }

  Future<void> signOut() async {
    await facebookSignIn.logOut();
    await googleSignIn.disconnect();
    await _firebaseAuth.signOut();
  }
}
