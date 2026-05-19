import 'package:flutter/material.dart';
import '../core/app_config.dart';
import '../models/test_item.dart';
import '../view/widget/test_card.dart';
import 'video_upload_test_page.dart';

class TestsHomePage extends StatelessWidget {
  const TestsHomePage({super.key});

  // تم تفعيل جميع الاختبارات الثلاثة وحذف العناصر التجريبية الأخرى لتعمل فوراً عند فتحها
  List<TestItem> get tests => const [
    TestItem(
      title: 'تنسيق حركة اليد',
      subtitle: 'اختبار لمس الأنف بالإصبع',
      icon: Icons.back_hand,
      endpoint: AppConfig.fingerEndpoint,
    ),
    TestItem(
      title: 'اختبار الاتزان',
      subtitle: 'الوقوف بثبات لفترة قصيرة',
      icon: Icons.accessibility_new,
      endpoint: AppConfig.rombergEndpoint,
    ),
    TestItem(
      title: 'اختبار المشي',
      subtitle: 'المشي في خط مستقيم',
      icon: Icons.directions_walk,
      endpoint: AppConfig.tandemEndpoint,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, 26, 22, 8),
                child: Text(
                  'اختر الاختبار المناسب',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, 0, 22, 20),
                child: Text(
                  'يمكنك رفع فيديو قصير للاختبار، وسيتم عرض النتيجة بعد التحليل.',
                  style: TextStyle(fontSize: 15, color: Color(0xFF6B7280), height: 1.6),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = MediaQuery.sizeOf(context).width;
                  // عرض الأعمدة بشكل متناسق (3 أعمدة للشاشات الكبيرة وعمودين للصغيرة)
                  final crossAxisCount = width < 420 ? 2 : width < 760 ? 3 : 3;
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final item = tests[index];
                        return TestCard(
                          item: item,
                          index: index,
                          onTap: () {
                            // تم التأكد من إتاحة الانتقال لصفحة الرفع مباشرة بدون شروط مسبقة
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => VideoUploadTestPage(item: item)),
                            );
                          },
                        );
                      },
                      childCount: tests.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: .78,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF45B649)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        children: [
          Positioned(left: -30, top: 40, child: _Circle(size: 130)),
          Positioned(left: 90, top: 70, child: _Circle(size: 90)),

          // زر العودة للخلف مدمج بشكل متناسق مع التصميم للرجوع للرئيسية
          Positioned(
            top: 45,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Positioned(
            right: 28,
            bottom: 48,
            left: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'اختبارات الفيديو الحركة',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 12),
                Text(
                  'نفّذ الاختبار بهدوء، واختر فيديو واضحاً قدر الإمكان.',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  const _Circle({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.12)),
  );
}