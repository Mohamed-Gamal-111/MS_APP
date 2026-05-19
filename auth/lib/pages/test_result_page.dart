import 'package:flutter/material.dart';
import '../models/test_result.dart';

class TestResultPage extends StatelessWidget {
  final TestResult result;
  const TestResultPage({super.key, required this.result});

  bool get isHealthy => result.prediction == 'HEALTHY' || result.label == 'HEALTHY';
  bool get hasConcern => !isHealthy && !result.hasError;

  @override
  Widget build(BuildContext context) {
    final statusColor = result.hasError
        ? const Color(0xFFF59E0B)
        : isHealthy
        ? const Color(0xFF22A35A)
        : const Color(0xFFF59E0B);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(
          title: const Text('نتيجة الاختبار'),
          centerTitle: true,
          foregroundColor: Colors.black87,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF45B649)]),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _MainResultCard(result: result, statusColor: statusColor),
            const SizedBox(height: 14),
            _DoctorNoteBox(hasConcern: hasConcern),
            if (result.error != null && result.error!.isNotEmpty)
              _Section(
                title: 'تفاصيل المشكلة',
                children: [Text(_friendlyError(result.error!), style: const TextStyle(color: Color(0xFF9A5B00), fontWeight: FontWeight.w700, height: 1.5))],
              ),
            if (result.warning != null && result.warning!.isNotEmpty)
              _Section(
                title: 'ملاحظة مهمة',
                children: [Text(result.warning!, style: const TextStyle(color: Color(0xFF9A5B00), fontWeight: FontWeight.w700, height: 1.5))],
              ),
            if (result.features.isNotEmpty || result.chartData.isNotEmpty)
              _TechnicalDetailsSection(result: result),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة الاختبار'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _friendlyError(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('landmarks') || lower.contains('visible') || lower.contains('detected')) {
      return 'لم نتمكن من قراءة الحركة بوضوح. تأكد أن الجزء المطلوب ظاهر في الفيديو، ثم حاول مرة أخرى.';
    }
    return value;
  }

  static String _predictionText(String? value) {
    switch (value) {
      case 'HEALTHY':
        return 'النتيجة مطمئنة';
      case 'PATIENT':
      case 'PARKINSON':
        return 'تم رصد بعض الملاحظات أثناء الاختبار';
      default:
        return value ?? 'لا توجد نتيجة واضحة';
    }
  }

  static String _predictionDescription(TestResult result) {
    final isHealthy = result.prediction == 'HEALTHY' || result.label == 'HEALTHY';
    if (result.hasError) return 'لم نتمكن من إكمال التحليل. حاول إعادة الاختبار بفيديو أوضح.';
    if (isHealthy) return 'الحركة في هذا الاختبار تبدو ضمن النطاق المطمئن.';
    return 'يفضل مشاركة النتيجة مع الطبيب المختص للاطمئنان والمتابعة.';
  }

  static String _testName(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('finger')) return 'اختبار لمس الأنف بالإصبع';
    if (lower.contains('romberg')) return 'اختبار الاتزان';
    if (lower.contains('tandem')) return 'اختبار المشي المتتابع';
    return value;
  }

  static String _numText(num? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  static String _prettyKey(String key) {
    const names = {
      'Main_Freq_Hz': 'التردد الأساسي للحركة',
      'Jitter': 'تذبذب الحركة',
      'Max_Dist_Error': 'أكبر فرق في المسافة',
      'Smoothness_Acc': 'نعومة الحركة',
      'Path_Spread_X': 'انتشار الحركة أفقيًا',
      'Path_Spread_Y': 'انتشار الحركة رأسيًا',
      'Velocity_Std': 'تغير السرعة',
      'Signal_Entropy': 'عدم انتظام الإشارة',
      'distance_signal': 'إشارة المسافة',
      'velocity_signal': 'إشارة السرعة',
      'shoulder_tilt_signal': 'ميل الكتف',
      'hip_tilt_signal': 'ميل الحوض',
      'hip_sway_signal': 'تأرجح الحوض',
      'spine_lateral_signal': 'ميل العمود الجانبي',
    };
    return names[key] ?? key.replaceAll('_', ' ');
  }
}

