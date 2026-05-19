import 'package:auth/view/patient_view/all_test.dart';
import 'package:auth/view/patient_view/homepage_patient.dart';
import 'package:auth/view/screan/Auth/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? profileData;
  bool _loading = true;
  bool canTakeTest = false; // 🔥 حالة الصلاحية

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    User? user = auth.currentUser;
    if (user == null) return;

    // استخدام snapshots للاستماع اللحظي مع معالجة آمنة للحقول
    firestore.collection("profiles").doc(user.uid).snapshots().listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          profileData = data;
          // 🔥 فحص آمن: إذا لم يوجد الحقل (مريض جديد) نفترض أنه false لمنع الانهيار
          canTakeTest = data.containsKey('canTakeTest') ? data['canTakeTest'] : false;
          _loading = false;
        });
      }
    });
  }

  // 🔥 دالة الحماية المحدثة مع رسالة للمرضى الجدد
  void _protectedNavigation(BuildContext context, Widget targetPage) {
    if (canTakeTest) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage));
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_bottom_rounded, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text("تنبيه"),
            ],
          ),
          content: const Text(
            "مرحباً بك! يرجى الانتظار حتى يقوم طبيبك بمراجعة ملفك وفتح صلاحية الاختبارات لك لبدء أول جلسة تقييم.",
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("حسناً", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  int _calculateAge(String birthDate) {
    try {
      DateTime dob = DateTime.parse(birthDate);
      DateTime today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = profileData?['name'] ?? "مستخدم";
    final gender = profileData?['gender'] ?? "-";
    final birthDate = profileData?['birthDate'] ?? "-";
    final age = _calculateAge(birthDate);
    final email = profileData?['email'] ?? "-";
    final phone = profileData?['phone'] ?? "-";
    final totalTests = profileData?['totalTests'] ?? 0;
    final progress = profileData?['progress'] ?? 0;
    final lastTestDate = profileData?['lastTestDate'] ?? "-";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // تحسين سلاسة التمرير
          child: Column(
            children: [
              _buildProfileHeader(name, age, gender),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard('$totalTests', 'إجمالي الاختبارات', Icons.monitor_heart, Colors.blue),
                    _buildStatCard('$progress%', 'معدل التقدم', Icons.trending_up, Colors.blue),
                    _buildStatCard(lastTestDate == "" ? '-' : lastTestDate, 'آخر اختبار', Icons.calendar_month_outlined, Colors.blue),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoSection(email, phone, birthDate, gender),
              const SizedBox(height: 15),
              _buildSettingsButton(),
              const SizedBox(height: 20),
              _buildLogoutButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // --- دوال بناء الواجهة ---

  Widget _buildProfileHeader(String name, int age, String gender) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 40, right: 20, left: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF4DB6E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Text('الملف الشخصي', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFB3E5FC),
                  child: Icon(Icons.person_outline, size: 45, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text('$age سنة • $gender', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        children: [
          CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String email, String phone, String birthDate, String gender) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          _buildInfoRow('البريد الإلكتروني', email, Icons.email_outlined),
          const Divider(height: 30),
          _buildInfoRow('رقم الهاتف', phone, Icons.phone_outlined),
          const Divider(height: 30),
          _buildInfoRow('تاريخ الميلاد', birthDate, Icons.calendar_today_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Icon(icon, color: Colors.blue, size: 22),
      ],
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: const Icon(Icons.settings_outlined, color: Colors.blue),
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
        onTap: () {},
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        onPressed: () async {
          await auth.signOut();
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent, width: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 2) {
          _protectedNavigation(context, const NeuroTestsPage());
        } else if (index == 3) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientHomePage()));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف الشخصي'),

        BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'الاختبارات'),
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
      ],
    );
  }
}