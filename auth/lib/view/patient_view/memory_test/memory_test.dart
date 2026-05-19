import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoryTestPage extends StatefulWidget {
  const MemoryTestPage({super.key});

  @override
  State<MemoryTestPage> createState() => _MemoryTestPageState();
}

enum MemoryTestState { intro, showingWords, recalling }

class _MemoryTestPageState extends State<MemoryTestPage> {
  final List<String> _targetWords = [
    'جزر', 'جاكيت', 'شاكوش', 'طاسه',
    'مسمار', 'بنطلون', 'كوسه', 'مغرفه',
    'جزمة', 'مفك', 'قمح', 'منشار',
    'مصفاه', 'فستان', 'حله', 'خس'
  ];

  MemoryTestState _currentState = MemoryTestState.intro;
  int _currentTrial = 1;
  final int _maxTrials = 5;

  List<String> _recalledWordsThisTrial = [];
  final Map<int, List<String>> _allTrialsResults = {};

  final TextEditingController _wordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 🔥 الدالة الشاملة: رفع النتائج + إشعار + قفل الحالة
  Future<void> _submitCVLTFinal(int totalScore) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot profile = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();
      
      if (!profile.exists) return;

      String patientName = profile.get('name') ?? "Unknown";
      String doctorUid = profile.get('doctorUid') ?? "";

      // 1. تحديث وثيقة النتائج المجمعة (Merge)
      await FirebaseFirestore.instance.collection('evaluations').doc(user.uid).set({
        'patientName': patientName,
        'patientUid': user.uid,
        'doctorUid': doctorUid,
        'lastUpdated': FieldValue.serverTimestamp(),
        'testResults': {
          'CVLT_Memory': totalScore,
        }
      }, SetOptions(merge: true));

      // 2. إرسال إشعار للدكتور
      await FirebaseFirestore.instance.collection('notifications').add({
        'doctorUid': doctorUid,
        'patientUid': user.uid,
        'patientName': patientName,
        'message': 'أتم المريض $patientName اختبار الذاكرة (CVLT)',
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 3. قفل الاختبار في الجلسة الحالية
      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).update({
        'testsStatus.Memory': false, 
      });

    } catch (e) {
      debugPrint("Error in CVLT submission: $e");
    }
  }

  void _showFinishAlert(int finalScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.blue, size: 60),
            const SizedBox(height: 15),
            const Text("اكتملت المحاولات بنجاح", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("اضغط إرسال لحفظ نتيجتك وإبلاغ الطبيب.", textAlign: TextAlign.center),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await _submitCVLTFinal(finalScore);
                if (mounted) {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                }
              },
              child: const Text("إرسال للدكتور", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _startWordsDisplay() {
    setState(() {
      _currentState = MemoryTestState.showingWords;
      _recalledWordsThisTrial = [];
    });

    // عرض الكلمات لمدة 15 ثانية ثم الانتقال للتذكر
    Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _currentState = MemoryTestState.recalling;
        });
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  void _submitWord() {
    String typed = _wordController.text.trim();
    if (typed.isEmpty) return;
    if (_targetWords.contains(typed) && !_recalledWordsThisTrial.contains(typed)) {
      setState(() => _recalledWordsThisTrial.add(typed));
    }
    _wordController.clear();
    _focusNode.requestFocus();
  }

  void _finishTrial() {
    _allTrialsResults[_currentTrial] = List.from(_recalledWordsThisTrial);
    if (_currentTrial < _maxTrials) {
      setState(() {
        _currentTrial++;
        _currentState = MemoryTestState.intro;
      });
    } else {
      int total = 0;
      _allTrialsResults.values.forEach((list) => total += list.length);
      _showFinishAlert(total);
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_currentState) {
      case MemoryTestState.intro: body = _buildIntro(); break;
      case MemoryTestState.showingWords: body = _buildShowingWordsGrid(); break; // 🔥 رجعنا الجدول
      case MemoryTestState.recalling: body = _buildRecalling(); break;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        appBar: AppBar(
          title: const Text('اختبار الذاكرة (CVLT)'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: KeyedSubtree(key: ValueKey(_currentState), child: body),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('المحاولة رقم $_currentTrial', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('سأعرض لك قائمة من الكلمات، حاول حفظها جيداً.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startWordsDisplay,
              child: const Text('أظهر الكلمات'),
            )
          ],
        ),
      ),
    );
  }

  // 🔥 الـ Grid الأصلي اللي بيعرض الـ 16 كلمة
  Widget _buildShowingWordsGrid() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('حاول حفظ هذه الكلمات (لديك 15 ثانية)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 2.5, 
              crossAxisSpacing: 10, 
              mainAxisSpacing: 10
            ),
            itemCount: _targetWords.length,
            itemBuilder: (context, index) => Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(_targetWords[index], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecalling() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('اكتب الكلمات التي تتذكرها من القائمة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wordController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'الكلمة...'),
                  onSubmitted: (_) => _submitWord(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _submitWord, child: const Text('إضافة'))
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _recalledWordsThisTrial.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: Text(_recalledWordsThisTrial[index]),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: _finishTrial,
              child: Text(_currentTrial == _maxTrials ? 'إنهاء الاختبار' : 'المحاولة التالية'),
            ),
          )
        ],
      ),
    );
  }
}