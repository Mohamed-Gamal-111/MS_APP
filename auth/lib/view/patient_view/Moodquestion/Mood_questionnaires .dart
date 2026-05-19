import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HADSTestScreen extends StatefulWidget {
  const HADSTestScreen({super.key});

  @override
  _HADSTestScreenState createState() => _HADSTestScreenState();
}

class _HADSTestScreenState extends State<HADSTestScreen> {
  List<int> anxietyAnswers = List.filled(7, -1);
  List<int> depressionAnswers = List.filled(7, -1);

  int anxietyScore = 0;
  int depressionScore = 0;

  final List<Map<String, dynamic>> questions = [
    {'type': 'A', 'text': 'أشعر بالتوتر أو الشد الزائد', 'options': [{'text': 'معظم الوقت', 'score': 3}, {'text': 'كثير من الأوقات', 'score': 2}, {'text': 'من وقت لآخر', 'score': 1}, {'text': 'أبداً', 'score': 0}]},
    {'type': 'D', 'text': 'ما زلت أستمتع بالأشياء التي كنت أستمتع بها سابقاً', 'options': [{'text': 'تماماً كما كنت', 'score': 0}, {'text': 'ليس بنفس القدر', 'score': 1}, {'text': 'بقدر ضئيل فقط', 'score': 2}, {'text': 'تقريباً لا أستمتع بشيء', 'score': 3}]},
    {'type': 'A', 'text': 'ينتابني شعور بالخوف كأن شيئاً مفزعاً على وشك الحدوث', 'options': [{'text': 'بالتأكيد وبدرجة كبيرة', 'score': 3}, {'text': 'نعم ولكن ليس بشدة', 'score': 2}, {'text': 'قليلاً ولكن لا يزعجني', 'score': 1}, {'text': 'لا إطلاقاً', 'score': 0}]},
    {'type': 'D', 'text': 'أستطيع الضحك ورؤية الجانب المسلي من الأمور', 'options': [{'text': 'مثلما كنت أفعل دائماً', 'score': 0}, {'text': 'ليس بنفس القدر الآن', 'score': 1}, {'text': 'أقل من ذلك بكثير حالياً', 'score': 2}, {'text': 'لا أستطيع إطلاقاً', 'score': 3}]},
    {'type': 'A', 'text': 'تراودني أفكار مقلقة في ذهني', 'options': [{'text': 'معظم الوقت', 'score': 3}, {'text': 'كثير من الأوقات', 'score': 2}, {'text': 'من وقت لآخر', 'score': 1}, {'text': 'نادرًا جدًا', 'score': 0}]},
    {'type': 'D', 'text': 'أشعر بالسعادة والبهجة', 'options': [{'text': 'أبداً', 'score': 3}, {'text': 'نادرًا', 'score': 2}, {'text': 'أحياناً', 'score': 1}, {'text': 'معظم الوقت', 'score': 0}]},
    {'type': 'A', 'text': 'أستطيع الجلوس هادئاً والاسترخاء', 'options': [{'text': 'دائماً', 'score': 0}, {'text': 'عادةً', 'score': 1}, {'text': 'نادرًا', 'score': 2}, {'text': 'أبداً', 'score': 3}]},
    {'type': 'D', 'text': 'أشعر وكأن حركتي وتفكيري أصبحا بطيئين', 'options': [{'text': 'تقريباً طوال الوقت', 'score': 3}, {'text': 'كثير من الأوقات', 'score': 2}, {'text': 'أحياناً', 'score': 1}, {'text': 'أبداً', 'score': 0}]},
    {'type': 'A', 'text': 'ينتابني شعور مخيف كأنني "مضطرب" في معدتي', 'options': [{'text': 'أبداً', 'score': 0}, {'text': 'أحياناً', 'score': 1}, {'text': 'كثير من الأوقات', 'score': 2}, {'text': 'غالباً جداً', 'score': 3}]},
    {'type': 'D', 'text': 'فقدت اهتمامي بمظهري الشخصي', 'options': [{'text': 'بالتأكيد', 'score': 3}, {'text': 'لم أعد أهتم به كما يجب', 'score': 2}, {'text': 'ربما أهتم أقل قليلاً', 'score': 1}, {'text': 'ما زلت أهتم به كما كنت', 'score': 0}]},
    {'type': 'A', 'text': 'أشعر بحالة من عدم الاستقرار وكأنني يجب أن أتحرك باستمرار', 'options': [{'text': 'بدرجة كبيرة جداً', 'score': 3}, {'text': 'بدرجة كبيرة', 'score': 2}, {'text': 'ليس كثيراً', 'score': 1}, {'text': 'لا إطلاقاً', 'score': 0}]},
    {'type': 'D', 'text': 'أتطلع بشوق للاستمتاع بالأشياء القادمة', 'options': [{'text': 'مثلما كنت أفعل دائماً', 'score': 0}, {'text': 'أقل قليلاً مما كنت', 'score': 1}, {'text': 'أقل بكثير مما كنت', 'score': 2}, {'text': 'نادرًا جدًا', 'score': 3}]},
    {'type': 'A', 'text': 'ينتابني شعور مفاجئ بالذعر', 'options': [{'text': 'غالباً جداً', 'score': 3}, {'text': 'كثير من الأوقات', 'score': 2}, {'text': 'ليس كثيراً', 'score': 1}, {'text': 'أبداً', 'score': 0}]},
    {'type': 'D', 'text': 'أستطيع الاستمتاع بقراءة كتاب أو برنامج إذاعي أو تلفزيوني', 'options': [{'text': 'غالباً', 'score': 0}, {'text': 'أحياناً', 'score': 1}, {'text': 'نادرًا', 'score': 2}, {'text': 'نادرًا جدًا', 'score': 3}]},
  ];

