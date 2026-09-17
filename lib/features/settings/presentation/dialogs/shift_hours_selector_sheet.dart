import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/settings/presentation/controllers/settings_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Modal sheet for selecting the standard daily shift duration for site workers.
class ShiftHoursSelectorSheet extends ConsumerWidget {
  const ShiftHoursSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return ShadSheet.show(
      context: context,
      builder: (context) => const ShadSheet(
        child: ShiftHoursSelectorSheet(),
      ),
    );
  }

  static const _shiftOptions = [
    (hoursX100: 600, label: '6.0 Hours', desc: 'Short / Part-time site shift'),
    (hoursX100: 700, label: '7.0 Hours', desc: 'Reduced daily shift'),
    (hoursX100: 800, label: '8.0 Hours (Standard)', desc: 'Standard Pakistani construction workday'),
    (hoursX100: 900, label: '9.0 Hours', desc: 'Extended standard shift'),
    (hoursX100: 1000, label: '10.0 Hours', desc: 'Fast-track contractor schedule'),
    (hoursX100: 1200, label: '12.0 Hours', desc: 'Full-day commercial overtime rotation'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.shad;
    final currentShiftX100 = ref.watch(standardShiftHoursProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.muted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.schedule, color: tokens.primary, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Standard Labour Shift', style: tokens.typography.h4),
                  const SizedBox(height: 2),
                  Text(
                    'Base duration for daily wage and overtime determinations',
                    style: tokens.typography.muted,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._shiftOptions.map((opt) {
          final isSelected = opt.hoursX100 == currentShiftX100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShadCard(
              onTap: () async {
                await ref
                    .read(standardShiftHoursProvider.notifier)
                    .setShiftHoursX100(opt.hoursX100);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ShadToast.show(
                    context,
                    title: 'Shift Standard Updated',
                    message: 'Set to ${opt.label}',
                  );
                }
              },
              backgroundColor: isSelected
                  ? tokens.primary.withValues(alpha: 0.1)
                  : tokens.card,
              borderColor: isSelected ? tokens.primary : tokens.border,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? tokens.primary : tokens.mutedForeground,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt.label,
                          style: tokens.typography.p.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? tokens.foreground : tokens.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          opt.desc,
                          style: tokens.typography.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    ShadBadge(
                      label: 'ACTIVE',
                      variant: ShadBadgeVariant.warning,
                      isSmall: true,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }
}
