import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SDMTTestPage extends StatefulWidget {
  const SDMTTestPage({super.key});

  @override
  State<SDMTTestPage> createState() => _SDMTTestPageState();
}

enum SDMTState { intro, testing }

class _SDMTTestPageState extends State<SDMTTestPage> with SingleTickerProviderStateMixin {
  SDMTState _currentState = SDMTState.intro;
  int _timeLeft = 90;
  Timer? _timer;
  int _score = 0;

  final Map<IconData, int> _symbolMap = {
    Icons.remove: 1, 
    Icons.horizontal_rule: 2, 
    Icons.add: 3,
    Icons.keyboard_arrow_up: 4, 
    Icons.keyboard_arrow_down: 5,
    Icons.close: 6, 
    Icons.turn_left: 7, 
    Icons.turn_right: 8, 
    Icons.circle_outlined: 9,
  };

  late IconData _currentSymbol;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pickNextSymbol();
  }

  void _pickNextSymbol() {
    final rand = Random();
    int idx = rand.nextInt(_symbolMap.length);
    setState(() => _currentSymbol = _symbolMap.keys.elementAt(idx));
    _animationController.forward(from: 0.0);
  }

  void _startTest() {
    setState(() {
      _currentState = SDMTState.testing;
      _score = 0;
      _timeLeft = 90;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 1) { 
        setState(() => _timeLeft--); 
      } else { 
        _endTest(); 
      }
    });
  }

  Future<void> _submitSDMTFinal() async {
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

      await FirebaseFirestore.instance
          .collection('evaluations')
          .doc(user.uid) 
          .set({
        'patientName': patientName,
        'patientUid': user.uid,
        'doctorUid': doctorUid,
        'lastUpdated': FieldValue.serverTimestamp(),
        'testResults': {
          'SDMT_ProcessingSpeed': _score,
        }
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('evaluations_history').add({
        'patientUid': user.uid,
        'patientName': patientName,
        'doctorUid': doctorUid,
        'testName': 'SDMT (Processing Speed)',
        'score': _score,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'doctorUid': doctorUid,
        'patientUid': user.uid,
        'patientName': patientName,
        'message': 'أتم المريض $patientName اختبار سرعة الاستجابة (SDMT)',
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).update({
        'testsStatus.SDMT': false, 
      });

      debugPrint("SDMT Data Submitted and Locked Successfully.");
    } catch (e) {
      debugPrint("Error in SDMT final submission: $e");
    }
  }

  void _endTest() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("انتهى الاختبار", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
            const SizedBox(height: 15),
            const Text("لقد أتممت الاختبار بنجاح.", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text("اضغط إرسال لحفظ نتيجتك وإبلاغ الطبيب بانتهاء اختبار SDMT.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await _submitSDMTFinal();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: const Text("إرسال للدكتور", style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  void _onDigitSelected(int digit) {
    if (_symbolMap[_currentSymbol] == digit) { 
      _score++; 
    }
    _pickNextSymbol();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // 🔥 الودجت المرجعية (الجدول العلوي) المضافة
  Widget _buildReferenceTable() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _symbolMap.entries.map((entry) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Icon(entry.key, size: 22, color: Colors.blueGrey),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        appBar: AppBar(
          title: const Text('اختبار SDMT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: _currentState == SDMTState.intro ? _buildIntro() : _buildTesting(),
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
            const Icon(Icons.speed, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text('اختبار سرعة الاستجابة\n(SDMT)', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text('لديك 90 ثانية لربط أكبر عدد ممكن من الرموز بالأرقام الموافقة لها.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), shape: const StadiumBorder()),
              onPressed: _startTest, 
              child: const Text('ابدأ الاختبار الآن', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTesting() {
    return Column(
      children: [
        LinearProgressIndicator(value: _timeLeft / 90.0, color: Colors.redAccent, backgroundColor: Colors.red.withOpacity(0.1)),
        const SizedBox(height: 8),
        _buildReferenceTable(), // 🔥 إضافة الجدول المرجعي هنا
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('الوقت المتبقي: $_timeLeft ثانية', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ),
        const Spacer(),
        ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
          child: Icon(_currentSymbol, size: 120, color: Colors.blue.shade900),
        ),
        const Spacer(),
        const Text("اختر الرقم المقابل للرمز:", style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 20),
        _buildNumericPad(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildNumericPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
        children: List.generate(9, (index) {
          int digit = index + 1;
          return SizedBox(width: 75, height: 75,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
              ),
              onPressed: () => _onDigitSelected(digit), 
              child: Text('$digit', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ),
    );
  }
}