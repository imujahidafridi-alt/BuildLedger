import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';

/// Canonical ShadCN search input field.
///
/// Characteristics:
/// - 44dp visual height
/// - Leading search icon
/// - Trailing clear button when text is non-empty
/// - Pure presentation (NO internal debouncing; debouncing handled by caller)
class ShadSearchInput extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const ShadSearchInput({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    String hintText = 'Search...',
    String? hint,
    this.autofocus = false,
    this.textInputAction = TextInputAction.search,
    this.onSubmitted,
    this.focusNode,
  }) : hintText = hint ?? hintText;

  @override
  State<ShadSearchInput> createState() => _ShadSearchInputState();
}

class _ShadSearchInputState extends State<ShadSearchInput> {
  late final TextEditingController _effectiveController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _hasText = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _effectiveController.dispose();
    } else {
      _effectiveController.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final nowHasText = _effectiveController.text.isNotEmpty;
    if (nowHasText != _hasText) {
      setState(() => _hasText = nowHasText);
    }
  }

  void _clear() {
    _effectiveController.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return SizedBox(
      height: 44,
      child: TextField(
        controller: _effectiveController,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onSubmitted: (val) {
          widget.onSubmitted?.call(val);
          FocusScope.of(context).unfocus();
        },
        style: tokens.typography.p,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: tokens.typography.muted,
          filled: true,
          fillColor: tokens.input,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          prefixIcon: Icon(Icons.search, size: 18, color: tokens.mutedForeground),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(Icons.close, size: 16, color: tokens.mutedForeground),
                  onPressed: _clear,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  tooltip: 'Clear search',
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: ShadRadii.roundedMd,
            borderSide: BorderSide(color: tokens.border, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: ShadRadii.roundedMd,
            borderSide: BorderSide(color: tokens.border, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: ShadRadii.roundedMd,
            borderSide: BorderSide(color: tokens.ring, width: 1.5),
          ),
        ),
      ),
    );
  }
}
