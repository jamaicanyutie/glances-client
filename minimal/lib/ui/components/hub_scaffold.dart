import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'server_reset_button.dart';

/// One capability-filterable sub-tab inside a [HubScaffold].
class HubTab {
  const HubTab({
    required this.id,
    required this.label,
    required this.builder,
    this.capability,
  });

  /// Stable identifier used to match a deep-link `initialTabId`.
  final String id;

  /// TabBar label.
  final String label;

  /// Builds the tab page.
  final WidgetBuilder builder;

  /// Glances plugin name. The tab is hidden when the server does not report
  /// this plugin (see [hasPluginCapability]).
  final String? capability;
}

/// A domain hub screen: AppBar + horizontal [TabBar] + [TabBarView].
///
/// Hosts the root of a bottom-navigation branch. Sub-tabs whose plugin is
/// absent on the server (checked via [capabilitiesProvider]) are hidden; until
/// capabilities resolve the list falls back to showing every tab. When the
/// capability set first resolves (or later changes) the internal
/// [TabController] is rebuilt at the new length with the current index
/// clamped, so the active sub-tab survives a sub-tab being filtered out.
///
/// When every sub-tab is filtered out the TabBar is dropped and a muted
/// message is shown instead, so a host without the relevant plugin (e.g. no
/// Docker on the Services branch) degrades gracefully rather than blanking.
class HubScaffold extends ConsumerStatefulWidget {
  const HubScaffold({
    super.key,
    required this.title,
    required this.tabs,
    this.initialTabId,
  });

  /// AppBar title (e.g. `CPU`, `Services`).
  final String title;

  /// Every configured sub-tab, gated on [HubTab.capability] at runtime.
  final List<HubTab> tabs;

  /// Sub-tab to select initially. Falls back to the first tab when absent or
  /// filtered out.
  final String? initialTabId;

  @override
  ConsumerState<HubScaffold> createState() => _HubScaffoldState();
}

class _HubScaffoldState extends ConsumerState<HubScaffold>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  List<HubTab> _visible = const <HubTab>[];

  @override
  void initState() {
    super.initState();
    _visible = _computeVisible(ref.read(capabilitiesProvider));
    _controller = TabController(
      length: _visible.isEmpty ? 1 : _visible.length,
      vsync: this,
      initialIndex: _indexFor(_visible, widget.initialTabId),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<HubTab> _computeVisible(AsyncValue<Set<String>> capabilities) {
    return widget.tabs
        .where(
          (HubTab tab) =>
              tab.capability == null ||
              hasPluginCapability(capabilities, tab.capability!),
        )
        .toList();
  }

  static int _indexFor(List<HubTab> tabs, String? id) {
    if (id == null || tabs.isEmpty) {
      return 0;
    }
    final int index = tabs.indexWhere((HubTab tab) => tab.id == id);
    return index < 0 ? 0 : index;
  }

  static bool _sameTabs(List<HubTab> a, List<HubTab> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Set<String>> capabilities =
        ref.watch(capabilitiesProvider);
    final List<HubTab> visible = _computeVisible(capabilities);
    if (!_sameTabs(_visible, visible)) {
      // Capabilities resolved or changed: rebuild the controller at the new
      // length, clamping the current index so the active sub-tab survives.
      final List<HubTab> next = visible;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _visible = next;
          final int length = next.isEmpty ? 1 : next.length;
          final int index = _controller.index.clamp(0, length - 1);
          final TabController replacement = TabController(
            length: length,
            vsync: this,
            initialIndex: index,
          );
          _controller.dispose();
          _controller = replacement;
        });
      });
    }

    final bool empty = _visible.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const <Widget>[ServerResetButton()],
        bottom: empty
            ? null
            : TabBar(
                controller: _controller,
                isScrollable: true,
                tabs: <Widget>[
                  for (final HubTab tab in _visible) Tab(text: tab.label),
                ],
              ),
      ),
      body: empty
          ? const _NoDataView()
          : TabBarView(
              controller: _controller,
              children: <Widget>[
                for (final HubTab tab in _visible) tab.builder(context),
              ],
            ),
    );
  }
}

/// Centered muted message shown when every hub sub-tab was filtered out.
class _NoDataView extends StatelessWidget {
  const _NoDataView();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.info_outline,
              size: 32,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No data available',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}