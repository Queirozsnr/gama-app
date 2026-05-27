import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum MobileTopBarStyle { light, dark }

/// Slot that each screen fills to inject content into the shared topbar.
class TopBarSlot {
  const TopBarSlot({
    this.pageTitle,
    this.desktopSubtitle,
    this.leading,
    this.action,
    this.mobileAction,
    this.mobileStyle = MobileTopBarStyle.light,
    this.mobileSubtitle,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
  });

  /// Overrides the route-based pageTitle in GamaTopBar when set.
  final String? pageTitle;

  /// Small text below the title on desktop (e.g. "OFICINA CENTRAL · 412 SKUs").
  final String? desktopSubtitle;

  /// Widget shown before the title (e.g. a back button).
  final Widget? leading;

  final Widget? action;

  /// Trailing widget(s) for mobile. Pass a Row for multiple buttons.
  final Widget? mobileAction;

  /// Dark (detail pages) or light (forms/wizards). Default: light.
  final MobileTopBarStyle mobileStyle;

  /// Small text above the title on mobile (e.g. "OS #1247" or "ORDENS / NOVA").
  final String? mobileSubtitle;

  final TextEditingController? searchController;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;

  bool get hasSearch => searchController != null || onSearchChanged != null;
  bool get hasContent =>
      pageTitle != null || leading != null || action != null || hasSearch;
}

/// Stack-based notifier: each screen pushes its slot on mount and pops on
/// dispose. The topbar always reflects the top of the stack — no animation
/// listeners, no restore timing, no race conditions.
class TopBarNotifier extends ChangeNotifier {
  final _stack = <TopBarSlot>[];

  TopBarSlot? get slot => _stack.isEmpty ? null : _stack.last;

  void push(TopBarSlot slot) {
    _stack.add(slot);
    _notify();
  }

  /// Replaces [old] in the stack with [next] (matched by identity).
  /// Falls back to push if [old] is not found (e.g. notifier was reassigned).
  void replace(TopBarSlot old, TopBarSlot next) {
    final idx = _stack.lastIndexOf(old);
    if (idx >= 0) {
      _stack[idx] = next;
    } else {
      _stack.add(next);
    }
    _notify();
  }

  void pop(TopBarSlot slot) {
    if (_stack.remove(slot)) _notify();
  }

  // Defers notifyListeners when called during the build phase to avoid
  // "setState called during build" / _dependents assertion errors.
  void _notify() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!hasListeners) return;
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }
}

/// InheritedNotifier that makes [TopBarNotifier] available to descendants.
class TopBarScope extends InheritedNotifier<TopBarNotifier> {
  const TopBarScope({
    super.key,
    required TopBarNotifier super.notifier,
    required super.child,
  });

  /// Subscribes the caller to rebuild when the notifier changes.
  /// Use this in widgets that display topbar content (e.g. GamaTopBar).
  static TopBarNotifier? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TopBarScope>()
        ?.notifier;
  }

  /// Reads the notifier WITHOUT subscribing. Use in [TopBarSlotMixin] to
  /// avoid a circular rebuild loop (slot change → didChangeDependencies →
  /// setTopBarSlot → slot change → …).
  static TopBarNotifier? readOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<TopBarScope>()
        ?.notifier;
  }
}

/// Drop-in widget that sets a [TopBarSlot] while it is mounted.
/// Useful for ConsumerWidget (stateless) screens that can't use the mixin.
class TopBarSlotProvider extends StatefulWidget {
  const TopBarSlotProvider({
    super.key,
    required this.slot,
    required this.child,
  });

  final TopBarSlot slot;
  final Widget child;

  @override
  State<TopBarSlotProvider> createState() => _TopBarSlotProviderState();
}

class _TopBarSlotProviderState extends State<TopBarSlotProvider>
    with TopBarSlotMixin<TopBarSlotProvider> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setTopBarSlot(widget.slot);
  }

  @override
  void didUpdateWidget(TopBarSlotProvider old) {
    super.didUpdateWidget(old);
    setTopBarSlot(widget.slot);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Provides one [TopBarNotifier] per shell branch so screens in inactive
/// branches don't pollute the active branch's topbar slot.
class BranchTopBarScope extends InheritedWidget {
  const BranchTopBarScope({
    super.key,
    required this.notifiers,
    required super.child,
  });

  final List<TopBarNotifier> notifiers;

  // Use get (not dependOn) — the list is stable and we don't need rebuilds.
  static List<TopBarNotifier> of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<BranchTopBarScope>()!.notifiers;

  @override
  bool updateShouldNotify(BranchTopBarScope old) => notifiers != old.notifiers;
}

/// Mixin for ConsumerStatefulWidget states to easily manage topbar slot.
///
/// Call [setTopBarSlot] whenever the slot content changes. The mixin pushes
/// the slot onto [TopBarNotifier]'s stack on first call and replaces it on
/// subsequent calls. On dispose the slot is popped — no animation listeners
/// or manual restore logic needed.
mixin TopBarSlotMixin<T extends StatefulWidget> on State<T> {
  TopBarNotifier? _topBarNotifier;
  TopBarSlot? _activeSlot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use readOf (no subscription) to avoid a circular rebuild loop where
    // slot changes trigger didChangeDependencies which re-pushes the slot.
    _topBarNotifier = TopBarScope.readOf(context);
  }

  void setTopBarSlot(TopBarSlot slot) {
    if (_activeSlot == null) {
      _topBarNotifier?.push(slot);
    } else {
      _topBarNotifier?.replace(_activeSlot!, slot);
    }
    _activeSlot = slot;
  }

  @override
  void dispose() {
    if (_activeSlot != null) _topBarNotifier?.pop(_activeSlot!);
    super.dispose();
  }
}
