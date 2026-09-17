import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Permanent visual regression & design system gallery playground.
/// Demonstrates canonical ShadCN enterprise components in Light/Dark modes,
/// verifying touch targets >= 48dp, states, and semantic tokens.
class DesignSystemGalleryScreen extends StatefulWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  State<DesignSystemGalleryScreen> createState() => _DesignSystemGalleryScreenState();
}

class _DesignSystemGalleryScreenState extends State<DesignSystemGalleryScreen> {
  // Form controllers & demo state
  final _textController = TextEditingController(text: 'Standard text input');
  final _amountController = TextEditingController(text: '18500.50');
  int _parsedMinorUnits = 1850050;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory = 'Cement';
  int _selectedTab = 0;
  bool _buttonLoading = false;
  bool _switchValue = true;

  @override
  void dispose() {
    _textController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
    final tokens = context.shad;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: tokens.primary,
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: tokens.border, height: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShadCN Design System'),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
        children: [
          // 1. Buttons
          _buildCategoryHeader(context, '1. ShadButton (7 Variants & 3 Sizes)'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ShadButton(
                label: 'Primary (Amber on Dark)',
                variant: ShadButtonVariant.primary,
                size: ShadButtonSize.medium,
                onPressed: () {},
              ),
              ShadButton(
                label: 'Small (36dp / 48dp hit)',
                variant: ShadButtonVariant.primary,
                size: ShadButtonSize.small,
                icon: Icons.check,
                onPressed: () {},
              ),
              ShadButton(
                label: 'Large (48dp)',
                variant: ShadButtonVariant.primary,
                size: ShadButtonSize.large,
                onPressed: () {},
              ),
              ShadButton(
                label: 'Secondary',
                variant: ShadButtonVariant.secondary,
                onPressed: () {},
              ),
              ShadButton(
                label: 'Outline',
                variant: ShadButtonVariant.outline,
                onPressed: () {},
              ),
              ShadButton(
                label: 'Tonal',
                variant: ShadButtonVariant.tonal,
                icon: Icons.layers_outlined,
                onPressed: () {},
              ),
              ShadButton(
                label: 'Destructive',
                variant: ShadButtonVariant.destructive,
                icon: Icons.delete_outline,
                onPressed: () {},
              ),
              ShadButton(
                label: 'Ghost',
                variant: ShadButtonVariant.ghost,
                onPressed: () {},
              ),
              ShadButton(
                label: 'Link',
                variant: ShadButtonVariant.link,
                onPressed: () {},
              ),
              ShadButton(
                label: 'Loading State',
                variant: ShadButtonVariant.primary,
                isLoading: _buttonLoading,
                onPressed: () {
                  setState(() => _buttonLoading = !_buttonLoading);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _buttonLoading = false);
                  });
                },
              ),
              const ShadButton(
                label: 'Disabled Button',
                variant: ShadButtonVariant.primary,
                onPressed: null,
              ),
            ],
          ),

          // 2. Badges & Progress
          _buildCategoryHeader(context, '2. ShadBadge & Progress'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              ShadBadge(label: 'Neutral', variant: ShadBadgeVariant.neutral),
              ShadBadge(label: 'Success', variant: ShadBadgeVariant.success),
              ShadBadge(label: 'Destructive', variant: ShadBadgeVariant.destructive),
              ShadBadge(label: 'Warning', variant: ShadBadgeVariant.warning),
              ShadBadge(label: 'Info', variant: ShadBadgeVariant.info),
              ShadBadge(label: 'Outline', variant: ShadBadgeVariant.outline),
              ShadBadge(label: 'Small Neutral', variant: ShadBadgeVariant.neutral, isSmall: true),
              ShadBadge(label: 'Small Success', variant: ShadBadgeVariant.success, isSmall: true),
            ],
          ),
          const SizedBox(height: 14),
          const ShadProgress(value: 0.65),

          // 3. Form Inputs & Text Fields
          _buildCategoryHeader(context, '3. ShadInput & ShadSearchInput'),
          ShadInput(
            controller: _textController,
            label: 'Project Name *',
            hint: 'e.g. Grand City Villa',
            prefixIcon: const Icon(Icons.business, size: 18),
            helperText: 'Enter complete registered project identifier',
          ),
          const SizedBox(height: 14),
          ShadSearchInput(
            hintText: 'Search expenses, vendors, materials...',
            onChanged: (q) {},
          ),

          // 4. Deterministic Amount Field
          _buildCategoryHeader(context, '4. ShadAmountInput (Deterministic Minor Units)'),
          ShadAmountInput(
            controller: _amountController,
            label: 'Site Expense Amount *',
            onChangedMinorUnits: (units) {
              setState(() => _parsedMinorUnits = units);
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.muted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deterministic Minor Units:',
                  style: tokens.typography.small.copyWith(color: tokens.mutedForeground),
                ),
                Text(
                  '$_parsedMinorUnits paisas',
                  style: tokens.typography.mono.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.primary,
                  ),
                ),
              ],
            ),
          ),

          // 5. Select & Date Input
          _buildCategoryHeader(context, '5. ShadSelect & ShadDateInput'),
          ShadSelect<String>(
            label: 'Material Category',
            value: _selectedCategory,
            items: const [
              ShadSelectItem(value: 'Cement', label: 'Cement & Binding', subtitle: 'Ordinary Portland'),
              ShadSelectItem(value: 'Steel', label: 'Reinforced Steel', subtitle: 'Grade 60 Deformed'),
              ShadSelectItem(value: 'Bricks', label: 'Red Clay Bricks', subtitle: 'A-Grade Kiln'),
              ShadSelectItem(value: 'Sand', label: 'River Sand & Aggregates', subtitle: 'Chenab Coarse'),
            ],
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
          const SizedBox(height: 14),
          ShadDateInput(
            label: 'Invoice / Shift Date',
            selectedDate: _selectedDate,
            onDateChanged: (picked) => setState(() => _selectedDate = picked),
          ),

          // 6. Tabs
          _buildCategoryHeader(context, '6. ShadTabs (Segmented Control)'),
          ShadTabs<int>(
            values: const [0, 1, 2, 3],
            selectedValue: _selectedTab,
            labelBuilder: (v) {
              switch (v) {
                case 0:
                  return 'All';
                case 1:
                  return 'Materials';
                case 2:
                  return 'Labour';
                case 3:
                  return 'Equipment';
                default:
                  return '$v';
              }
            },
            onTabSelected: (v) => setState(() => _selectedTab = v),
          ),

          // 7. ShadCard & Composable ShadSection
          _buildCategoryHeader(context, '7. ShadSection & ShadSectionItem (Anti-Card-Soup)'),
          ShadSection(
            title: 'System Security & Storage',
            children: [
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.infoContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.shield_outlined, color: tokens.info, size: 20)),
                ),
                title: const Text('Encrypted Backup & Restore'),
                subtitle: const Text('AES-256-GCM package with SHA-256 integrity check'),
                onTap: () {},
              ),
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.successContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.storage_outlined, color: tokens.success, size: 20)),
                ),
                title: const Text('Offline Database'),
                subtitle: const Text('SQLite WAL mode • Local Zero-Latency Engine'),
                onTap: () {},
              ),
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.notifications_outlined, color: tokens.warning, size: 20)),
                ),
                title: const Text('Over-Budget Alerts'),
                subtitle: const Text('Push notification when spend exceeds 90%'),
                trailing: Switch.adaptive(
                  value: _switchValue,
                  activeTrackColor: tokens.primary,
                  onChanged: (v) => setState(() => _switchValue = v),
                ),
              ),
            ],
          ),

          // 8. Stat Cards & Financial KPIs
          _buildCategoryHeader(context, '8. ShadStatCard & MoneyText'),
          Row(
            children: [
              Expanded(
                child: ShadStatCard(
                  title: 'Total Spend',
                  amount: const Money(345000000), // Rs 3,450,000
                  subtitle: '82% of budget',
                  icon: Icons.trending_up,
                  semanticColor: MoneySemanticColor.alert,
                  progressFraction: 0.82,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShadStatCard(
                  title: 'Cash Outflow',
                  amount: const Money(210000000), // Rs 2,100,000
                  subtitle: 'Reconciled',
                  icon: Icons.account_balance_wallet_outlined,
                  semanticColor: MoneySemanticColor.profit,
                  progressFraction: 0.50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShadCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Headline', style: TextStyle(fontSize: 11, color: tokens.mutedForeground)),
                    const SizedBox(height: 4),
                    const MoneyText(Money(50000000), style: MoneyTextStyle.headline),
                  ],
                ),
                Column(
                  children: [
                    Text('Title', style: TextStyle(fontSize: 11, color: tokens.mutedForeground)),
                    const SizedBox(height: 4),
                    const MoneyText(Money(1250000), style: MoneyTextStyle.title, semanticColor: MoneySemanticColor.profit),
                  ],
                ),
                Column(
                  children: [
                    Text('Caption', style: TextStyle(fontSize: 11, color: tokens.mutedForeground)),
                    const SizedBox(height: 4),
                    const MoneyText(Money(-450000), style: MoneyTextStyle.caption, semanticColor: MoneySemanticColor.auto),
                  ],
                ),
              ],
            ),
          ),

          // 9. Transaction Tiles
          _buildCategoryHeader(context, '9. ShadTransactionTile (Expenses & Ledger)'),
          ShadTransactionTile(
            title: '500 Bags Ordinary Portland Cement',
            subtitle: 'ABC Cement Agency • Gate Pass #402',
            amount: const Money(42500000), // Rs 425,000
            date: DateTime.now(),
            leadingIcon: const Icon(Icons.construction),
            statusBadge: 'CREDIT',
            badgeVariant: ShadBadgeVariant.warning,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          ShadTransactionTile(
            title: 'Mason Daily Wage Payout',
            subtitle: 'Ustad Aslam • Full Day (1.0)',
            amount: const Money(250000), // Rs 2,500
            date: DateTime.now().subtract(const Duration(days: 1)),
            direction: TransactionDirection.outflow,
            leadingIcon: const Icon(Icons.engineering),
            statusBadge: 'CASH',
            badgeVariant: ShadBadgeVariant.success,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          ShadTransactionTile(
            title: 'Accidental Duplicate Sand Delivery',
            subtitle: 'Chenab River Sand',
            amount: const Money(8500000), // Rs 85,000
            date: DateTime.now().subtract(const Duration(days: 3)),
            leadingIcon: const Icon(Icons.local_shipping),
            isVoided: true,
          ),

          // 10. Project Selector
          _buildCategoryHeader(context, '10. ShadProjectSelector'),
          ShadProjectSelector(
            project: Project(
              id: '1',
              name: 'Gulberg Commercial Plaza (Tower A)',
              location: 'Lahore',
              budgetAmount: const Money(1500000000), // Rs 15,000,000
              status: ProjectStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ShadProjectSelector(
              project: Project(
                id: '2',
                name: 'Grand City Villa #14',
                location: 'Islamabad',
                budgetAmount: const Money(800000000),
                status: ProjectStatus.active,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              isCompact: true,
              onTap: () {},
            ),
          ),

          // 11. Dialogs & Sheet Triggers
          _buildCategoryHeader(context, '11. ShadConfirmDialog & ShadSheet'),
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  label: 'Test Confirm Dialog',
                  icon: Icons.help_outline,
                  onPressed: () async {
                    await ShadConfirmDialog.show(
                      context,
                      title: 'Archive Active Project?',
                      message: 'This will move the project to archives. Historical reports will remain accessible.',
                      confirmLabel: 'Archive Project',
                      isDestructive: true,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShadButton(
                  label: 'Test Bottom Sheet',
                  icon: Icons.open_in_browser,
                  onPressed: () {
                    ShadSheet.show(
                      context: context,
                      builder: (ctx) => ShadSheet(
                        title: const Text('Quick Filter Options'),
                        description: const Text('Narrow expenses by category or payment status'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.money_off),
                              title: const Text('Unpaid Credit Purchases'),
                              onTap: () => Navigator.of(ctx).pop(),
                            ),
                            ListTile(
                              leading: const Icon(Icons.attach_file),
                              title: const Text('Transactions with Receipts'),
                              onTap: () => Navigator.of(ctx).pop(),
                            ),
                            const SizedBox(height: 16),
                            ShadButton(
                              label: 'Apply Filters',
                              fullWidth: true,
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // 12. States & Skeleton
          _buildCategoryHeader(context, '12. ShadStates & Skeletons'),
          const ShadEmptyState(
            icon: Icons.receipt_long,
            title: 'No Expenses Logged Yet',
            message: 'Start tracking site purchases, vendor bills, and equipment rentals.',
            actionLabel: 'Record First Expense',
          ),
          const SizedBox(height: 12),
          const ShadErrorState(
            title: 'Database Read Error',
            message: 'Unable to decrypt local storage ledger. Verify password or passphrase.',
            retryLabel: 'Re-authenticate',
          ),
        ],
      ),
    );
  }
}

