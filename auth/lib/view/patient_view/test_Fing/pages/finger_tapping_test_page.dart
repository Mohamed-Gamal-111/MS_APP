import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/finger_tap_result.dart';
import '../utils/edss_classifier.dart';

class FingerTappingTestPage extends StatefulWidget {
  final String hand;

  const FingerTappingTestPage({super.key, required this.hand});

  @override
  State<FingerTappingTestPage> createState() => _FingerTappingTestPageState();
}

class _FingerTappingTestPageState extends State<FingerTappingTestPage> {
  static const int duration = 10;
  Timer? timer;
  int remaining = duration;
  bool running = false;
  List<int> tapsTime = [];

  void start() {
    setState(() {
      tapsTime.clear();
      remaining = duration;
      running = true;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remaining == 0) {
        t.cancel();
        finish();
      } else {
        setState(() => remaining--);
      }
    });
  }

  void tap() {
    if (!running) return;
    tapsTime.add(DateTime.now().millisecondsSinceEpoch);
  }

  void finish() {
    running = false;
    int taps = tapsTime.length;
    double speed = taps / duration;
    double irregularity = calcIrregularity();
    String edss = classifyEDSS(taps, irregularity);

    Navigator.pop(
      context,
      FingerTapResult(
        hand: widget.hand,
        taps: taps,
        speed: speed,
        irregularity: irregularity,
        edss: edss,
        date: DateTime.now(),
      ),
    );
  }

  double calcIrregularity() {
    if (tapsTime.length < 2) return 0;
    List<int> intervals = [];
    for (int i = 1; i < tapsTime.length; i++) {
      intervals.add(tapsTime[i] - tapsTime[i - 1]);
    }
    double mean = intervals.reduce((a, b) => a + b) / intervals.length;
    double variance = intervals
        .map((e) => pow(e - mean, 2))
        .reduce((a, b) => a + b) /
        intervals.length;
    return sqrt(variance);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("اختبار اليد ${widget.hand}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue.shade900,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // مؤشر الوقت الدائري
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: remaining / duration,
                  strokeWidth: 8,
                  backgroundColor: Colors.blue.shade50,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                ),
              ),
              Column(
                children: [
                  Text(
                    "$remaining",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                  const Text("ثانية", style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
          
          const Spacer(),
          
          // تعليمات بسيطة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              running ? "استمر بالنقر بأسرع ما يمكن!" : "اضغط على الزر الأزرق للبدء ثم انقر داخل الدائرة",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade600),
            ),
          ),
          
          const SizedBox(height: 30),

          // منطقة النقر الكبيرة (Tap Zone)
          GestureDetector(
            onTap: tap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: running ? Colors.blue.shade600 : Colors.grey.shade200,
                shape: BoxShape.circle,
                boxShadow: [
                  if (running)
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                ],
                border: Border.all(color: Colors.white, width: 10),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app, 
                      size: 50, 
                      color: running ? Colors.white : Colors.grey.shade500
                    ),
                    const SizedBox(height: 10),
                    Text(
                      running ? "انقر هنا!" : "المنطقة معطلة",
                      style: TextStyle(
                        color: running ? Colors.white : Colors.grey.shade500,
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // زر التحكم السفلي
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                ),
                onPressed: running ? null : start,
                child: Text(
                  running ? "الاختبار جارٍ..." : "ابدأ الاختبار",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}