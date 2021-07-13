import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

enum SignInMethod {
  Twitter,
  Password,
  EmailLink,
  Facebook,
  Github,
  Google,
  Phone,
}

abstract class BaseAuth {
  Stream<User?> get userChanges;

  Future<User?> getUser();
  Future<UserCredential> signIn(String email, String password);
  Future<UserCredential> anonymousSignIn();
  Future<UserCredential> signUp(String email, String password);
  Future<void> changeEmail(String email);
  Future<bool> checkEmailExists(String email);
  Future<List<SignInMethod>> getSignInMethodsForEmail(String email);
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<UserCredential> setPhoneNumber(
      String phoneNumber, Future<String> Function()? getCode);
  Future<AuthCredential> verifyPhoneNumber(
      String phoneNumber, Future<String> Function() getCode);
}

class SimpleAuth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static final _signInMethods = {
    TwitterAuthProvider.TWITTER_SIGN_IN_METHOD: SignInMethod.Twitter,
    EmailAuthProvider.EMAIL_LINK_SIGN_IN_METHOD: SignInMethod.EmailLink,
    EmailAuthProvider.EMAIL_PASSWORD_SIGN_IN_METHOD: SignInMethod.Password,
    FacebookAuthProvider.FACEBOOK_SIGN_IN_METHOD: SignInMethod.Facebook,
    GithubAuthProvider.GITHUB_SIGN_IN_METHOD: SignInMethod.Github,
    GoogleAuthProvider.GOOGLE_SIGN_IN_METHOD: SignInMethod.Google,
    PhoneAuthProvider.PHONE_SIGN_IN_METHOD: SignInMethod.Phone,
  };

  @override
  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  @override
  Future<UserCredential> signUp(String email, String password) async {
    final user = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    await user.user!.sendEmailVerification();
    return user;
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    return signIn(_firebaseAuth.currentUser!.email!, oldPassword)
        .then((value) => value.user!.updatePassword(newPassword));
  }

  @override
  Future<void> changeEmail(String email) async {
    await _firebaseAuth.currentUser!.verifyBeforeUpdateEmail(email);
  }

  @override
  Future<User?> getUser() async {
    User? user = _firebaseAuth.currentUser;
    return user;
  }

  @override
  Future<UserCredential> signIn(String email, String password) async {
    final UserCredential user = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return user;
  }

  @override
  Future<UserCredential> anonymousSignIn() async {
    final UserCredential user = await _firebaseAuth.signInAnonymously();
    return user;
  }

  @override
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<List<SignInMethod>> getSignInMethodsForEmail(String email) async {
    return await _firebaseAuth.fetchSignInMethodsForEmail(email).then((value) =>
        value.map((e) => _signInMethods[e]).whereType<SignInMethod>().toList());
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    final result = await _firebaseAuth.fetchSignInMethodsForEmail(email);
    return result.isNotEmpty;
  }

  @override
  Future<AuthCredential> verifyPhoneNumber(
      String newPhone, Future<String> Function()? getCode) async {
    Completer<AuthCredential> completer = Completer();
    String storedVerificationId;
    int? resendToken;
    await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: newPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          completer.complete(credential);
        },
        verificationFailed: (FirebaseAuthException error) {
          completer.completeError(error);
        },
        codeSent: (String verificationId, int? forceResendingToken) async {
          storedVerificationId = verificationId;
          resendToken = forceResendingToken;
          final code = await getCode!();
          if (code == null) {
            completer
                .completeError(FlutterError('Must validate your phone number'));
          } else {
            final credential = PhoneAuthProvider.credential(
                verificationId: verificationId, smsCode: code);
            completer.complete(credential);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          storedVerificationId = verificationId;
        });
    final credentials = await completer.future;
    return credentials;
  }

  @override
  Future<UserCredential> setPhoneNumber(
      String newPhone, Future<String> Function()? getCode) async {
    final credentials = await verifyPhoneNumber(newPhone, getCode);
    final result =
        await _firebaseAuth.currentUser!.linkWithCredential(credentials);
    return result;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
