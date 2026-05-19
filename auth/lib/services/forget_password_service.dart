import 'package:firebase_auth/firebase_auth.dart';

class ForgetPasswordService {
  Future<String> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "حدث خطأ";
    }
  }
}