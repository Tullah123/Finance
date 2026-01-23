import 'package:flutter/material.dart';

class AppLayout {
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 12;
    if (width < 600) return 16;
    if (width < 900) return 24;
    return 32;
  }

  static double sectionGap(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 12;
    if (width < 600) return 16;
    return 20;
  }

  static double itemGap(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 8;
    return 12;
  }

  static double cardPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 720;
    if (width >= 600) return 560;
    return double.infinity;
  }

  static int gridCount(
    BuildContext context, {
    double minTileWidth = 110,
    int minCount = 2,
    int maxCount = 4,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final available = width - (horizontalPadding(context) * 2);
    final count = (available / minTileWidth).floor();
    return count.clamp(minCount, maxCount);
  }
}


