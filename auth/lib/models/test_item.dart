import 'package:flutter/material.dart';

class TestItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String endpoint;
  final bool enabled;
  final bool completed;

  const TestItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.endpoint,
    this.enabled = true,
    this.completed = false,
  });
}
