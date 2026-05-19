import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/test_result.dart';

class FingerResultPage extends StatefulWidget {
  final TestResult result;
  const FingerResultPage({super.key, required this.result});

  @override
  State<FingerResultPage> createState() => _FingerResultPageState();
}

class _FingerResultPageState extends State<FingerResultPage> {
  bool _isUploading = false;

  bool get isHealthy => widget.result.prediction == 'HEALTHY' || widget.result.label == 'HEALTHY';
  bool get hasConcern => !isHealthy && !widget.result.hasError;

  Future<void> _sendTestResultDirectly() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      DocumentSnapshot profile = await FirebaseFirestore.instance.collection('profiles').doc(user.uid).get();
      if (!profile.exists) return;

      String patientName = profile.get('name') ?? "Unknown";
      String doctorUid = profile.get('doctorUid') ?? "";

      // استخدام الـ Merge الآمن هنا لحقن النتيجة في كولكشن التقييمات للدكتور بدون كراش أو مسح بيانات
      await FirebaseFirestore.instance.collection('evaluations').doc(user.uid).set({
        'patientName': patientName,
        'patientUid': user.uid,
        'doctorUid': doctorUid,
        'lastUpdated': FieldValue.serverTimestamp(),
        'testResults': {
          'Finger_Prediction': widget.result.prediction ?? widget.result.label ?? "UNKNOWN",
        }
      }, SetOptions(merge: true));

      // إرسال الإشعار للطبيب المشرف
      await FirebaseFirestore.instance.collection('notifications').add({
        'doctorUid': doctorUid,
        'patientName': patientName,
        'message': 'أتم المريض $patientName اختبار تنسيق حركة اليد (Finger To Nose) بنجاح.',
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // المكان النهائي والشرعي لإغلاق صلاحية الاختبار للمريض في الجلسة الحالية
      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).update({
        'testsStatus.FingerToNose': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ النتيجة وإغلاق الاختبار بنجاح')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.result.hasError ? const Color(0xFFF59E0B) : isHealthy ? const Color(0xFF22A35A) : const Color(0xFFF59E0B);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(title: const Text('نتيجة حركة وتنسيق اليد'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 18)]),
              child: Column(
                children: [
                  Icon(widget.result.hasError ? Icons.error_outline : isHealthy ? Icons.check_circle_outline : Icons.info_outline, size: 72, color: statusColor),
                  const SizedBox(height: 12),
                  Text(widget.result.hasError ? 'تعذر إكمال التحليل' : (isHealthy ? 'حركة وتنسيق اليد طبيعي' : 'تم رصد اضطراب أو عدم انتظام في حركة الأصابع'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF4FAFF), borderRadius: BorderRadius.circular(18)), child: Column(children: [const Text('مؤشر التنسيق', style: TextStyle(color: Colors.grey, fontSize: 13)), const SizedBox(height: 6), Text(widget.result.score?.toStringAsFixed(2) ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))]))),
                      const SizedBox(width: 10),
                      Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF4FAFF), borderRadius: BorderRadius.circular(18)), child: Column(children: [const Text('نسبة الثقة', style: TextStyle(color: Colors.grey, fontSize: 13)), const SizedBox(height: 6), Text(widget.result.confidence == null ? '-' : '${widget.result.confidence!.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))]))),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: hasConcern ? const Color(0xFFFFF8E8) : const Color(0xFFF0FFF6), borderRadius: BorderRadius.circular(20), border: Border.all(color: hasConcern ? const Color(0xFFFFE0A3) : const Color(0xFFCDEFD8))),
              child: Text(hasConcern ? 'سيتم مشاركة القياسات الحركية للتنبؤ تلقائياً مع طبيبك المتابع.' : 'المؤشرات مطمئنة ومستقرة تماماً.', textAlign: TextAlign.center, style: TextStyle(color: hasConcern ? const Color(0xFF9A5B00) : const Color(0xFF087443), fontWeight: FontWeight.w800, height: 1.6)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _isUploading ? null : _sendTestResultDirectly,
              icon: _isUploading ? const SizedBox() : const Icon(Icons.send_and_archive, color: Colors.white),
              label: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("إرسال للدكتور وإنهاء الاختبار الفعلي", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}