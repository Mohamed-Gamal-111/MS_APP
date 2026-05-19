import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DrawingTestPage extends StatefulWidget {
  const DrawingTestPage({super.key});

  @override
  State<DrawingTestPage> createState() => _DrawingTestPageState();
}

enum DrawingTestState { intro, viewing, drawing }

class Stroke {
  final List<Offset> points;
  Stroke({required this.points});
}

class _DrawingTestPageState extends State<DrawingTestPage> {
  DrawingTestState _currentState = DrawingTestState.intro;
  int _currentTrial = 1;
  final int _maxTrials = 3;
  int _viewingSecondsLeft = 10;
  Timer? _timer;

  final Map<int, Map<int, List<Stroke>>> _allDrawings = {
    1: {}, 2: {}, 3: {},
  };

  final Map<int, Map<int, int>> _calculatedScores = {
    1: {}, 2: {}, 3: {},
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    for (int t = 1; t <= 3; t++) {
      for (int s = 0; s < 6; s++) {
        _allDrawings[t]![s] = [];
        _calculatedScores[t]![s] = 0;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // دالة إرسال النتائج النهائية بنظام الـ Merge وقفل الاختبار
  Future<void> _sendTestResultDirectly(int score) async {
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
          'BVMT_Drawing': score, 
        }
      }, SetOptions(merge: true));


      await FirebaseFirestore.instance.collection('notifications').add({
        'doctorUid': doctorUid,
        'patientName': patientName,
        'message': 'أتم المريض $patientName اختبار الرسم (BVMT-R) بنجاح.',
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
      });


      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).update({
        'testsStatus.Drawing': false, 
      });

    } catch (e) {
      debugPrint("Error in final submission: $e");
    }
  }

  void _showFinishAlertAndUpload(int finalScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_done_outlined, color: Colors.green, size: 60),
              const SizedBox(height: 15),
              const Text("تم إنهاء الاختبار", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text("اضغط إرسال لحفظ نتيجتك وإبلاغ الطبيب.", textAlign: TextAlign.center),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await _sendTestResultDirectly(finalScore);
                  if (mounted) {
                    Navigator.pop(context); // إغلاق التنبيه
                    Navigator.pop(context); // العودة للقائمة الرئيسية
                  }
                },
                child: const Text("إرسال للدكتور", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  // منطق تصحيح الرسم التلقائي
  int _runAdvancedGrading(List<Stroke> strokes) {
    if (strokes.isEmpty) return 0;
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    int pointCount = 0;
    for (var stroke in strokes) {
      for (var p in stroke.points) {
        if (p.dx < minX) minX = p.dx; if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy; if (p.dy > maxY) maxY = p.dy;
        pointCount++;
      }
    }
    if (pointCount < 20) return 0;
    if ((maxX - minX) < 40 || (maxY - minY) < 40) return 1;
    return 2;
  }

  void _startViewing() {
    setState(() {
      _currentState = DrawingTestState.viewing;
      _viewingSecondsLeft = 10;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_viewingSecondsLeft > 1) {
        setState(() => _viewingSecondsLeft--);
      } else {
        timer.cancel();
        setState(() => _currentState = DrawingTestState.drawing);
      }
    });
  }

  void _finishTrial() {
    for (int i = 0; i < 6; i++) {
      _calculatedScores[_currentTrial]![i] = _runAdvancedGrading(_allDrawings[_currentTrial]![i] ?? []);
    }
    if (_currentTrial < _maxTrials) {
      setState(() {
        _currentTrial++;
        _currentState = DrawingTestState.intro;
      });
    } else {
      int finalTotal = 0;
      _calculatedScores.forEach((t, sMap) => sMap.values.forEach((v) => finalTotal += v));
      _showFinishAlertAndUpload(finalTotal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('اختبار الرسم (BVMT-R)'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blueAccent,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case DrawingTestState.intro: return _buildIntro();
      case DrawingTestState.viewing: return _buildViewing();
      case DrawingTestState.drawing: return _buildDrawingGrid();
    }
  }

  Widget _buildIntro() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_note_rounded, size: 100, color: Colors.blueAccent),
          const SizedBox(height: 20),
          Text('المحاولة رقم $_currentTrial', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('ركز في الأشكال الستة جيداً، ستحصل على 10 ثوانٍ لحفظ أماكنها وتفاصيلها.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: _startViewing,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: const StadiumBorder()),
            child: const Text('أظهر الأشكال الآن'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewing() {
    return Column(
      children: [
        LinearProgressIndicator(value: _viewingSecondsLeft / 10, color: Colors.redAccent, backgroundColor: Colors.red.withOpacity(0.1)),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('الوقت المتبقي: $_viewingSecondsLeft ثانية', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1),
            itemCount: 6,
            itemBuilder: (context, index) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: CustomPaint(painter: ShapePainter(index)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawingGrid() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12.0),
          child: Text('ارسم الأشكال من الذاكرة في أماكنها الصحيحة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.85, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: 6,
            itemBuilder: (context, index) => Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: GestureDetector(
                      onPanStart: (d) => setState(() => _allDrawings[_currentTrial]![index]!.add(Stroke(points: [d.localPosition]))),
                      onPanUpdate: (d) => setState(() => _allDrawings[_currentTrial]![index]!.last.points.add(d.localPosition)),
                      child: CustomPaint(painter: DrawingPainter(_allDrawings[_currentTrial]![index]!), size: Size.infinite),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _allDrawings[_currentTrial]![index] = []),
                  icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.redAccent),
                  label: const Text('مسح', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _finishTrial,
            child: Text(_currentTrial == _maxTrials ? 'إنهاء الاختبار وإرسال النتائج' : 'اعتماد المحاولة', style: const TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

// --- استعادة الرسومات الأصلية بكامل تفاصيلها ---
class ShapePainter extends CustomPainter {
  final int index;
  ShapePainter(this.index);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final w = size.width; final h = size.height;

    switch (index) {
      case 0:
        canvas.drawPath(Path()..moveTo(w*0.2, h*0.8)..lineTo(w*0.2, h*0.4)..arcToPoint(Offset(w*0.8, h*0.4), radius: Radius.circular(w*0.3))..lineTo(w*0.8, h*0.8)..moveTo(w*0.2, h*0.7)..lineTo(w*0.4, h*0.5), p);
        break;
      case 1:
        canvas.drawPath(Path()..moveTo(w*0.5, h*0.1)..lineTo(w*0.8, h*0.5)..lineTo(w*0.5, h*0.9)..lineTo(w*0.2, h*0.5)..close(), p);
        canvas.drawOval(Rect.fromCenter(center: Offset(w*0.5, h*0.5), width: w*0.3, height: h*0.2), p);
        break;
      case 2:
        canvas.drawRect(Rect.fromLTRB(w*0.1, h*0.3, w*0.9, h*0.7), p);
        canvas.drawPath(Path()..moveTo(w*0.1, h*0.3)..arcToPoint(Offset(w*0.9, h*0.3), radius: Radius.circular(w*0.4), clockwise: false), p);
        break;
      case 3:
        canvas.drawRect(Rect.fromLTRB(w*0.1, h*0.5, w*0.9, h*0.8), p);
        canvas.drawPath(Path()..moveTo(w*0.5, h*0.2)..lineTo(w*0.7, h*0.5)..lineTo(w*0.5, h*0.8)..lineTo(w*0.3, h*0.5)..close(), p);
        break;
      case 4:
        canvas.drawPath(Path()..moveTo(w*0.2, h*0.1)..lineTo(w*0.2, h*0.9)..lineTo(w*0.8, h*0.9)..lineTo(w*0.8, h*0.7)..lineTo(w*0.4, h*0.7)..lineTo(w*0.4, h*0.1)..close(), p);
        break;
      case 5:
        canvas.drawPath(Path()..moveTo(w*0.3, h*0.2)..lineTo(w*0.7, h*0.2)..lineTo(w*0.9, h*0.8)..lineTo(w*0.1, h*0.8)..close(), p);
        break;
    }
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  DrawingPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..strokeWidth = 3.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      canvas.drawPath(path, paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}