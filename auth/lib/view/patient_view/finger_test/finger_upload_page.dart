import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  PlatformFile? rightVideo;
  PlatformFile? leftVideo;
  bool loading = false;
  String? error;

  final api = ParkinsonApiService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> pickVideo({required bool isRightHand}) async {
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
        setState(() {
          error = 'لم نتمكن من قراءة ملف الفيديو. يرجى رفع فيديو جديد والالتزام بالتعليمات.';
        });
        return;
      }

      setState(() {
        if (isRightHand) {
          rightVideo = file;
        } else {
          leftVideo = file;
        }
        error = null;
      });
    } catch (_) {
      setState(() {
        error = 'حدثت مشكلة أثناء تحديد الفيديو. يرجى رفع فيديو جديد والالتزام بالتعليمات.';
      });
    }
  }

  Future<void> upload() async {
    if (rightVideo == null || leftVideo == null) {
      setState(() {
        error = 'من فضلك قم برفع فيديو لليد اليمنى وفيديو لليد اليسرى قبل بدء التحليل.';
      });
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
      final TestResult rightResult = await api.analyzeVideo(
        endpoint: AppConfig.fingerEndpoint,
        videoFile: rightVideo!,
      );

      final TestResult leftResult = await api.analyzeVideo(
        endpoint: AppConfig.fingerEndpoint,
        videoFile: leftVideo!,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FingerResultPage(
            rightResult: rightResult,
            leftResult: leftResult,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          loading = false;
          rightVideo = null;
          leftVideo = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error =
            'فشل الاتصال بالخادم (Failed to respond). من فضلك قم برفع فيديوهين جديدين واضحين لليد اليمنى واليسرى مع الالتزام بالتعليمات الموضحة في الأعلى.';
        loading = false;
      });
    }
  }

  String _fileSizeText(PlatformFile? file) {
    if (file == null || file.size <= 0) return '';
    final mb = file.size / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} ميجابايت';
  }

  bool get hasBothVideos => rightVideo != null && leftVideo != null;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(
          title: const Text('فحص حركة وتنسيق اليدين'),
          centerTitle: true,
          foregroundColor: Colors.black87,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF45B649)],
              ),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.back_hand,
                      size: 70,
                      color: Color(0xFF1E9BEF),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'اختبار لمس الأنف بالإصبع (Finger To Nose)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'قم برفع فيديو منفصل لليد اليمنى وفيديو منفصل لليد اليسرى. يجب أن تكون اليد واضحة أمام الكاميرا أثناء لمس الأنف بالإصبع بحركة منتظمة ليتم تحليل التنسيق الحركي لكل يد على حدة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _VideoPickerBox(
                      title: 'فيديو اليد اليمنى',
                      emptyText: 'اختر فيديو اليد اليمنى',
                      selectedVideo: rightVideo,
                      fileSizeText: _fileSizeText(rightVideo),
                      loading: loading,
                      accentColor: const Color(0xFF1E9BEF),
                      icon: Icons.pan_tool_alt_outlined,
                      onPick: () => pickVideo(isRightHand: true),
                    ),

                    if (rightVideo != null && !loading) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => pickVideo(isRightHand: true),
                          icon: const Icon(
                            Icons.swap_horiz,
                            color: Color(0xFF1E9BEF),
                          ),
                          label: const Text(
                            'اختيار فيديو بديل لليد اليمنى',
                            style: TextStyle(
                              color: Color(0xFF1E9BEF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    _VideoPickerBox(
                      title: 'فيديو اليد اليسرى',
                      emptyText: 'اختر فيديو اليد اليسرى',
                      selectedVideo: leftVideo,
                      fileSizeText: _fileSizeText(leftVideo),
                      loading: loading,
                      accentColor: const Color(0xFF45B649),
                      icon: Icons.back_hand_outlined,
                      onPick: () => pickVideo(isRightHand: false),
                    ),

                    if (leftVideo != null && !loading) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => pickVideo(isRightHand: false),
                          icon: const Icon(
                            Icons.swap_horiz,
                            color: Color(0xFF45B649),
                          ),
                          label: const Text(
                            'اختيار فيديو بديل لليد اليسرى',
                            style: TextStyle(
                              color: Color(0xFF45B649),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    if (loading)
                      const _LoadingBox()
                    else if (hasBothVideos)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E9BEF),
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
                            'تحليل اليد اليمنى واليسرى',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    else
                      const _WaitingForVideoBox(),

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
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFD97706),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                error!,
                                style: const TextStyle(
                                  color: Color(0xFF9A5B00),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.5,
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
  final String title;
  final String emptyText;
  final PlatformFile? selectedVideo;
  final String fileSizeText;
  final bool loading;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onPick;

  const _VideoPickerBox({
    required this.title,
    required this.emptyText,
    required this.selectedVideo,
    required this.fileSizeText,
    required this.loading,
    required this.accentColor,
    required this.icon,
    required this.onPick,
  });

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
          border: Border.all(
            color: hasVideo ? const Color(0xFF45B649) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasVideo
                    ? const Color(0xFFE6F8EC)
                    : accentColor.withOpacity(.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                hasVideo ? Icons.check_circle : icon,
                color: hasVideo ? const Color(0xFF1D9B50) : accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasVideo ? selectedVideo!.name : emptyText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasVideo
                        ? 'تم اختيار الفيديو بنجاح $fileSizeText'
                        : 'اضغط هنا لرفع فيديو الفحص المسجل بجهازك',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'قم برفع فيديو اليد اليمنى واليد اليسرى، وبعدها سيظهر لك زر التحليل.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'جاري رفع وتحليل فيديو اليد اليمنى واليد اليسرى...',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, height: 1.5),
          ),
        ],
      ),
    );
  }
}
