import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../constants/responsive_constants.dart';

class ResponsiveLayout {
  const ResponsiveLayout._();

  static double appBarTitleHeight(TextScaler textScaler) =>
      math.max(65.0, textScaler.scale(26) + 32);

  static double searchFieldHeight(TextScaler textScaler) =>
      math.max(65.0, textScaler.scale(16) + 49);

  static NewsGridLayout newsGrid({
    required double availableWidth,
    required TextScaler textScaler,
  }) {
    final textScale = math.max(1.0, textScaler.scale(16) / 16);
    final isTablet = availableWidth >= ResponsiveConstants.tabletBreakpoint;
    final isWideTablet =
        availableWidth >= ResponsiveConstants.wideTabletBreakpoint;

    final columns = textScale >= ResponsiveConstants.appBarTextScaleBreakpoint
        ? 1
        : isWideTablet
        ? 3
        : isTablet
        ? 2
        : 1;
    final baseCardExtent = isTablet
        ? ResponsiveConstants.tabletArticleExtent
        : ResponsiveConstants.phoneArticleExtent;

    return NewsGridLayout(
      columns: columns,
      cardExtent:
          baseCardExtent +
          (textScale - 1) * ResponsiveConstants.extraCardHeightPerScale,
    );
  }
}

class NewsGridLayout {
  final int columns;
  final double cardExtent;

  const NewsGridLayout({required this.columns, required this.cardExtent});
}
