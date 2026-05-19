import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FatigueTestScreen extends StatefulWidget {
  const FatigueTestScreen({super.key});

  @override
  _FatigueTestScreenState createState() => _FatigueTestScreenState();
}

class _FatigueTestScreenState extends State<FatigueTestScreen> {
  List<int> answers = List.filled(9, 0); // 0 تعني لم يتم الاختيار
  int totalScore = 0;

  final List<String> questions = [
    'أشعر بعدم الرغبة في عمل شيء عندما أكون مرهقاً',
    'أداء النشاطات الحركية يجعلني أشعر بالإعياء',
    'أشعر بالإرهاق بسهولة',
    'يتعارض الشعور بالإرهاق مع قدرتي على أداء مهامي الحركية',
    'يتسبب الشعور بالإرهاق في حدوث مشاكل متعددة لي',
    'يتعارض الشعور بالإرهاق مع قدرتي على "الاستمرار" في ممارسة مهامي الحركية',
    'يتعارض الشعور بالإرهاق مع قدرتي على أداء واجبات ومسئوليات معينة',
    'يمثل الإرهاق أحد ثلاثة أعراض مؤدية للشعور بالإعاقة',
    'يتعارض الشعور بالإرهاق مع عملي، عائلتي أو حياتي الاجتماعية',
  ];

  void calculateTotalScore() {
    setState(() {
      totalScore = answers.reduce((value, element) => value + element);
    });
  }

  // 🔥 الدالة الشاملة: رفع النتائج + إشعار + قفل الحالة + سجل التاريخ
  Future<void> _submitFatigueFinal() async {
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

      // 2. تحديث وثيقة النتائج المجمعة (Merge) ليراها الدكتور في الجدول
      await FirebaseFirestore.instance
          .collection('evaluations')
          .doc(user.uid)
          .set({
        'patientName': patientName,
        'patientUid': user.uid,
        'doctorUid': doctorUid,
        'lastUpdated': FieldValue.serverTimestamp(),
        'testResults': {
          'FSS_Fatigue': totalScore, // تخزين نتيجة الإرهاق
        }
      }, SetOptions(merge: true));

      // 3. إضافة سجل في التاريخ (History) كوثيقة منفصلة
      await FirebaseFirestore.instance.collection('evaluations_history').add({
        'patientUid': user.uid,
        'patientName': patientName,
        'doctorUid': doctorUid,
        'testName': 'FSS (Fatigue Questionnaire)',
        'score': totalScore,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 4. إرسال إشعار فوري للدكتور
      await FirebaseFirestore.instance.collection('notifications').add({
        'doctorUid': doctorUid,
        'patientUid': user.uid,
        'patientName': patientName,
        'message': 'أتم المريض $patientName استبيان الإرهاق (FSS)',
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 5. 🔥 قفل حالة هذا الاختبار في بروفايل المريض لهذه الجلسة
      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).update({
        'testsStatus.Fatigue': false, 
      });

      debugPrint("Fatigue Data Submitted, Notified, and Locked Successfully.");
    } catch (e) {
      debugPrint("Error in Fatigue final submission: $e");
    }
  }

  void _showFinishAlert() {
    if (answers.contains(0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى الإجابة على جميع الأسئلة أولاً'), backgroundColor: Colors.red),
      );
      return;
    }

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
            const Text("اكتمل التقييم بنجاح", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("اضغط إرسال لحفظ إجاباتك وإبلاغ الطبيب بانتهاء استبيان الإرهاق.", textAlign: TextAlign.center),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await _submitFatigueFinal();
                if (mounted) {
                  Navigator.pop(context); // إغلاق الـ Alert
                  Navigator.pop(context); // العودة للقائمة
                }
              },
              child: const Text("إرسال للدكتور", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('استبيان الإرهاق (FSS)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF4DB6E1)]),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'هذا الاستبيان هدفه معرفة مدى تأثير الإرهاق على حياتك اليومية. اختر الرقم الذي يصف حالتك (1: لا يحدث، 7: دائماً).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 25),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) => _buildQuestionCard(index),
              ),
              const SizedBox(height: 30),
              _buildGradientButton('إنهاء وإرسال التقييم', _showFinishAlert),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('سؤال ${index + 1}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(questions[index], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                int val = i + 1;
                bool isSelected = answers[index] == val;
                return GestureDetector(
                  onTap: () {
                    setState(() => answers[index] = val);
                    calculateTotalScore();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    height: 45, width: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Text('$val', style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onTap) {
    return Container(
      width: double.infinity, height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF4CAF50)]),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}