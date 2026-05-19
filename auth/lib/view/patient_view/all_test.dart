import 'package:auth/view/patient_view/homepage_patient.dart';
import 'package:auth/view/patient_view/Fatigue questionnaires/Fatigue_questionnaires.dart';
import 'package:auth/view/patient_view/profile_patient.dart';
import 'package:auth/view/patient_view/romberg_test/romberg_upload_page.dart';
import 'package:auth/view/patient_view/tandem_test/tandem_upload_page.dart';
import 'package:auth/view/patient_view/test_Fing/pages/test_dashboard_page.dart';
import 'package:auth/view/patient_view/memory_test/memory_test.dart';
import 'package:auth/view/patient_view/drawing_test/drawing_test.dart';
import 'package:auth/view/patient_view/Moodquestion/Mood_questionnaires .dart';
import 'package:auth/view/patient_view/sdmt_test/sdmt_test.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'finger_test/finger_upload_page.dart';

class NeuroTestsPage extends StatefulWidget {
  const NeuroTestsPage({super.key});

  @override
  State<NeuroTestsPage> createState() => _NeuroTestsPageState();
}

class _NeuroTestsPageState extends State<NeuroTestsPage> {
  int _currentIndex = 1;
  bool canTakeTestGeneral = false;
  Map<String, dynamic> testsStatus = {};
  bool _isLoading = true;

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchPermissions();
  }

  // 🔥 جلب الصلاحيات بشكل لحظي وآمن للمرضى الجدد
  void _fetchPermissions() {
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('profiles')
        .doc(user!.uid)
        .snapshots()
        .listen((doc) {
      if (mounted) {
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            canTakeTestGeneral = data.containsKey('canTakeTest') ? data['canTakeTest'] : false;
            testsStatus = data.containsKey('testsStatus') ? data['testsStatus'] : {};
            _isLoading = false;
          });
        }
      }
    });
  }

  // 🔥 دالة الحماية الموحدة
  void _protectedNavigation(Widget page, String testKey) {
    bool isTestOpen = testsStatus[testKey] ?? false;

    if (!canTakeTestGeneral) {
      _showLockedAlert("مرحباً بك! يرجى الانتظار حتى يقوم طبيبك بمراجعة ملفك وفتح صلاحية الاختبارات لك لبدء التقييم.");
    } else if (!isTestOpen) {
      _showLockedAlert("لقد أتممت هذا الاختبار بالفعل في هذه الجلسة.");
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    }
  }

  void _showLockedAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: Colors.blue),
            SizedBox(width: 10),
            Text("تنبيه الصلاحية"),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("حسناً", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> neuroTests = [
      {'key': 'Romberg', 'title': 'اختبار التوازن', 'desc': 'قياس ثبات الوقوف (رومبيرغ)', 'duration': '30 ثانية', 'icon': Icons.scale, 'page': const RombergUploadPage()},
      {'key': 'FingerNose', 'title': 'التنسيق الحركي', 'desc': 'حركة الإصبع للأنف 10 مرات', 'duration': 'دقيقة واحدة', 'icon': Icons.front_hand, 'page': const FingerUploadPage()},
      {'key': 'Walking', 'title': 'اختبار المشي', 'desc': 'تحليل نمط المشي الطبيعي', 'duration': '45 ثانية', 'icon': Icons.directions_walk, 'page': const TandemUploadPage()},
      {'key': 'Memory', 'title': 'اختبار الذاكرة (CVLT)', 'desc': 'الذاكرة اللفظية والسمعية', 'duration': '5 دقائق', 'icon': Icons.psychology, 'page': const MemoryTestPage()},
      {'key': 'FingerTap', 'title': 'سرعة النقر', 'desc': 'قياس الحركة ومؤشر الإرهاق', 'duration': '10 ثواني', 'icon': Icons.touch_app, 'page': const TestDashboardPage()},
      {'key': 'Drawing', 'title': 'اختبار الرسم (BVMT-R)', 'desc': 'الذاكرة البصرية والمكانية', 'duration': '3 دقائق', 'icon': Icons.edit, 'page': const DrawingTestPage()},
      {'key': 'SDMT', 'title': 'اختبار الرموز (SDMT)', 'desc': 'سرعة معالجة المعلومات', 'duration': '90 ثانية', 'icon': Icons.speed, 'page': const SDMTTestPage()},
      {'key': 'Mood', 'title': 'استبيان المزاج', 'desc': 'تقييم الحالة المزاجية اليومية', 'duration': 'دقيقة واحدة', 'icon': Icons.sentiment_satisfied_alt, 'page': const HADSTestScreen()},
      {'key': 'Fatigue', 'title': 'استبيان الارهاق', 'desc': 'تقييم حالة الارهاق اليومية', 'duration': 'دقيقة واحدة', 'icon': Icons.battery_alert, 'page': const FatigueTestScreen()},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40, right: 25, left: 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF4DB6E1)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: const Column(
                children: [
                  Text('الاختبارات العصبية', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('اختر الاختبار الذي تريد إجراءه', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                itemCount: neuroTests.length,
                itemBuilder: (context, index) {
                  final test = neuroTests[index];
                  // 🔥 فحص الحالة لكل سطر في القائمة
                  bool isTestOpen = canTakeTestGeneral && (testsStatus[test['key']] ?? false);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _protectedNavigation(test['page'], test['key']),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              // 🔥 أيقونة القفل أو السهم بناءً على الحالة
                              Icon(isTestOpen ? Icons.arrow_back_ios_new : Icons.lock_outline,
                                   size: 18, color: isTestOpen ? Colors.blue : Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(test['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isTestOpen ? Colors.black : Colors.grey)),
                                    Text(test['desc'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      !canTakeTestGeneral ? "بانتظار الطبيب" : (isTestOpen ? "المدة: ${test['duration']}" : "تم الإكمال"),
                                      style: TextStyle(color: isTestOpen ? Colors.blue : Colors.red.shade300, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isTestOpen ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(test['icon'], color: isTestOpen ? const Color(0xFF2196F3) : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientHomePage()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'الملف الشخصي'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'الاختبارات'),

          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
        ],
      ),
    );
  }
}