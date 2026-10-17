import 'package:flutter/material.dart';

class AppResponsive {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext c) => MediaQuery.of(c).size.width < mobile;
  static bool isTablet(BuildContext c) => MediaQuery.of(c).size.width >= mobile && MediaQuery.of(c).size.width < desktop;
  static bool isDesktop(BuildContext c) => MediaQuery.of(c).size.width >= desktop;

  static int gridCols(BuildContext c, {int mobileCols = 2, int tabletCols = 3, int desktopCols = 4}) {
    final w = MediaQuery.of(c).size.width;
    if (w >= desktop) return desktopCols;
    if (w >= mobile) return tabletCols;
    return mobileCols;
  }

  static double contentMaxWidth(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    if (w >= 1400) return 1200;
    if (w >= desktop) return 1000;
    if (w >= tablet) return 720;
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext c) {
    if (isDesktop(c)) return const EdgeInsets.fromLTRB(24, 16, 24, 24);
    if (isTablet(c)) return const EdgeInsets.fromLTRB(20, 14, 20, 20);
    return const EdgeInsets.fromLTRB(16, 12, 16, 20);
  }
}

class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 1200});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int mobileCols;
  final int tabletCols;
  final int desktopCols;
  final double childAspectRatio;
  const AdaptiveGrid({super.key, required this.children, this.spacing = 12, this.runSpacing = 12, this.mobileCols = 2, this.tabletCols = 3, this.desktopCols = 4, this.childAspectRatio = 1.1});
  @override
  Widget build(BuildContext context) {
    final cols = AppResponsive.gridCols(context, mobileCols: mobileCols, tabletCols: tabletCols, desktopCols: desktopCols);
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: runSpacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: children,
    );
  }
}
