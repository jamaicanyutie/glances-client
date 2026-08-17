import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../theme/theme.dart';
import 'settings_button.dart';

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

/// A scrollable wrapper for sub-tab pages whose body is a compact `Column`
/// (e.g. the metric-sheet bodies reused as sub-tabs). Gives them the standard
/// content padding and lets them scroll when they overflow.
class SheetTabBody extends StatelessWidget {
  const SheetTabBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}

/// A domain hub screen: AppBar + horizontal [TabBar] + [TabBarView].
///
/// Hosts the root of a bottom-navigation branch. Sub-tabs whose plugin is
/// absent on the server (checked via [capabilitiesProvider]) are hidden; until
/// capabilities resolve the list falls back to showing every tab. When the
/// capability set first resolves (or later changes) the internal
/// [TabController] is rebuilt at the new length with the current index
/// clamped, so deep-linked tabs survive a sub-tab being filtered out.
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

  /// Sub-tab to select initially (used by nested deep-link routes). Falls
  /// back to the first tab when absent or filtered out.
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
        actions: const <Widget>[SettingsButton()],
        bottom: TabBar(
          controller: _controller,
          isScrollable: true,
          tabs: empty
              ? const <Widget>[Tab(text: '')]
              : <Widget>[for (final HubTab tab in _visible) Tab(text: tab.label)],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: empty
            ? const <Widget>[SizedBox.shrink()]
            : <Widget>[for (final HubTab tab in _visible) tab.builder(context)],
      ),
    );
  }
}