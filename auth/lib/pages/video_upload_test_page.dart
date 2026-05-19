import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/test_item.dart';
import '../models/test_result.dart';
import '../services/parkinson_api_service.dart';

import '../view/widget/gradient_button.dart';
import 'test_result_page.dart';

class VideoUploadTestPage extends StatefulWidget {
  final TestItem item;
  const VideoUploadTestPage({super.key, required this.item});

  @override
  State<VideoUploadTestPage> createState() => _VideoUploadTestPageState();
}

class _VideoUploadTestPageState extends State<VideoUploadTestPage> {
  PlatformFile? selectedVideo;
  bool loading = false;
  String? error;
  final api = ParkinsonApiService();

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
        setState(() => error = 'لم نتمكن من قراءة الفيديو. من فضلك اختر فيديو آخر.');
        return;
      }

      setState(() {
        selectedVideo = file;
        error = null;
      });
    } catch (_) {
      setState(() => error = 'حدثت مشكلة أثناء اختيار الفيديو. حاول مرة أخرى.');
    }
  }

  Future<void> upload() async {
    final video = selectedVideo;
    if (video == null) {
      setState(() => error = 'من فضلك اختر فيديو الاختبار أولاً.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final TestResult result = await api.analyzeVideo(endpoint: widget.item.endpoint, videoFile: video);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => TestResultPage(result: result)));
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void resetSelectedVideo() {
    if (loading) return;
    setState(() {
      selectedVideo = null;
      error = null;
    });
  }

  String get fileSizeText {
    final size = selectedVideo?.size;
    if (size == null || size <= 0) return '';
    final mb = size / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} ميجابايت';
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = selectedVideo != null;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(
          title: Text(widget.item.title),
          centerTitle: true,
          elevation: 0,
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
                  children: [
                    Icon(widget.item.icon, size: 70, color: const Color(0xFF1E9BEF)),
                    const SizedBox(height: 18),
                    Text(
                      widget.item.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'اختر فيديو واضحاً للاختبار. لن يبدأ التحليل إلا بعد الضغط على زر تحليل الفيديو.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.7),
                    ),
                    const SizedBox(height: 18),
                    const _TipsBox(),
                    const SizedBox(height: 22),
                    _VideoPickerBox(
                      selectedVideo: selectedVideo,
                      fileSizeText: fileSizeText,
                      loading: loading,
                      onPick: pickVideo,
                    ),
                    if (hasVideo && !loading) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: pickVideo,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('اختيار فيديو آخر'),
                      ),
                    ],
                    const SizedBox(height: 22),
                    if (loading)
                      const _LoadingBox()
                    else if (hasVideo)
                      GradientButton(
                        text: 'تحليل الفيديو',
                        icon: Icons.analytics_outlined,
                        onPressed: upload,
                      )
                    else
                      const _WaitingForVideoBox(),
                    if (error != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFE0A3)),
                        ),
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF9A5B00), fontWeight: FontWeight.w700, height: 1.5),
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

class _TipsBox extends StatelessWidget {
  const _TipsBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF4FAFF), borderRadius: BorderRadius.circular(18)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('لأفضل نتيجة:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          SizedBox(height: 8),
          Text('• اجعل الإضاءة جيدة.', style: TextStyle(height: 1.5)),
          Text('• ثبّت الهاتف قدر الإمكان.', style: TextStyle(height: 1.5)),
          Text('• تأكد أن الحركة ظاهرة بوضوح في الفيديو.', style: TextStyle(height: 1.5)),
          Text('• يفضل أن يكون الفيديو قصيراً وواضحاً.', style: TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}

class _VideoPickerBox extends StatelessWidget {
  final PlatformFile? selectedVideo;
  final String fileSizeText;
  final bool loading;
  final VoidCallback onPick;

  const _VideoPickerBox({
    required this.selectedVideo,
    required this.fileSizeText,
    required this.loading,
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
                    hasVideo ? selectedVideo!.name : 'اختر فيديو الاختبار',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasVideo ? 'تم اختيار الفيديو ${fileSizeText.isEmpty ? '' : '($fileSizeText)'}' : 'اضغط هنا لاختيار الفيديو من جهازك',
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
        'بعد اختيار الفيديو سيظهر زر تحليل الفيديو هنا.',
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
            'جاري رفع الفيديو وتحليل الحركة... من فضلك لا تغلق الصفحة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            'قد يستغرق التحليل دقيقة أو أكثر حسب مدة الفيديو.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
          ),
        ],
      ),
    );
  }
}
