import 'package:flutter/material.dart';

class QuickAction {
  final String title;
  final String imageAsset;
  final VoidCallback onTap;

  QuickAction({
    required this.title,
    required this.imageAsset,
    required this.onTap,
  });
}
