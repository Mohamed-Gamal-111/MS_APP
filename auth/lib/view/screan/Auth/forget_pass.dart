import 'package:auth/view/screan/Auth/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_dialog/awesome_dialog.dart'; // لازم تضيف الباكيج

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController email = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendResetEmail() async {
    if (email.text.isEmpty) {
      _showSnack("⚠ يرجى إدخال البريد الإلكتروني");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.text.trim());

      if (!mounted) return;

      // 🌟 هنا نعرض AwesomeDialog
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'تم الإرسال!',
        desc: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.\nالرجاء تغيير كلمة المرور ثم تسجيل الدخول.',
        autoHide: const Duration(seconds: 5), // بعد 10 ثواني يقفل تلقائي
        onDismissCallback: (type) {
          // بعد 10 ثواني نروح على صفحة Login
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));// تأكد من أن اسم الراوت /login موجود
        },
      ).show();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(e.message ?? "حدث خطأ");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "استعادة كلمة المرور",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "البريد الإلكتروني",
                  hintText: "example@gmail.com",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF00C853)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _sendResetEmail,
                  child: const Text(
                    "إرسال رابط إعادة التعيين",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}