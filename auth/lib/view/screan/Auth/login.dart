import 'package:auth/services/login_service.dart';
import 'package:auth/view/patient_view/homepage_patient.dart';
import 'package:auth/view/doctor_view/doctor_homepage.dart';
import 'package:auth/view/screan/Auth/forget_pass.dart';
import 'package:auth/view/screan/Auth/sign_up.dart';
import 'package:auth/view/widget/image_logo.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true; // 1️⃣ المتغير المسؤول عن إظهار وإخفاء كلمة المرور

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05), // تحديث لتجنب التحذيرات الصفراء
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const CircleAvatar(
                  radius: 75,
                  backgroundColor: Color(0xFFF0F7FA),
                  child: LogoWidget(img: "assets/images/logo.png"),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "رعاية التصلب المتعدد",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3B5D),
                ),
              ),
              const Text(
                "معاً نتابع صحتك",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5A7B9D),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05), // تحديث لتجنب التحذيرات الصفراء
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Center(
                      child: Text(
                        "مرحباً بعودتك",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildLabel("البريد الإلكتروني أو اسم المستخدم"),
                    _buildTextField(
                      controller: emailController,
                      hint: "أدخل بريدك الإلكتروني",
                    ),
                    const SizedBox(height: 20),
                    _buildLabel("كلمة المرور"),
                    // 2️⃣ تمرير الخصائص الجديدة لزر العين التفاعلي
                    _buildTextField(
                      controller: passwordController,
                      hint: "أدخل كلمة المرور",
                      isPassword: true,
                      hasEyeIcon: true,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "نسيت كلمة المرور؟",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _loading ? null : _handleLogin,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "تسجيل الدخول",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "إنشاء حساب",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text("ليس لديك حساب؟"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    ),
  );

  // 3️⃣ تحديث الميثود لدعم الـ IconButton التفاعلي وعكس قيمة الـ Obscure
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool hasEyeIcon = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        // تعديل الأيقونة لتصبح IconButton تفاعلي داخل الـ prefixIcon أو suffixIcon ليتناسب مع اتجاه الكتابة
        prefixIcon: hasEyeIcon
            ? IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final user = await authService.signIn(email, password);
      if (user != null) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final profileRef =
        FirebaseFirestore.instance.collection("profiles").doc(uid);

        final doc = await profileRef.get();
        String role = "patient"; // default
        if (!doc.exists) {
          await profileRef.set({
            "uid": uid,
            "email": email,
            "name": "",
            "age": 0,
            "gender": "",
            "phone": "",
            "totalTests": 0,
            "progress": 0,
            "lastTestDate": "",
            "createdAt": DateTime.now().toIso8601String(),
            "role": role,
          });
        } else {
          final data = doc.data();
          if (data != null && data.containsKey('role')) {
            role = data['role'];
          }
        }

        if (!mounted) return;
        if (role == "doctor") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DoctorHomePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientHomePage()),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("خطأ في البريد الإلكتروني أو كلمة المرور"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }
}