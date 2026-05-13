import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Searchable select that works for both API-backed (async) and fixed lists.
/// Uses [key] to reset when [selectedValue] changes externally (e.g. resetting
/// Modelo after Marca changes). Clear button resets selection.
class GamaSearchableSelect<T extends Object> extends StatefulWidget {
  const GamaSearchableSelect({
    super.key,
    required this.label,
    required this.optionsBuilder,
    required this.displayString,
    required this.onChanged,
    this.selectedValue,
    this.enabled = true,
    this.isRequired = false,
    this.hint,
  });

  final String label;
  final Future<List<T>> Function(String query) optionsBuilder;
  final String Function(T) displayString;
  final void Function(T?) onChanged;
  final T? selectedValue;
  final bool enabled;
  final bool isRequired;
  final String? hint;

  @override
  State<GamaSearchableSelect<T>> createState() => _GamaSearchableSelectState<T>();
}

class _GamaSearchableSelectState<T extends Object> extends State<GamaSearchableSelect<T>> {
  // Track last known selectedValue to detect external resets (e.g. Marca → reset Modelo)
  T? _lastSelectedValue;

  @override
  void initState() {
    super.initState();
    _lastSelectedValue = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    // If parent reset selectedValue to null or different object, rebuild Autocomplete via key
    final needsReset = widget.selectedValue != _lastSelectedValue;
    if (needsReset) _lastSelectedValue = widget.selectedValue;

    return Autocomplete<T>(
      // Key forces recreation when external selection changes (e.g. reset after Marca swap)
      key: ValueKey(widget.selectedValue),
      initialValue: widget.selectedValue != null
          ? TextEditingValue(text: widget.displayString(widget.selectedValue!))
          : null,
      optionsBuilder: widget.enabled
          ? (v) => widget.optionsBuilder(v.text)
          : (_) async => [],
      displayStringForOption: widget.displayString,
      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
        return _SelectField<T>(
          ctrl: ctrl,
          focusNode: focusNode,
          label: widget.label,
          hint: widget.hint,
          enabled: widget.enabled,
          isRequired: widget.isRequired,
          selectedValue: widget.selectedValue,
          displayString: widget.displayString,
          onClear: () {
            ctrl.clear();
            widget.onChanged(null);
          },
          onChanged: (text) {
            // User edited text manually → clear current selection so form knows it's dirty
            if (widget.selectedValue != null &&
                text != widget.displayString(widget.selectedValue!)) {
              widget.onChanged(null);
            }
          },
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          shadowColor: Colors.black26,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 480),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(opt),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      child: Text(
                        widget.displayString(opt),
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      onSelected: widget.onChanged,
    );
  }
}

/// Extracted so we can use addListener cleanly without re-adding it each build.
class _SelectField<T extends Object> extends StatefulWidget {
  const _SelectField({
    required this.ctrl,
    required this.focusNode,
    required this.label,
    required this.enabled,
    required this.isRequired,
    required this.selectedValue,
    required this.displayString,
    required this.onClear,
    required this.onChanged,
    this.hint,
  });

  final TextEditingController ctrl;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final bool enabled;
  final bool isRequired;
  final T? selectedValue;
  final String Function(T) displayString;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;

  @override
  State<_SelectField<T>> createState() => _SelectFieldState<T>();
}

class _SelectFieldState<T extends Object> extends State<_SelectField<T>> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onTextChange);
  }

  void _onTextChange() {
    widget.onChanged(widget.ctrl.text);
    // Rebuild to update the clear button visibility
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.ctrl.text.isNotEmpty;

    return TextFormField(
      controller: widget.ctrl,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: widget.enabled ? Colors.white : AppColors.surface,
        suffixIcon: hasText && widget.enabled
            ? IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                onPressed: widget.onClear,
              )
            : const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textSecondary),
      ),
      validator: widget.isRequired
          ? (v) {
              if (widget.selectedValue == null) return 'Selecione uma opção';
              return null;
            }
          : null,
    );
  }
}
