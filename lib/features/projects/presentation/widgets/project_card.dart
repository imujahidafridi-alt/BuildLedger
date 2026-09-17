import 'package:flutter/material.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/core/formatting/date_formatter.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return ShadCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: tokens.typography.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ShadBadge(
                label: project.status.name.toUpperCase(),
                variant: project.isActive ? ShadBadgeVariant.success : ShadBadgeVariant.neutral,
              ),
            ],
          ),
          if (project.clientName != null || project.location != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (project.clientName != null) ...[
                  Icon(Icons.person_outline, size: 14, color: tokens.mutedForeground),
                  const SizedBox(width: 4),
                  Text(
                    project.clientName!,
                    style: tokens.typography.muted,
                  ),
                ],
                if (project.clientName != null && project.location != null)
                  Text(' • ', style: TextStyle(color: tokens.mutedForeground)),
                if (project.location != null) ...[
                  Icon(Icons.location_on_outlined, size: 14, color: tokens.mutedForeground),
                  const SizedBox(width: 4),
                  Text(
                    project.location!,
                    style: tokens.typography.muted,
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          const ShadSeparator(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL BUDGET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: tokens.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MoneyText(
                    project.budgetAmount,
                    style: MoneyTextStyle.body,
                  ),
                ],
              ),
              if (project.startDate != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'START DATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: tokens.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatShort(project.startDate!),
                      style: tokens.typography.small.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
