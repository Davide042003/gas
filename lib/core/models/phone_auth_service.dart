import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> verifyPhoneNumber(String phoneNumber, Function(String) onCodeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,

      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        // Handle verification failure
        print(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        // Pass verification ID to the callback
        print("code sent");
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handle timeout
      },
      timeout: Duration(seconds: 45)
    );
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }
}
