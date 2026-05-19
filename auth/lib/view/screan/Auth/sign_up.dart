import 'dart:math';
import 'package:auth/view/patient_view/homepage_patient.dart';
import 'package:auth/view/doctor_view/doctor_homepage.dart';
import 'package:auth/view/screan/Auth/login.dart';
import 'package:auth/view/widget/image_logo.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String accountType = "مريض"; // default
  String? selectedDoctor;
  List<String> doctors = []; // هنجلبها من Firestore
  String? selectedGender;
  DateTime? selectedBirthDate;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // مفتاح التحكم في حالة الـ Form والـ Validators
  final _formKey = GlobalKey<FormState>();

  // متغيرات حالة العين التفاعلية لإظهار وإخفاء كلمة المرور بشكل مستقل
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // متغيرات لمراقبة الـ Validation الخاص بالـ Dropdowns والتاريخ لإظهار خطأ مخصص متناسق مع الثيم
  String? _doctorError;
  String? _birthDateError;
  String? _genderError;

  // متغير مخصص لعمل حاقن خطأ (Error Injection) تحت حقل الإيميل مباشرة عند وجود حساب مسجل مسبقاً
  String? _serverEmailError;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    QuerySnapshot snapshot = await firestore.collection("users")
        .where("role", isEqualTo: "doctor")
        .get();

    if (!mounted) return;
    setState(() {
      doctors = snapshot.docs.map((doc) => doc["name"].toString()).toList();
    });
  }

  String _generateDoctorCode() {
    Random random = Random();
    return "DOC${10000 + random.nextInt(90000)}";
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickBirthDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        selectedBirthDate = picked;
        _birthDateError = null; // إزالة الخطأ بمجرد الاختيار
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _register() async {
    // إعادة تعيين أخطاء الـ Dropdowns والتاريخ والإيميل قبل التحقق الجديد
    setState(() {
      _serverEmailError = null;
      _doctorError = (accountType == "مريض" && selectedDoctor == null) ? "يرجى اختيار الطبيب المتابع" : null;
      _birthDateError = (selectedBirthDate == null) ? "يرجى تحديد تاريخ الميلاد" : null;
      _genderError = (selectedGender == null) ? "يرجى اختيار الجنس" : null;
    });

    // تشغيل الـ Validator لجميع الـ Fields النصية في نفس الوقت
    if (!_formKey.currentState!.validate() || _doctorError != null || _birthDateError != null || _genderError != null) {
      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();

    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user!.updateDisplayName(name);
      String uid = userCredential.user!.uid;
      final profileRef = firestore.collection("profiles").doc(uid);

      String birthDateString = "${selectedBirthDate!.year}-${selectedBirthDate!.month.toString().padLeft(2,'0')}-${selectedBirthDate!.day.toString().padLeft(2,'0')}";

      if (accountType == "طبيب") {
        String doctorCode = _generateDoctorCode();
        await firestore.collection("users").doc(uid).set({
          "uid": uid,
          "name": name,
          "email": email,
          "role": "doctor",
          "doctorCode": doctorCode,
        });
        await profileRef.set({
          "uid": uid,
          "name": name,
          "email": email,
          "role": "doctor",
          "doctorCode": doctorCode,
          "birthDate": birthDateString,
          "age": _calculateAge(selectedBirthDate!),
          "gender": selectedGender,
          "phone": phone,
          "totalTests": 0,
          "progress": 0,
          "lastTestDate": "",
          "createdAt": DateTime.now().toIso8601String(),
        });
      } else if (accountType == "مريض") {
        QuerySnapshot doctorQuery = await firestore.collection("users")
            .where("name", isEqualTo: selectedDoctor)
            .where("role", isEqualTo: "doctor")
            .get();
        if (doctorQuery.docs.isEmpty) {
          if (!mounted) return;
          _showErrorSnackBar("الطبيب المختار غير موجود");
          return;
        }
        String doctorUid = doctorQuery.docs.first["uid"];
        String doctorCode = doctorQuery.docs.first["doctorCode"];
        await firestore.collection("users").doc(uid).set({
          "uid": uid,
          "name": name,
          "email": email,
          "role": "patient",
          "doctorUid": doctorUid,
          "doctorCode": doctorCode,
        });

        await profileRef.set({
          "uid": uid,
          "name": name,
          "email": email,
          "role": "patient",
          "doctorUid": doctorUid,
          "doctorCode": doctorCode,
          "birthDate": birthDateString,
          "age": _calculateAge(selectedBirthDate!),
          "gender": selectedGender,
          "phone": phone,
          "totalTests": 0,
          "progress": 0,
          "lastTestDate": "",
          "createdAt": DateTime.now().toIso8601String(),
          "canTakeTest": true,
          "testsStatus": {
            "SDMT": true,
            "Memory": true,
            "FingerTap": true,
            "Drawing": true,
            "Balance": true,
            "Walking": true,
            "FingerToNose": true,
            "Mood": true,
            "Fatigue": true
          }
        });
      }

      if (!mounted) return;
      if (accountType == "طبيب") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorHomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientHomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      // هنا بنمسك الأكواد اللي راجعة من الفايربيز ونعرضها بشكل بروفيشنال متناسق مع الواجهة
      if (e.code == 'email-already-in-use') {
        setState(() {
          _serverEmailError = "البريد الإلكتروني مستخدم بالفعل";
        });
        // إعادة تشغيل الـ validation عشان يظهر الخطأ فوراً تحت حقل الإيميل بالظبط
        _formKey.currentState!.validate();
      } else if (e.code == 'invalid-email') {
        setState(() {
          _serverEmailError = "صيغة البريد الإلكتروني غير صالحة";
        });
        _formKey.currentState!.validate();
      } else if (e.code == 'weak-password') {
        _showErrorSnackBar("كلمة المرور ضعيفة للغاية من ناحية الحماية");
      } else {
        _showErrorSnackBar("خطأ في المصادقة: ${e.message}");
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar("حدث خطأ غير متوقع أثناء التسجيل: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  child: LogoWidget(img: "assets/images/logo.png"),
                ),
                const SizedBox(height: 20),
                const Text("رعاية التصلب المتعدد",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5D))),
                const Text("معاً نتابع صحتك",
                    style: TextStyle(fontSize: 16, color: Color(0xFF5A7B9D))),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0,10)
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Center(child: Text("إنشاء حساب جديد", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
                      const SizedBox(height: 25),
                      _buildLabel("الاسم الكامل"),
                      _buildTextField(
                        controller: nameController,
                        hint: "Yassa Nazeer",
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "يرجى إدخال الاسم الكامل أولاً";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildLabel("البريد الإلكتروني"),
                      _buildTextField(
                        controller: emailController,
                        hint: "yassa@example.com",
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          // لو السيرفر رجع إن الإيميل موجود، بنعرض الخطأ المخصص فوراً هنا تحت الحقل
                          if (_serverEmailError != null) {
                            return _serverEmailError;
                          }
                          if (value == null || value.trim().isEmpty) {
                            return "يرجى إدخال البريد الإلكتروني أولاً";
                          }
                          final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                          if (!emailRegex.hasMatch(value.trim())) {
                            return "صيغة البريد الإلكتروني غير صحيحة";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildLabel("كلمة المرور"),
                      _buildTextField(
                        controller: passwordController,
                        hint: "أدخل كلمة المرور (8 خانات على الأقل)",
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onEyePressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "يرجى إدخال كلمة المرور أولاً";
                          }
                          if (value.length < 8) {
                            return "يجب ألا تقل كلمة المرور عن 8 أحرف أو أرقام";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildLabel("تأكيد كلمة المرور"),
                      _buildTextField(
                        controller: confirmPasswordController,
                        hint: "إعادة كتابة كلمة المرور للتأكيد",
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onEyePressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "يرجى تأكيد كلمة المرور أولاً";
                          }
                          if (value != passwordController.text) {
                            return "كلمة المرور وتأكيدها غير متطابقين";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text("أنا:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildRadioOption("طبيب"),
                          const SizedBox(width: 20),
                          _buildRadioOption("مريض"),
                        ],
                      ),
                      if (accountType == "مريض") ...[
                        const SizedBox(height: 15),
                        _buildLabel("اختر الطبيب المتابع"),
                        _buildDropdown(),
                        if (_doctorError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 12),
                            child: Text(_doctorError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                      ],
                      const SizedBox(height: 15),
                      _buildLabel("تاريخ الميلاد"),
                      InkWell(
                        onTap: _pickBirthDate,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(15),
                              border: _birthDateError != null ? Border.all(color: Colors.red.shade400, width: 1) : null),
                          alignment: Alignment.centerRight,
                          child: Text(
                            selectedBirthDate == null
                                ? "اختر تاريخ الميلاد"
                                : "${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}",
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                      if (_birthDateError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5, right: 12),
                          child: Text(_birthDateError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      const SizedBox(height: 15),
                      _buildLabel("الجنس"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(15),
                            border: _genderError != null ? Border.all(color: Colors.red.shade400, width: 1) : null
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedGender,
                            hint: const Text("اختر الجنس"),
                            items: ["ذكر", "أنثى"]
                                .map((g) => DropdownMenuItem(value: g, child: Text(g, textAlign: TextAlign.right)))
                                .toList(),
                            onChanged: (v) => setState(() {
                              selectedGender = v;
                              _genderError = null;
                            }),
                          ),
                        ),
                      ),
                      if (_genderError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5, right: 12),
                          child: Text(_genderError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      const SizedBox(height: 15),
                      _buildLabel("رقم الهاتف"),
                      _buildTextField(
                        controller: phoneController,
                        hint: "01012345678",
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "يرجى إدخال رقم الهاتف أولاً";
                          }
                          final phoneRegex = RegExp(r"^01[0125][0-9]{8}$");
                          if (value.trim().length != 11 || !phoneRegex.hasMatch(value.trim())) {
                            return "يجب أن يتكون من 11 رقم ويبدأ بـ 01";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF00C853)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          onPressed: _register,
                          child: const Text("إنشاء حساب", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())); },
                            child: const Text("تسجيل الدخول", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ),
                          const Text("لديك حساب بالفعل؟"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(label,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onEyePressed,
    TextInputType keyboardType = TextInputType.text,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      onChanged: (value) {
        // بمجرد ما المستخدم يبدأ يعدل في الإيميل، بنمسح خطأ السيرفر القديم فوراً عشان يرجع طبيعي
        if (keyboardType == TextInputType.emailAddress && _serverEmailError != null) {
          setState(() {
            _serverEmailError = null;
          });
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        prefixIcon: isPassword && onEyePressed != null
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: onEyePressed,
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildRadioOption(String value) {
    return InkWell(
      onTap: () => setState(() {
        accountType = value;
        _doctorError = null;
      }),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 16)),
          Radio<String>(
              value: value,
              groupValue: accountType,
              activeColor: const Color(0xFF1A3B5D),
              onChanged: (v) => setState(() {
                accountType = v!;
                _doctorError = null;
              })),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(15),
          border: _doctorError != null ? Border.all(color: Colors.red.shade400, width: 1) : null
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: const Text("اختر طبيباً من القائمة"),
          value: selectedDoctor,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: doctors.map((e) => DropdownMenuItem(value: e, child: Text(e, textAlign: TextAlign.right))).toList(),
          onChanged: (v) => setState(() {
            selectedDoctor = v;
            _doctorError = null;
          }),
        ),
      ),
    );
  }
}