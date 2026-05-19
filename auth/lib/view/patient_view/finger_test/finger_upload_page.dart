import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_config.dart';
import '../../../models/test_result.dart';
import '../../../services/parkinson_api_service.dart';
import 'finger_result_page.dart';

class FingerUploadPage extends StatefulWidget {
  const FingerUploadPage({super.key});

  @override
  State<FingerUploadPage> createState() => _FingerUploadPageState();
}

class _FingerUploadPageState extends State<FingerUploadPage> {
  PlatformFile? video;
  bool loading = false;
  String? error;

  final api = ParkinsonApiService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> pickVideo() async {
    if (loading) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null || file.bytes!.isEmpty) {
        setState(() => error = 'لم نتمكن من قراءة ملف الفيديو. يرجى رفع فيديو جديد والالتزام بالتعليمات.');
        return;
      }

      setState(() {
        video = file;
        error = null;
      });
    } catch (_) {
      setState(() => error = 'حدثت مشكلة أثناء تحديد الفيديو. يرجى رفع فيديو جديد والالتزام بالتعليمات.');
    }
  }

  Future<void> upload() async {
    if (video == null) {
      setState(() => error = 'من فضلك قم باختيار فيديو اختبار حركة اليد أولاً.');
      return;
    }

    if (currentUser == null) {
      setState(() => error = 'خطأ: لم يتم العثور على حساب مريض نشط.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final TestResult result = await api.analyzeVideo(
        endpoint: AppConfig.fingerEndpoint,
        videoFile: video!,
      );

      final docRef = FirebaseFirestore.instance.collection('evaluations').doc(currentUser!.uid);

      await docRef.set({
        'doctorUid': '4PM43A2ahfR6fCZ1mlHTkaQIJXZ2', // مربوط بالـ UID الحقيقي للدكتور صلاح
        'patientUid': currentUser!.uid,
        'patientName': currentUser!.displayName ?? "Sara",
        'lastUpdated': FieldValue.serverTimestamp(),
        'testResults': {
          'Finger_Prediction': result.prediction ?? result.label ?? "UNKNOWN",
        }
      }, SetOptions(merge: true));

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FingerResultPage(result: result),
        ),
      );

      if (mounted) {
        setState(() {
          loading = false;
          video = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // رسالة الخطأ الذكية المخصصة عند فشل الرد أو الرفع
        error = 'فشل الاتصال بالخادم (Failed to respond). من فضلك قم برفع فيديو جديد يلتزم تماماً بالتعليمات الموضحة في الأعلى لإتمام الفحص بنجاح.';
        loading = false;
      });
    }
  }

  String get fileSizeText {
    if (video == null || video!.size <= 0) return '';
    final mb = video!.size / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} ميجابايت';
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = video != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(
          title: const Text('فحص حركة وتنسيق اليد'),
          centerTitle: true,
          foregroundColor: Colors.black87,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF45B649)]),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 18)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.back_hand, size: 70, color: Color(0xFF1E9BEF)),
                    const SizedBox(height: 18),
                    const Text(
                      'اختبار لمس الأنف بالإصبع (Finger To Nose)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ثبّت يدك أمام الكاميرا وقم بلمس الأنف بإصبعك بالتناوب وبحركة منتظمة ليقوم النظام بحساب التردد والسرعة والتوافق العضلي العصبي.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFF6B7280), height: 1.6),
                    ),
                    const SizedBox(height: 16),

                    // مربع رفع الفيديو الأساسي
                    _VideoPickerBox(
                      selectedVideo: video,
                      fileSizeText: fileSizeText,
                      loading: loading,
                      onPick: pickVideo,
                    ),

                    // حتة زرار استبدال المرفق الحالي المكتوب رجعت مكانه بالملي
                    if (hasVideo && !loading) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: pickVideo,
                        icon: const Icon(Icons.swap_horiz, color: Color(0xFF1E9BEF)),
                        label: const Text(
                          'اختيار فيديو بديل للمرفق الحالي',
                          style: TextStyle(color: Color(0xFF1E9BEF), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // إدارة حالة الأزرار وشاشة التحميل
                    if (loading)
                      const _LoadingBox()
                    else if (hasVideo)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E9BEF), // رجعتلك الزرار الأزرق الصريح المميز
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: upload,
                          icon: const Icon(Icons.analytics_outlined, size: 22),
                          label: const Text(
                            'تحليل حركة اليد وبدء الرفع',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      )
                    else
                      const _WaitingForVideoBox(),

                    // صندوق الأخطاء والتحذير من جودة الفيديو والالتزام بالتعليمات
                    if (error != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFE0A3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                error!,
                                style: const TextStyle(
                                    color: Color(0xFF9A5B00),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    height: 1.5
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPickerBox extends StatelessWidget {
  final PlatformFile? selectedVideo;
  final String fileSizeText;
  final bool loading;
  final VoidCallback onPick;
  const _VideoPickerBox({required this.selectedVideo, required this.fileSizeText, required this.loading, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final hasVideo = selectedVideo != null;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: loading ? null : onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasVideo ? const Color(0xFFF0FFF6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasVideo ? const Color(0xFF45B649) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasVideo ? const Color(0xFFE6F8EC) : const Color(0xFFF4F7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(hasVideo ? Icons.check_circle : Icons.video_file_outlined, color: hasVideo ? const Color(0xFF1D9B50) : const Color(0xFF1E9BEF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasVideo ? selectedVideo!.name : 'اختر فيديو اختبار تنسيق اليد',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasVideo ? 'تم التقاط مقطع الفحص بنجاح $fileSizeText' : 'اضغط هنا لرفع فيديو الفحص المسجل بجهازك',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_left, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _WaitingForVideoBox extends StatelessWidget {
  const _WaitingForVideoBox();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18)),
      child: const Text(
        'بمجرد تحديد المقطع المسجل، سيظهر لك خيار التحليل هنا.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700, height: 1.5),
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF4FAFF), borderRadius: BorderRadius.circular(18)),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'جاري رفع الفيديو وحساب معاملات التنسيق الحركي لـ (Finger To Nose)...',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, height: 1.5),
          ),
        ],
      ),
    );
  }
}