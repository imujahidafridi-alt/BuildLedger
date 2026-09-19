import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/settings/presentation/controllers/settings_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class CurrencySelectorSheet extends ConsumerStatefulWidget {
  const CurrencySelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return ShadSheet.show(
      context: context,
      builder: (context) => const CurrencySelectorSheet(),
    );
  }

  @override
  ConsumerState<CurrencySelectorSheet> createState() => _CurrencySelectorSheetState();
}

class _CurrencySelectorSheetState extends ConsumerState<CurrencySelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final currentCurrency = ref.watch(baseCurrencyProvider);

    final filtered = kSupportedCurrencies.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();

    return ShadSheet(
      title: const Text('Select Base Currency'),
      description: const Text('All financial dashboards, expenses, and PDF statements will use this currency.'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadInput(
              controller: _searchController,
              hint: 'Search currency (e.g. PKR, AED, USD)...',
              prefixIcon: Icon(Icons.search, size: 18, color: tokens.mutedForeground),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: tokens.border.withValues(alpha: 0.5)),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isSelected = item.code == currentCurrency.code;

                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? tokens.primary.withValues(alpha: 0.15) : tokens.muted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? tokens.primary : tokens.border,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          item.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          item.code,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? tokens.primary : tokens.foreground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ShadBadge(
                          label: item.symbol,
                          variant: isSelected ? ShadBadgeVariant.warning : ShadBadgeVariant.outline,
                          isSmall: true,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      item.name,
                      style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, size: 20, color: tokens.primary)
                        : null,
                    onTap: () async {
                      await ref.read(baseCurrencyProvider.notifier).setCurrency(item);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ShadToast.show(
                          context,
                          title: 'Base Currency Updated',
                          message: 'Active operating currency set to ${item.name} (${item.symbol}).',
                          variant: ShadToastVariant.success,
                        );
                      }
                    },
                  ),
                );
              },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
