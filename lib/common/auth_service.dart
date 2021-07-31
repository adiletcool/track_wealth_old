import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_login_vk/flutter_login_vk.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;

  //! Initialize GoogleSignIn with the scopes you want:
  final GoogleSignIn googleSignIn = GoogleSignIn(
    signInOption: SignInOption.standard,
    scopes: [
      'email',
      // 'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );
  //! Initialize facebook auth instance
  final FacebookAuth facebookSignIn = FacebookAuth.instance;

  //! Initialize vkontakte auth instance
  final vkSignIn = VKLogin();

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
        final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(result.accessToken.token);
        // Once signed in, return the UserCredential
        await _firebaseAuth.signInWithCredential(facebookAuthCredential);
      }
    }
  }

  Future<void> signInWithVk() async {
    await vkSignIn.initSdk('7913884'); //* инициализируем с app id

    // Запрашиваем вход и разрешение на почту
    final res = await vkSignIn.logIn(scope: [VKScope.email]);
    // Если не ошибка
    if (res.isValue) {
      // Ошибки нет, но мы еще не знаем, вошел пользователь или нет
      // Он мог отменить вход. Нужно проверить свойство isCanceled:
      final VKLoginResult loginResult = res.asValue.value;
      if (!loginResult.isCanceled) {
        final VKAccessToken accessToken = loginResult.accessToken;

        if (accessToken != null) {
          // final profileRes = await vkSignIn.getUserProfile(); // Получаем данные профиля
          // final email = await vkSignIn.getUserEmail();
          // final vkAuthCredential = OAuthCredential(
          //   providerId: 'vk.com',
          //   signInMethod: 'vk.com',
          //   accessToken: accessToken.token,
          // );
          // await _firebaseAuth.signInWithCredential(vkAuthCredential);
          // * TODO wait till firebase supports vk auth :(
          // or
          // _firebaseAuth.signInWithCustomToken(accessToken.token);
        }

        // profileRes.asValue.value.firstName;

      } else {
        print('VK sign in cancelled');
      }
    } else {
      print('Ошибка при входе: ${res.asError.error}');
    }
  }

  Future<void> signInWithPhoneNumber({
    @required BuildContext context,
    @required String phoneNumber,
    @required void Function(String verificationId, int forceResendingToken) codeSent,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 119),
      verificationCompleted: (AuthCredential creds) async {
        await _firebaseAuth.signInWithCredential(creds);
        Navigator.of(context).pop();
      },
      verificationFailed: (FirebaseAuthException exception) {
        print(exception);
      },
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    print('sent code to $phoneNumber');
  }

  Future<ConfirmationResult> webSignInWithPhoneNumber(phoneNumber) async {
    return await _firebaseAuth.signInWithPhoneNumber(phoneNumber);
  }

  Future<String> signInWithCreds(AuthCredential credential) async {
    try {
      await _firebaseAuth.signInWithCredential(credential);
      return 'Signed in';
    } on FirebaseAuthException catch (e) {
      return e.code;
    }
  }

  Future<void> signOut(User firebaseUser) async {
    List<UserInfo> providerData = firebaseUser.providerData;
    String providerId = providerData.first.providerId;

    switch (providerId) {
      case 'facebook.com':
        await facebookSignIn.logOut();
        break;
      case 'google.com':
        if (await googleSignIn.isSignedIn()) await googleSignIn.disconnect();
        break;
    }

    await _firebaseAuth.signOut();
  }
}
