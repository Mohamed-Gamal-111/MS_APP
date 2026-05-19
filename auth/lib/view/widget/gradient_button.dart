import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool disabled;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.disabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: disabled ? null : onPressed,
      child: Ink(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: disabled
              ? null
              : const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF45B649)]),
          color: disabled ? const Color(0xFFBDBDBD) : null,
          boxShadow: disabled
              ? []
              : [BoxShadow(color: const Color(0xFF2196F3).withOpacity(.22), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 21),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
