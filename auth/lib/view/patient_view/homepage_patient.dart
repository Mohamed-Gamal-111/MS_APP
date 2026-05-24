import 'dart:ui';

import 'package:auth/view/patient_view/romberg_test/romberg_upload_page.dart';
import 'package:auth/view/patient_view/tandem_test/tandem_upload_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:auth/view/patient_view/Moodquestion/Mood_questionnaires .dart';
import 'package:auth/view/patient_view/Fatigue questionnaires/Fatigue_questionnaires.dart';
import 'package:auth/view/patient_view/drawing_test/drawing_test.dart';
import 'package:auth/view/patient_view/memory_test/memory_test.dart';
import 'package:auth/view/patient_view/profile_patient.dart';
import 'package:auth/view/patient_view/sdmt_test/sdmt_test.dart';
import 'package:auth/view/patient_view/test_Fing/pages/test_dashboard_page.dart';
import 'finger_test/finger_upload_page.dart';
import 'package:auth/view/chatbot/chatbot_fab.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  int _currentIndex = 2;
  Map<String, dynamic> testsStatus = {};
  bool canTakeTestGeneral = false;
  bool _isLoading = true;

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchPermissionsAndStatus();
  }

  Future<void> _fetchPermissionsAndStatus() async {
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      FirebaseFirestore.instance
          .collection('profiles')
          .doc(user!.uid)
          .snapshots()
          .listen(
        (doc) {
          if (mounted) {
            setState(() {
              if (doc.exists && doc.data() != null) {
                final Map<String, dynamic> data =
                    doc.data() as Map<String, dynamic>;

                canTakeTestGeneral = data.containsKey('canTakeTest')
                    ? data['canTakeTest']
                    : false;

                testsStatus =
                    data.containsKey('testsStatus') ? data['testsStatus'] : {};
              } else {
                canTakeTestGeneral = false;
                testsStatus = {};
              }

              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _checkTestStatus(String key) {
    if (testsStatus.isEmpty) return false;

    if (testsStatus.containsKey(key)) {
      return testsStatus[key] ?? false;
    }

    if (key == 'FingerToNose') {
      return testsStatus['FingerToNose'] ??
          testsStatus['fingerToNose'] ??
          testsStatus['finger_to_nose'] ??
          false;
    }

    return false;
  }

  void _handleTestNavigation(Widget page, String testKey) {
    final bool isTestOpen = _checkTestStatus(testKey);

    if (!canTakeTestGeneral) {
      _showLockedAlert(
        "مرحباً بك! يرجى الانتظار حتى يقوم طبيبك بمراجعة ملفك وفتح صلاحية الاختبارات لك لبدء أول جلسة تقييم.",
      );
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
            Icon(Icons.hourglass_empty_rounded, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text("تنبيه"),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "فهمت ذلك",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBottomNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String userName = user?.displayName ?? "المستخدم";

    final List<Map<String, dynamic>> tests = [
      {
        'key': 'SDMT',
        'title': 'اختبار الرموز (SDMT)',
        'subtitle': 'سرعة المعالجة',
        'icon': Icons.speed,
        'page': const SDMTTestPage(),
      },
      {
        'key': 'Memory',
        'title': 'اختبار الذاكرة',
        'subtitle': 'الذاكرة قصيرة المدى',
        'icon': Icons.psychology,
        'page': const MemoryTestPage(),
      },
      {
        'key': 'FingerTap',
        'title': 'سرعة النقر',
        'subtitle': 'قياس الحركة',
        'icon': Icons.touch_app,
        'page': const TestDashboardPage(),
      },
      {
        'key': 'Drawing',
        'title': 'اختبار الرسم',
        'subtitle': 'التحكم الحركي',
        'icon': Icons.edit,
        'page': const DrawingTestPage(),
      },
      {
        'key': 'FingerToNose',
        'title': 'تنسيق حركة اليد',
        'subtitle': 'لمس الأنف بالإصبع',
        'icon': Icons.back_hand,
        'page': const FingerUploadPage(),
      },
      {
        'key': 'Balance',
        'title': 'اختبار الاتزان',
        'subtitle': 'الوقوف بثبات لفترة قصيرة',
        'icon': Icons.accessibility_new,
        'page': const RombergUploadPage(),
      },
      {
        'key': 'Walking',
        'title': 'اختبار المشي',
        'subtitle': 'المشي في خط مستقيم',
        'icon': Icons.directions_walk,
        'page': const TandemUploadPage(),
      },
      {
        'key': 'Mood',
        'title': 'استبيان المزاج',
        'subtitle': 'الحالة المزاجية',
        'icon': Icons.sentiment_satisfied_alt,
        'page': const HADSTestScreen(),
      },
      {
        'key': 'Fatigue',
        'title': 'استبيان الإرهاق',
        'subtitle': 'مستوى الإرهاق',
        'icon': Icons.battery_alert,
        'page': const FatigueTestScreen(),
      },
    ];

    final Widget currentPage = _currentIndex == 0
        ? const KeyedSubtree(
            key: ValueKey('profile_page'),
            child: ProfilePage(),
          )
        : _buildTestsHomeContent(userName, tests);

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5F8FF),
      floatingActionButton: const ChatBotFAB(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slideAnimation = Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: child,
                    ),
                  );
                },
                child: currentPage,
              ),
            ),
      bottomNavigationBar: _buildLiquidGlassNavBar(),
    );
  }

  Widget _buildTestsHomeContent(
    String userName,
    List<Map<String, dynamic>> tests,
  ) {
    return SingleChildScrollView(
      key: ValueKey('tests_home_$_currentIndex'),
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 60,
              right: 25,
              left: 25,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'كيف حالك اليوم؟',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الاختبارات المطلوبة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tests.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemBuilder: (context, index) {
                final item = tests[index];

                final bool isTestOpen =
                    canTakeTestGeneral && _checkTestStatus(item['key']);

                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.05),
                        child: Icon(
                          item['icon'],
                          color: isTestOpen ? Colors.blue : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: isTestOpen
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2196F3),
                                    Color(0xFF4CAF50),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade400,
                                    Colors.grey.shade400,
                                  ],
                                ),
                        ),
                        child: ElevatedButton(
                          onPressed: () => _handleTestNavigation(
                            item['page'],
                            item['key'],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            canTakeTestGeneral
                                ? (isTestOpen ? 'ابدأ' : 'تم الإكمال')
                                : 'بانتظار الطبيب',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidGlassNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.32),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.13),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLiquidNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'الملف',
                  index: 0,
                ),
                _buildLiquidNavItem(
                  icon: Icons.assignment_outlined,
                  label: 'الاختبارات',
                  index: 1,
                ),
                _buildLiquidNavItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  index: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _handleBottomNavigation(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF4CAF50)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.blueGrey.shade600,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
