import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Responsive grid that reflows its children into multiple columns when the
/// available width allows it (landscape phones, tablets, wide windows) instead
/// of stretching every card to full width.
///
/// Column count is width-driven:
///  - below [twoColumnBreakpoint] (600 dp) → 1 column (portrait phones, the
///    original layout)
///  - [twoColumnBreakpoint] to [threeColumnBreakpoint] → 2 columns
///  - at or above [threeColumnBreakpoint] (1000 dp) → 3 columns
///
/// Children keep their intrinsic heights (a [Wrap], not a [GridView]), so
/// cards of different heights sit naturally next to each other and the layout
/// adapts automatically on every rotation/resize via [LayoutBuilder]. Items
/// that must always span the full row (section headers, overview cards)
/// should be wrapped with [span].
class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
    this.twoColumnBreakpoint = 600,
    this.threeColumnBreakpoint = 1000,
  });

  /// Children to lay out in the grid. Wrap full-width items with [span].
  final List<Widget> children;

  /// Gap between grid cells on both axes.
  final double spacing;

  /// Minimum available width (dp) before a second column appears.
  final double twoColumnBreakpoint;

  /// Minimum available width (dp) before a third column appears.
  final double threeColumnBreakpoint;

  /// Marks [child] as a full-width grid item.
  static Widget span(Widget child) => _SpanGridItem(child: child);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int columns = width >= threeColumnBreakpoint
            ? 3
            : width >= twoColumnBreakpoint
                ? 2
                : 1;
        final double itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final Widget child in children)
              if (child is _SpanGridItem)
                SizedBox(width: width, child: child.child)
              else
                SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Marker wrapper for grid items that span the full row width.
class _SpanGridItem extends StatelessWidget {
  const _SpanGridItem({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