class _MainResultCard extends StatelessWidget {
  final TestResult result;
  final Color statusColor;
  const _MainResultCard({required this.result, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final isHealthy = result.prediction == 'HEALTHY' || result.label == 'HEALTHY';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 18)],
      ),
      child: Column(
        children: [
          Icon(
            result.hasError
                ? Icons.error_outline
                : isHealthy
                ? Icons.check_circle_outline
                : Icons.info_outline,
            size: 72,
            color: statusColor,
          ),
          const SizedBox(height: 12),
          Text(
            TestResultPage._testName(result.test),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            result.hasError ? 'تعذر إكمال التحليل' : TestResultPage._predictionText(result.prediction ?? result.label),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            TestResultPage._predictionDescription(result),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280), height: 1.6),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(title: 'درجة الأداء الحركي', value: TestResultPage._numText(result.score)),
              const SizedBox(width: 10),
              _Stat(title: 'نسبة الثقة', value: result.confidence == null ? '-' : '${TestResultPage._numText(result.confidence)}%'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'نسبة الثقة توضح مدى ثقة النموذج في التحليل، وليست تشخيصاً طبياً.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.4),
          ),
          if (result.framesUsed != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _WideStat(title: 'عدد اللقطات التي تم تحليلها', value: result.framesUsed.toString()),
            ),
        ],
      ),
    );
  }
}

class _DoctorNoteBox extends StatelessWidget {
  final bool hasConcern;
  const _DoctorNoteBox({required this.hasConcern});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasConcern ? const Color(0xFFFFF8E8) : const Color(0xFFF0FFF6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasConcern ? const Color(0xFFFFE0A3) : const Color(0xFFCDEFD8)),
      ),
      child: Text(
        hasConcern
            ? 'هذه النتيجة للمساعدة فقط. من الأفضل مشاركة التقرير مع الطبيب المختص للاطمئنان.'
            : 'هذه النتيجة مطمئنة، ومع ذلك لا تغني عن المتابعة الطبية عند الحاجة.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: hasConcern ? const Color(0xFF9A5B00) : const Color(0xFF087443),
          fontWeight: FontWeight.w800,
          height: 1.6,
        ),
      ),
    );
  }
}

class _TechnicalDetailsSection extends StatelessWidget {
  final TestResult result;
  const _TechnicalDetailsSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: const Text('عرض التفاصيل التقنية للطبيب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          subtitle: const Text('هذه البيانات اختيارية وليست ضرورية للمريض.'),
          children: [
            if (result.features.isNotEmpty) ...[
              const Align(alignment: Alignment.centerRight, child: Text('مؤشرات الحركة', style: TextStyle(fontWeight: FontWeight.w900))),
              const SizedBox(height: 8),
              ...result.features.entries.map((e) => _KeyValue(k: TestResultPage._prettyKey(e.key), v: e.value.toString())),
            ],
            if (result.chartData.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Align(alignment: Alignment.centerRight, child: Text('بيانات الحركة', style: TextStyle(fontWeight: FontWeight.w900))),
              const SizedBox(height: 8),
              ...result.chartData.entries.map((e) => _KeyValue(k: TestResultPage._prettyKey(e.key), v: 'عدد النقاط: ${(e.value is List) ? (e.value as List).length : '-'}')),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String title, value;
  const _Stat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF4FAFF), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    ),
  );
}

class _WideStat extends StatelessWidget {
  final String title, value;
  const _WideStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFF4FAFF), borderRadius: BorderRadius.circular(18)),
    child: Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700))),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 18),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _KeyValue extends StatelessWidget {
  final String k, v;
  const _KeyValue({required this.k, required this.v});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800))),
        const SizedBox(width: 8),
        Flexible(child: Text(v, textAlign: TextAlign.left)),
      ],
    ),
  );
}