import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/finger_tap_result.dart';
import 'finger_tapping_test_page.dart';

class TestDashboardPage extends StatefulWidget {
  const TestDashboardPage({super.key});

  @override
  State<TestDashboardPage> createState() => _TestDashboardPageState();
}

class _TestDashboardPageState extends State<TestDashboardPage> {
  FingerTapResult? rightHand;
  FingerTapResult? leftHand;

  // 🔥 الدالة الشاملة: رفع النتائج المدمجة + إشعار + قفل الحالة + سجل التاريخ
  Future<void> _submitFingerTapFinal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. جلب بيانات المريض والدكتور
      DocumentSnapshot profile = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();
      
      if (!profile.exists) return;

      String patientName = profile.get('name') ?? "Unknown";
      String doctorUid = profile.get('doctorUid') ?? "";

      // 2. تحديث وثيقة النتائج المجمعة (Merge) ليراها الدكتور في الجدول السريع
      await FirebaseFirestore.instance
          .collection('evaluations')
          .doc(user.uid)
          .set({
        'patientName': patientName,
        'patientUid': user.uid,
        'doctorUid': doctorUid,
        'lastUpdated': FieldValue.serverTimestamp(),
        'testResults': {
          'FingerTap_Right': rightHand?.taps ?? 0,
          'FingerTap_Left': leftHand?.taps ?? 0,
        }
      }, SetOptions(merge: true));

      // 3. إضافة سجل في التاريخ (History) كوثيقة منفصلة
      await FirebaseFirestore.instance.collection('evaluations_history').add({
        'patientUid': user.uid,
        'patientName': patientName,
        'doctorUid': doctorUid,
        'testName': 'Finger Tapping Speed',
        'testResults': {
          'right_hand': rightHand?.taps ?? 0,
          'left_hand': leftHand?.taps ?? 0,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 4. إرسال إشعار فوري للدكتور
      await FirebaseFirestore.instance.collection('notifications').add({
        'doctorUid': doctorUid,
        'patientUid': user.uid,
        'patientName': patientName,
        'message': 'أتم المريض $patientName اختبار سرعة النقر لليدين',
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 5. 🔥 قفل حالة هذا الاختبار في بروفايل المريض لهذه الجلسة
      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).update({
        'testsStatus.FingerTap': false, 
      });

      debugPrint("Finger Tap Data Submitted and Test Locked.");
    } catch (e) {
      debugPrint("Error in Finger Tap final submission: $e");
    }
  }

  // 🔥 الـ Alert النهائي لطلب الإرسال للدكتور
  void _showFinishConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_done_rounded, color: Colors.green, size: 60),
            const SizedBox(height: 15),
            const Text(
              "اكتمل اختبار التنسيق الحركي",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "اضغط إرسال لحفظ قياسات سرعة النقر لليدين وإبلاغ طبيبك المختص.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await _submitFingerTapFinal();
                if (mounted) {
                  Navigator.pop(context); // إغلاق الـ Alert
                  Navigator.pop(context); // العودة للقائمة الرئيسية
                }
              },
              child: const Text("إرسال للدكتور", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startTest(String hand) async {
    final result = await Navigator.push<FingerTapResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FingerTappingTestPage(hand: hand),
      ),
    );

    if (result != null) {
      setState(() {
        if (hand == "اليمنى") {
          rightHand = result;
        } else {
          leftHand = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        appBar: AppBar(
          title: const Text("اختبار التنسيق الحركي", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF4DB6E1)]),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.speed_rounded, color: Colors.white, size: 50),
                    SizedBox(height: 15),
                    Text(
                      "اختبار سرعة النقر (Finger Tapping)",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "هذا الاختبار يقيس التنسيق الحركي العصبي من خلال سرعة استجابة الأصابع",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("ابدأ الاختبار لكل يد:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildActionButton("اليد اليمنى", "اليمنى", Icons.front_hand, rightHand != null)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildActionButton("اليد اليسرى", "اليسرى", Icons.front_hand_outlined, leftHand != null)),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // زر الإرسال يظهر فقط عند تجربة اليدين
                    if (rightHand != null && leftHand != null)
                      _buildGradientButton("إنهاء وإرسال النتائج", _showFinishConfirmation),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, String hand, IconData icon, bool isDone) {
    return InkWell(
      onTap: () => startTest(hand),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDone ? Colors.green.shade300 : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 35, color: isDone ? Colors.green : Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? Colors.green : Colors.black87)),
            if (isDone) const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text("تم الاختبار", style: TextStyle(color: Colors.green, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onTap) {
    return Container(
      width: double.infinity, height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF4CAF50)]),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}