  void calculateScores() {
    setState(() {
      anxietyScore = anxietyAnswers.where((e) => e != -1).fold(0, (a, b) => a + b);
      depressionScore = depressionAnswers.where((e) => e != -1).fold(0, (a, b) => a + b);
    });
  }

  // 🔥 الدالة الشاملة: رفع النتائج المجمعة + سجل التاريخ + إشعار الدكتور + قفل التيست
  Future<void> _submitHADSFinal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. جلب بيانات المريض والدكتور
      DocumentSnapshot profile = await FirebaseFirestore.instance.collection('profiles').doc(user.uid).get();
      if (!profile.exists) return;

      String patientName = profile.get('name') ?? "Unknown";
      String doctorUid = profile.get('doctorUid') ?? "";

      // 2. تحديث وثيقة النتائج المجمعة (Merge) لجدول الطبيب
      await FirebaseFirestore.instance.collection('evaluations').doc(user.uid).set({
        'patientName': patientName,
        'patientUid': user.uid,
        'doctorUid': doctorUid,
        'lastUpdated': FieldValue.serverTimestamp(),
        'testResults': {
          'HADS_Anxiety': anxietyScore,
          'HADS_Depression': depressionScore,
        }
      }, SetOptions(merge: true));

      // 3. إضافة سجل مستقل في التاريخ (History)
      await FirebaseFirestore.instance.collection('evaluations_history').add({
        'patientUid': user.uid,
        'patientName': patientName,
        'doctorUid': doctorUid,
        'testName': 'HADS (Mood Questionnaire)',
        'testResults': {
          'anxiety': anxietyScore,
          'depression': depressionScore,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 4. إرسال إشعار للدكتور
      await FirebaseFirestore.instance.collection('notifications').add({
        'doctorUid': doctorUid,
        'patientUid': user.uid,
        'patientName': patientName,
        'message': 'أتم المريض $patientName استبيان الحالة المزاجية (HADS)',
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 5. 🔥 قفل حالة هذا الاختبار في بروفايل المريض لهذه الجلسة
      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).update({
        'testsStatus.Mood': false, 
      });

    } catch (e) {
      debugPrint("Error in HADS submission: $e");
    }
  }

  void _showFinishAlert() {
    if (anxietyAnswers.contains(-1) || depressionAnswers.contains(-1)) {
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
            const Text("تم إكمال التقييم بنجاح", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("سيتم إرسال النتائج للدكتور وقفل الاختبار لهذه الجلسة.", textAlign: TextAlign.center),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await _submitHADSFinal();
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
        title: const Text('تقييم الحالة المزاجية', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final isAnxiety = q['type'] == 'A';
                  final qIndex = _getQuestionIndex(index, q['type']);
                  return HADSQuestionCard(
                    questionNumber: index + 1,
                    questionData: q,
                    selectedScore: isAnxiety ? anxietyAnswers[qIndex] : depressionAnswers[qIndex],
                    onChanged: (score) {
                      setState(() {
                        if (isAnxiety) anxietyAnswers[qIndex] = score;
                        else depressionAnswers[qIndex] = score;
                      });
                      calculateScores();
                    },
                  );
                },
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF4DB6E1)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'من فضلك اقرأ كل عبارة واختبر الإجابة التي تصف شعورك خلال الأسبوع الماضي.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, height: 1.5, fontWeight: FontWeight.w500),
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

  int _getQuestionIndex(int fullIndex, String type) {
    int count = 0;
    for (int i = 0; i < fullIndex; i++) {
      if (questions[i]['type'] == type) count++;
    }
    return count;
  }
}

class HADSQuestionCard extends StatelessWidget {
  final int questionNumber;
  final Map<String, dynamic> questionData;
  final int selectedScore;
  final Function(int) onChanged;
  const HADSQuestionCard({super.key, required this.questionNumber, required this.questionData, required this.selectedScore, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('سؤال $questionNumber', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(questionData['text'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
          const SizedBox(height: 15),
          ...List.generate(questionData['options'].length, (index) {
            final option = questionData['options'][index];
            bool isSelected = selectedScore == option['score'];
            return GestureDetector(
              onTap: () => onChanged(option['score']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.blue : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.blue : Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(option['text'], style: TextStyle(color: isSelected ? Colors.blue : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}