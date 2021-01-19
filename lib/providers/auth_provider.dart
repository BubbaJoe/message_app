import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:message_app/services/firestore_database.dart';

import '../services/prefs.dart';

import '../helper/enums/auth_status_enum.dart';

import '../models/user_account.dart';

class AuthProvider extends ChangeNotifier {
  //Firebase Auth object
  FirebaseAuth _auth = FirebaseAuth.instance;

  Prefs _prefs = Prefs.instance;

  UserAccount _currentUser;

  String _verificationId;

  AuthStatus _status;

  AuthProvider() {
    loadDefaults();
  }

  AuthStatus get status => _status;

  UserAccount get currentUser => _currentUser;

  String get userNumber => _currentUser.number;

  void loadDefaults() async {
    _currentUser = await _prefs.getAuthUserKey();
    _status = await _prefs.getAuthStatusKey();
  }

  Future<void> verifyPhoneForOTP(String phoneNo) async {
    _status = AuthStatus.AUTHENTICATING;
    notifyListeners();

    final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
      _verificationId = verId;
    };

    final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
      _verificationId = verId;
      _status = AuthStatus.OTP_SENT;
      notifyListeners();
    };

    final PhoneVerificationFailed verifyFailed =
        (FirebaseAuthException exception) {
      _status = AuthStatus.UNAUTHENTICATED;
      notifyListeners();
      print('${exception.message}');
    };

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNo,
      codeAutoRetrievalTimeout: autoRetrieve,
      codeSent: smsCodeSent,
      timeout: const Duration(seconds: 5),
      verificationCompleted: _signInUser,
      verificationFailed: verifyFailed,
    );
  }

  void verifyOTP(String otp) {
    final AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: otp,
    );
    _signInUser(credential);
  }

  void _signInUser(AuthCredential credential) async {
    try {
      //Sign in, change status and get user
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      _status = AuthStatus.LOGGED_IN;
      _currentUser = _userAccountFromFirebase(userCredential.user);

      //Initialize database for this user
      FirestoreDatabase.init(uid: userNumber);

      //Save preferences
      await _prefs.setAuthUserKey(userNumber);
      await _prefs.setAuthStatusKey(_status);
    } catch (e) {
      print(e.toString());
      _status = AuthStatus.UNAUTHENTICATED;
    }
    notifyListeners();
  }

  //Create user object based on the given FirebaseUser
  UserAccount _userAccountFromFirebase(User user) {
    if (user == null) {
      return null;
    }
    return UserAccount(user.phoneNumber);
  }

  //Method to handle user signing out
  void signOut() async {
    await _auth.signOut();
    _status = AuthStatus.LOGGED_OUT;
    await _prefs.resetAuth();
    notifyListeners();
    return;
  }
}
