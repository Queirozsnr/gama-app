import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum MobileTopBarStyle { light, dark }

/// Slot that each screen fills to inject content into the shared topbar.
class TopBarSlot {
  const TopBarSlot({
    this.pageTitle,
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

class TopBarNotifier extends ChangeNotifier {
  TopBarSlot? _slot;
  TopBarSlot? get slot => _slot;

  void set(TopBarSlot slot) {
    _slot = slot;
    _notify();
  }

  void clear() {
    if (_slot == null) return;
    _slot = null;
    _notify();
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

  static TopBarNotifier? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TopBarScope>()
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

/// Mixin for ConsumerStatefulWidget states to easily manage topbar slot.
mixin TopBarSlotMixin<T extends StatefulWidget> on State<T> {
  TopBarNotifier? _topBarNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _topBarNotifier = TopBarScope.maybeOf(context);
  }

  void setTopBarSlot(TopBarSlot slot) {
    _topBarNotifier?.set(slot);
  }

  @override
  void dispose() {
    _topBarNotifier?.clear();
    super.dispose();
  }
}
