import 'package:flutter/widgets.dart';

/// Tracks imperative routes (bottom sheets, dialogs) pushed onto a branch
/// navigator so the shell can drop them *without* running their exit
/// animation.
///
/// go_router's indexed-stack shell wraps inactive branches in
/// `Offstage`/`TickerMode`, which stops ticking the moment a branch is left.
/// An animated `pop` of a modal sheet therefore freezes mid-animation and its
/// overlay remnant stays alive until the branch is revisited — making the card
/// flash back for a few milliseconds. Removing the route directly via
/// [NavigatorState.removeRoute] disposes the overlay immediately instead.
class SheetDismissingNavigatorObserver extends NavigatorObserver {
  /// Modal routes currently open on the observed navigator, keyed by the
  /// navigator they were pushed onto.
  ///
  /// The navigator identity guards [dismissAll]: if a branch navigator is ever
  /// swapped while a sheet is still open, routes owned by the disposed
  /// navigator are skipped instead of being fed to [NavigatorState.removeRoute]
  /// (which asserts the route is part of its history).
  final Map<Route<dynamic>, NavigatorState> _sheets =
      <Route<dynamic>, NavigatorState>{};

  /// Whether any modal route is currently tracked.
  bool get hasSheets => _sheets.isNotEmpty;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // The branch's own first route has no previous route; anything pushed on
    // top of it is an imperative overlay we want to be able to drop.
    if (previousRoute != null) {
      _sheets[route] = navigator!;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sheets.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sheets.remove(route);
  }

  /// Removes every tracked sheet route immediately, without running its exit
  /// animation, so no frozen overlay remnant can survive a tab switch.
  ///
  /// Safe to call when the navigator has been disposed: a missing navigator
  /// is a no-op.
  void dismissAll() {
    final NavigatorState? nav = navigator;
    if (nav == null) {
      _sheets.clear();
      return;
    }
    // Remove top-most first; only routes owned by the live navigator are
    // removed (stale entries from a disposed navigator are pruned instead).
    for (final MapEntry<Route<dynamic>, NavigatorState> entry
        in _sheets.entries.toList().reversed) {
      if (entry.value == nav) {
        nav.removeRoute(entry.key);
      }
    }
    _sheets.removeWhere(
      (Route<dynamic> route, NavigatorState owner) => owner == nav,
    );
  }
}
