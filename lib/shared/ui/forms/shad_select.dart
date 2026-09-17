import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/shared/ui/components/sheet/shad_sheet.dart';
import 'package:build_ledger/shared/ui/components/keyboard/keyboard_dismissible.dart';

class ShadSelectItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? icon;

  const ShadSelectItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });
}

/// Canonical ShadCN-style select / dropdown field.
class ShadSelect<T> extends FormField<T> {
  final String? label;
  final String placeholder;
  final List<ShadSelectItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enableSearch;
  final Widget? prefixIcon;

  ShadSelect({
    super.key,
    this.label,
    this.placeholder = 'Select an option',
    required this.items,
    T? value,
    this.onChanged,
    this.enableSearch = false,
    this.prefixIcon,
    super.validator,
    super.enabled = true,
  }) : super(
          initialValue: value,
          builder: (FormFieldState<T> state) {
            final context = state.context;
            final isEnabled = state.widget.enabled;
            final tokens = context.shad;
            final selectedItem = items.cast<ShadSelectItem<T>?>().firstWhere(
                  (item) => item?.value == state.value,
                  orElse: () => null,
                );
            final hasError = state.hasError;

            void openSelector() async {
              if (!isEnabled) return;

              final picked = await ShadSheet.show<T>(
                context: context,
                builder: (ctx) => _ShadSelectSheet<T>(
                  title: label ?? 'Select Option',
                  items: items,
                  selectedValue: state.value,
                  enableSearch: enableSearch,
                ),
              );

              if (picked != null) {
                state.didChange(picked);
                onChanged?.call(picked);
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null) ...[
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? tokens.foreground : tokens.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: ShadRadii.roundedMd,
                    onTap: isEnabled ? openSelector : null,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: tokens.input,
                        borderRadius: ShadRadii.roundedMd,
                        border: Border.all(
                          color: hasError
                              ? tokens.destructive
                              : (isEnabled ? tokens.border : tokens.border.withValues(alpha: 0.5)),
                          width: hasError ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (prefixIcon != null) ...[
                            prefixIcon,
                            const SizedBox(width: 10),
                          ] else if (selectedItem?.icon != null) ...[
                            selectedItem!.icon!,
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              selectedItem?.label ?? placeholder,
                              style: tokens.typography.p.copyWith(
                                color: selectedItem != null
                                    ? tokens.foreground
                                    : tokens.mutedForeground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.unfold_more_rounded,
                            size: 18,
                            color: isEnabled ? tokens.mutedForeground : tokens.border,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.errorText!,
                    style: TextStyle(fontSize: 11, color: tokens.destructive),
                  ),
                ],
              ],
            );
          },
        );
}

class _ShadSelectSheet<T> extends StatefulWidget {
  final String title;
  final List<ShadSelectItem<T>> items;
  final T? selectedValue;
  final bool enableSearch;

  const _ShadSelectSheet({
    required this.title,
    required this.items,
    this.selectedValue,
    required this.enableSearch,
  });

  @override
  State<_ShadSelectSheet<T>> createState() => _ShadSelectSheetState<T>();
}

class _ShadSelectSheetState<T> extends State<_ShadSelectSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final filtered = widget.items.where((i) {
      if (_query.isEmpty) return true;
      return i.label.toLowerCase().contains(_query.toLowerCase()) ||
          (i.subtitle != null && i.subtitle!.toLowerCase().contains(_query.toLowerCase()));
    }).toList();

    return ShadSheet(
      title: Text(widget.title),
      child: KeyboardDismissible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.enableSearch) ...[
              TextField(
                autofocus: true,
                style: tokens.typography.p,
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.none,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                scrollPadding: const EdgeInsets.only(top: 20, bottom: 96),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (val) => setState(() => _query = val),
              ),
              const SizedBox(height: ShadSpacing.sm),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No options found', style: tokens.typography.muted),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: tokens.border),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item.value == widget.selectedValue;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: item.icon,
                          title: Text(
                            item.label,
                            style: tokens.typography.p.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              color: isSelected ? tokens.primary : tokens.foreground,
                            ),
                          ),
                          subtitle: item.subtitle != null
                              ? Text(item.subtitle!, style: tokens.typography.muted)
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check, size: 18, color: tokens.primary)
                              : null,
                          onTap: () => Navigator.of(context).pop(item.value),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
