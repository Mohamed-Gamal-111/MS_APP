import 'package:flutter/material.dart';
import '../../models/test_item.dart';

import 'gradient_button.dart';

class TestCard extends StatelessWidget {
  final TestItem item;
  final VoidCallback onTap;
  final int index;

  const TestCard({super.key, required this.item, required this.onTap, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index * 80)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: Opacity(opacity: value.clamp(0, 1), child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(.08), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 2),
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(color: const Color(0xFFF4FAFF), borderRadius: BorderRadius.circular(32)),
              child: Icon(item.icon, size: 32, color: item.enabled ? const Color(0xFF1E9BEF) : Colors.grey),
            ),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, height: 1.2),
            ),
            Text(
              item.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.3),
            ),
            GradientButton(
              text: item.enabled ? 'ابدأ الاختبار' : 'قريباً',
              disabled: item.completed || !item.enabled,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
