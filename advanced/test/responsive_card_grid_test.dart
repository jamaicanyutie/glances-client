import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glances_client_advanced/ui/components/responsive_card_grid.dart';

void main() {
  /// Builds a [ResponsiveCardGrid] with [count] keyed, sized children inside
  /// a surface of [width]x[height] logical pixels and returns the laid-out
  /// rects, so tests can assert column counts purely from geometry.
  Future<List<Rect>> pumpGrid(
    WidgetTester tester, {
    required double width,
    required double height,
    int count = 4,
    List<Widget>? children,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveCardGrid(
            children: children ??
                <Widget>[
                  for (int i = 0; i < count; i++)
                    SizedBox(
                      key: ValueKey<int>(i),
                      height: 40,
                      child: const ColoredBox(color: Colors.black),
                    ),
                ],
          ),
        ),
      ),
    );

    final List<Rect> rects = <Rect>[];
    if (children == null) {
      for (int i = 0; i < count; i++) {
        rects.add(tester.getRect(find.byKey(ValueKey<int>(i))));
      }
    } else {
      for (int i = 0; i < children.length; i++) {
        rects.add(tester.getRect(find.byKey(ValueKey<int>(i))));
      }
    }
    return rects;
  }

  group('ResponsiveCardGrid column count', () {
    testWidgets('single column below the two-column breakpoint (portrait)',
        (WidgetTester tester) async {
      final List<Rect> rects = await pumpGrid(tester,
          width: 400, height: 800, count: 4);

      // All four cards share the same left edge and start x.
      expect(rects[0].left, rects[1].left);
      expect(rects[1].left, rects[2].left);
      expect(rects[2].left, rects[3].left);
      // Each card sits below the previous one.
      expect(rects[1].top, greaterThan(rects[0].bottom));
      expect(rects[2].top, greaterThan(rects[1].bottom));
      // Cards fill the full available width.
      expect(rects[0].width, closeTo(400, 0.01));
    });

    testWidgets('two columns between 600 and 1000 (landscape phone)',
        (WidgetTester tester) async {
      final List<Rect> rects = await pumpGrid(tester,
          width: 800, height: 400, count: 4);

      // First row: two side-by-side cards of equal width.
      expect(rects[0].left, 0);
      expect(rects[1].left, greaterThan(rects[0].right));
      expect(rects[0].width, closeTo(rects[1].width, 0.01));
      // Second row starts below the first.
      expect(rects[2].top, greaterThan(rects[0].bottom));
      expect(rects[2].left, 0);
      expect(rects[3].left, greaterThan(rects[2].right));
    });

    testWidgets('three columns at or above 1000 (tablet/wide)',
        (WidgetTester tester) async {
      final List<Rect> rects = await pumpGrid(tester,
          width: 1200, height: 800, count: 6);

      // First row: three cards.
      expect(rects[0].left, 0);
      expect(rects[1].left, greaterThan(rects[0].right));
      expect(rects[2].left, greaterThan(rects[1].right));
      // Fourth card wraps to the second row.
      expect(rects[3].top, greaterThan(rects[0].bottom));
      expect(rects[3].left, 0);
      // All first-row cards share the same width.
      expect(rects[0].width, closeTo(rects[1].width, 0.01));
      expect(rects[1].width, closeTo(rects[2].width, 0.01));
    });
  });

  group('ResponsiveCardGrid span', () {
    testWidgets('span() items always take the full row width',
        (WidgetTester tester) async {
      final List<Rect> rects = await pumpGrid(
        tester,
        width: 800,
        height: 600,
        children: <Widget>[
          ResponsiveCardGrid.span(
            const SizedBox(
              key: ValueKey<int>(0),
              height: 24,
            ),
          ),
          const SizedBox(
            key: ValueKey<int>(1),
            height: 40,
          ),
          const SizedBox(
            key: ValueKey<int>(2),
            height: 40,
          ),
        ],
      );

      final Rect header = rects[0];
      final Rect first = rects[1];
      final Rect second = rects[2];

      // Header spans the full width and sits on its own row.
      expect(header.width, closeTo(800, 0.01));
      expect(header.left, 0);
      // Regular cards below it reflow into two columns.
      expect(first.left, 0);
      expect(second.left, greaterThan(first.right));
    });
  });

  group('ResponsiveCardGrid spacing', () {
    testWidgets('custom spacing is honored between columns',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCardGrid(
              spacing: 40,
              children: <Widget>[
                SizedBox(
                  key: ValueKey<int>(0),
                  height: 40,
                  child: ColoredBox(color: Colors.black),
                ),
                SizedBox(
                  key: ValueKey<int>(1),
                  height: 40,
                  child: ColoredBox(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      );

      final Rect first = tester.getRect(find.byKey(const ValueKey<int>(0)));
      final Rect second = tester.getRect(find.byKey(const ValueKey<int>(1)));
      // With 2 columns and 40dp of spacing, each card is (800-40)/2 = 380 wide.
      expect(first.width, closeTo(380, 0.01));
      expect(second.left - first.right, closeTo(40, 0.01));
    });
  });
}
