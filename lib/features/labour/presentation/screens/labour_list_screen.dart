import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/features/labour/presentation/controllers/labour_controller.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/projects/presentation/widgets/project_selector_sheet.dart';
import 'package:build_ledger/shared/dialogs/app_void_dialog.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class LabourListScreen extends ConsumerWidget {
  const LabourListScreen({super.key});

  void _onVoidShift(BuildContext context, WidgetRef ref, String labourId) async {
    final reason = await AppVoidDialog.show(context, entityName: 'Labour Shift');
    if (reason != null && reason.trim().isNotEmpty) {
      final success = await ref.read(labourControllerProvider.notifier).voidLabourShift(
            labourId: labourId,
            reason: reason,
          );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Labour shift voided and excluded from costs')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(labourEntriesProvider);
    final activeProject = ref.watch(selectedProjectProvider);
    final tokens = context.shad;
    final dynamicBottomPadding = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    final hasEntries = labourAsync.asData?.value.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final picked = await ProjectSelectorSheet.show(context, ref);
            if (picked != null) {
              ref.read(selectedProjectProvider.notifier).state = picked;
              ref.invalidate(labourEntriesProvider);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeProject?.name ?? 'Site Labour',
                  style: tokens.typography.h3,
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 20, color: tokens.mutedForeground),
              ],
            ),
          ),
        ),
      ),
      body: labourAsync.when(
        loading: () => const ShadLoadingState(message: 'Loading labour & attendance records...'),
        error: (err, _) => ShadErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(labourEntriesProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return ShadEmptyState(
              icon: Icons.engineering,
              title: 'No Labour Logged',
              message: activeProject != null
                  ? 'No daily wage shifts or workers logged yet for ${activeProject.name}.'
                  : 'Track daily wages for Masons, Mazdoors, Plumbers, and Carpenters.',
              actionLabel: 'Log Labour Shift',
              onAction: () => context.push('/labour/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(labourEntriesProvider),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 16, 16, dynamicBottomPadding),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isVoided = entry.isVoided;

                return ShadCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isVoided ? tokens.destructiveContainer : tokens.muted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.engineering,
                              color: isVoided ? tokens.destructive : tokens.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.workerName,
                                  style: tokens.typography.p.copyWith(
                                    fontWeight: FontWeight.w700,
                                    decoration: isVoided ? TextDecoration.lineThrough : null,
                                    color: isVoided ? tokens.destructive : tokens.foreground,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${entry.role} • ${entry.formattedDays}',
                                  style: tokens.typography.small.copyWith(
                                    color: tokens.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'NET PAYABLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isVoided ? tokens.destructive : tokens.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              MoneyText(
                                entry.netAmount,
                                style: MoneyTextStyle.title,
                                semanticColor: isVoided ? MoneySemanticColor.alert : MoneySemanticColor.profit,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: tokens.border),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rate: Rs ${entry.rate.minorUnits ~/ 100}/day  •  Advance: Rs ${entry.advance.minorUnits ~/ 100}',
                            style: tokens.typography.small.copyWith(color: tokens.mutedForeground),
                          ),
                          if (!isVoided)
                            InkWell(
                              onTap: () => _onVoidShift(context, ref, entry.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Text(
                                  'Void',
                                  style: TextStyle(fontSize: 12, color: tokens.destructive, fontWeight: FontWeight.w600),
                                ),
                              ),
                            )
                          else
                            const ShadBadge.destructive(label: 'VOIDED', isSmall: true),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: hasEntries
          ? FloatingActionButton.extended(
              heroTag: 'new_labour_fab',
              backgroundColor: tokens.primary,
              foregroundColor: tokens.primaryForeground,
              elevation: 2,
              onPressed: () => context.push('/labour/new'),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Log Shift',
                style: TextStyle(
                  color: tokens.primaryForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }
}

