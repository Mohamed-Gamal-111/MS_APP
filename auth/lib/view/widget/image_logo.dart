import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final String img;
  // يمكنك زيادة هذا الرقم إذا أردت الدائرة نفسها أكبر في الشاشة
  final double size;

  const LogoWidget({
    super.key,
    required this.img,
    this.size = 180.0, // جعلت الحجم الافتراضي أكبر قليلاً (كان 150)
  });

  @override
  Widget build(BuildContext context) {
    // نستخدم Container لتحديد حجم ثابت للدائرة
    return SizedBox(
      width: size,
      height: size,
      // ClipOval: هو المسؤول عن قص الصورة لتصبح دائرية
      child: ClipOval(
        child: Image.asset(
          img,
          // 🔥 هذا هو السطر الأهم 🔥
          // BoxFit.cover: يضمن أن الصورة تملأ الدائرة بالكامل وتخفي أي خلفية
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}