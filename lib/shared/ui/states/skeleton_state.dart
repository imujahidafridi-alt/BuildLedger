import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/shared/ui/components/skeleton/shad_skeleton.dart';
import 'package:build_ledger/shared/ui/components/card/shad_card.dart';

/// Pre-configured skeleton layout for lists and screens.
class ShadSkeletonState extends StatelessWidget {
  final int itemCount;

  const ShadSkeletonState({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: ShadSpacing.pagePadding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: ShadSpacing.md),
      itemBuilder: (context, index) => ShadCard(
        padding: ShadSpacing.cardPadding,
        child: Row(
          children: [
            const ShadSkeleton(width: 40, height: 40, borderRadius: ShadRadii.roundedMd),
            const SizedBox(width: ShadSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShadSkeleton(width: 140, height: 16),
                  SizedBox(height: 6),
                  ShadSkeleton(width: 90, height: 12),
                ],
              ),
            ),
            const ShadSkeleton(width: 60, height: 18),
          ],
        ),
      ),
    );
  }
}
