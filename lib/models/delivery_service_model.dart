import 'package:flutter/material.dart';

class DeliveryService {
  final String id;
  final String name;
  final String subtitle;
  final String? imageAssetPath;    // Path to your SVG asset
  final IconData icon;

  DeliveryService({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imageAssetPath,
    required this.icon,
  });
}
