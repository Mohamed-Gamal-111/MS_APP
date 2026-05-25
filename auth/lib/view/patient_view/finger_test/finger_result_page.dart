import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/test_result.dart';

class FingerResultPage extends StatefulWidget {
  final TestResult rightResult;
  final TestResult leftResult;

  const FingerResultPage({
    super.key,
    required this.rightResult,
    required this.leftResult,
  });

  @override
  State<FingerResultPage> createState() => _FingerResultPageState();
}

class _FingerResultPageState extends State<FingerResultPage> {
  bool _isUploading = false;

  bool _isHealthy(TestResult result) {
    return result.prediction == 'HEALTHY' || result.label == 'HEALTHY';
  }

  bool get hasConcern {
    return (!_isHealthy(widget.rightResult) && !widget.rightResult.hasError) ||
        (!_isHealthy(widget.leftResult) && !widget.leftResult.hasError);
  }

  String _resultValue(TestResult result) {
    return result.prediction ?? result.label ?? 'UNKNOWN';
  }

  Future<void> _sendTestResultDirectly() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final DocumentSnapshot profile = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();

      if (!profile.exists) return;

      final String patientName = profile.get('name') ?? 'Unknown';
      final String doctorUid = profile.get('doctorUid') ?? '';

      await FirebaseFirestore.instance.collection('evaluations').doc(user.uid).set({
        'patientName': patientName,
        'patientUid': user.uid,
        'doctorUid': doctorUid,
        'lastUpdated': FieldValue.serverTimestamp(),
        'testResults': {
          'Finger_Right': _resultValue(widget.rightResult),
          'Finger_Left': _resultValue(widget.leftResult),
        }
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('notifications').add({
        'doctorUid': doctorUid,
        'patientName': patientName,
        'message':
            'أتم المريض $patientName اختبار تنسيق حركة اليدين (Finger To Nose) بنجاح.',
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).update({
        'testsStatus.FingerToNose': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ نتيجة اليد اليمنى واليسرى وإغلاق الاختبار بنجاح')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(
          title: const Text('نتيجة حركة وتنسيق اليدين'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 14),
            _buildHandResult(
              title: 'نتيجة اليد اليمنى',
              result: widget.rightResult,
              color: const Color(0xFF1E9BEF),
              icon: Icons.pan_tool_alt_outlined,
            ),
            const SizedBox(height: 14),
            _buildHandResult(
              title: 'نتيجة اليد اليسرى',
              result: widget.leftResult,
              color: const Color(0xFF45B649),
              icon: Icons.back_hand_outlined,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasConcern
                    ? const Color(0xFFFFF8E8)
                    : const Color(0xFFF0FFF6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasConcern
                      ? const Color(0xFFFFE0A3)
                      : const Color(0xFFCDEFD8),
                ),
              ),
              child: Text(
                hasConcern
                    ? 'سيتم مشاركة قياسات اليد اليمنى واليسرى مع طبيبك المتابع لمراجعة التنسيق الحركي.'
                    : 'المؤشرات الخاصة باليد اليمنى واليسرى مطمئنة ومستقرة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hasConcern
                      ? const Color(0xFF9A5B00)
                      : const Color(0xFF087443),
                  fontWeight: FontWeight.w800,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isUploading ? null : _sendTestResultDirectly,
              icon: _isUploading
                  ? const SizedBox()
                  : const Icon(Icons.send_and_archive, color: Colors.white),
              label: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'إرسال النتيجتين للدكتور وإنهاء الاختبار',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 72,
            color: Color(0xFF1E9BEF),
          ),
          SizedBox(height: 12),
          Text(
            'تحليل تنسيق حركة اليدين',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'تم تحليل فيديو اليد اليمنى وفيديو اليد اليسرى بشكل منفصل لعرض نتيجة كل يد بوضوح.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandResult({
    required String title,
    required TestResult result,
    required Color color,
    required IconData icon,
  }) {
    final bool healthy = _isHealthy(result);
    final bool hasError = result.hasError;
    final Color statusColor = hasError
        ? const Color(0xFFF59E0B)
        : healthy
            ? const Color(0xFF22A35A)
            : const Color(0xFFF59E0B);

    final String titleText = hasError
        ? 'تعذر إكمال التحليل'
        : healthy
            ? 'الحركة طبيعية'
            : 'تم رصد اضطراب أو عدم انتظام';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Icon(
                hasError
                    ? Icons.error_outline
                    : healthy
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                color: statusColor,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  label: 'مؤشر التنسيق',
                  value: result.score?.toStringAsFixed(2) ?? '-',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  label: 'نسبة الثقة',
                  value: result.confidence == null
                      ? '-'
                      : '${result.confidence!.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
