# BuildLedger - Construction Site Expense Tracker

## Enterprise Software Requirements Specification (SRS)

**Product Type:** Android-first construction financial management application
**Platform:** Android, with architecture prepared for iOS
**Framework:** Flutter
**UI System:** Material 3
**Architecture:** Feature-first, modular, offline-first
**Primary Market:** Small-to-medium contractors, builders, site supervisors, property owners, and construction businesses
**Document Status:** Production Specification
**Version:** 1.0

---

# 1. Executive Summary

Construction Site Expense Tracker is an offline-first mobile application designed to help construction businesses record, organize, monitor, and analyze project expenses without relying on spreadsheets, notebooks, or complex ERP systems.

The product focuses on one central problem:

> **Give construction stakeholders a reliable real-time picture of where project money is being spent.**

The application will allow users to:

* Create construction projects.
* Define project budgets.
* Record expenses.
* Categorize construction expenses.
* Attach receipt photographs.
* Track suppliers.
* Track supplier balances.
* Monitor labour costs.
* Compare budget against actual spending.
* Generate professional reports.
* Share reports through WhatsApp and other Android sharing mechanisms.
* Continue working without internet connectivity.
* Synchronize data when connectivity becomes available.

The architecture must be capable of expanding into:

* Multi-user project management.
* Site-supervisor workflows.
* Cloud synchronization.
* OCR receipt processing.
* Purchase orders.
* BOQ and estimation.
* Material inventory.
* Labour attendance and payroll.
* Advanced project costing.

---

# 2. Product Vision

The application should become the financial control layer for small construction projects.

Instead of requiring users to understand accounting software, the application should model the way construction work actually happens:

**Project → Site → Purchase → Labour → Payment → Expense → Balance → Report**

The interface should prioritize:

* Speed.
* Clarity.
* Reliability.
* Offline operation.
* Minimal data entry.
* Large touch targets.
* Strong visual hierarchy.
* Professional construction-business aesthetics.
* Consistent interaction patterns.

The application must feel like a serious business tool rather than a generic personal expense tracker.

---

# 3. Target Users

## 3.1 Contractor / Business Owner

Responsibilities:

* Owns one or more projects.
* Controls budgets.
* Reviews expenses.
* Manages suppliers.
* Reviews labour costs.
* Monitors project profitability/cost.
* Generates reports.

Primary needs:

* Executive dashboard.
* Budget monitoring.
* Project comparison.
* Supplier balances.
* Expense reports.
* Financial summaries.

---

## 3.2 Site Supervisor

Responsibilities:

* Records daily site expenses.
* Purchases materials.
* Records labour expenses.
* Uploads receipts.
* Reports site activity.

Primary needs:

* Extremely fast expense entry.
* Camera receipt capture.
* Offline functionality.
* Project/site selection.
* Minimal navigation.

---

## 3.3 Property Owner

Responsibilities:

* Monitors construction spending.
* Reviews contractor-reported expenses.
* Tracks project budget.

Primary needs:

* Readable reports.
* Budget vs actual.
* Spending breakdown.
* Payment history.
* Project progress.

---

## 3.4 Accountant / Office Staff

Responsibilities:

* Reviews expenses.
* Manages suppliers.
* Generates reports.
* Reconciles payments.

Primary needs:

* Search.
* Filters.
* Ledgers.
* Export.
* Audit history.
* Structured data.

---

# 4. Product Scope

## 4.1 Version 1 Core Scope

V1 must include:

1. Project management.
2. Project budget.
3. Expense management.
4. Construction categories.
5. Receipt attachments.
6. Supplier management.
7. Supplier transaction ledger.
8. Labour expense tracking.
9. Dashboard.
10. Budget vs actual analysis.
11. Reports.
12. PDF generation.
13. Android sharing.
14. Offline-first local database.
15. Backup/export.
16. Search and filtering.
17. Validation.
18. Audit-friendly transaction history.
19. Material 3 UI system.
20. Responsive Flutter architecture.

---

# 5. Out of Scope for V1

The following must not unnecessarily complicate the first production release:

* Full accounting/general ledger.
* Tax accounting.
* Full inventory management.
* BOQ engine.
* Procurement workflow.
* Payroll engine.
* Attendance system.
* Banking integrations.
* Payment gateway.
* Contractor marketplace.
* Social features.
* AI chatbot.
* Complex project scheduling.
* CAD/BIM integration.

Architecture must allow these capabilities later without requiring a complete rewrite.

---

# 6. Technology Stack

## 6.1 Application

**Flutter**

Recommended stable production Flutter release.

Language:

**Dart**

Minimum architecture requirements:

* Null safety.
* Strong typing.
* Feature modularization.
* Dependency injection.
* Repository pattern.
* Immutable domain models where appropriate.

---

# 7. UI Framework

## Material 3

The entire application must use **Material 3 design principles**.

Do not create unrelated custom UI patterns for common controls.

Use shared components for:

* Buttons.
* Cards.
* Text fields.
* Dropdowns.
* Search fields.
* Dialogs.
* Bottom sheets.
* Navigation.
* Chips.
* Segmented controls.
* Tabs.
* Progress indicators.
* Empty states.
* Error states.
* Confirmation dialogs.
* Snackbars.
* Date pickers.
* Numeric inputs.

Material 3 should be customized through a centralized theme rather than manually styling every screen.

---

# 8. Design Language

The visual identity should communicate:

**Construction + Finance + Reliability**

The interface must be:

* Professional.
* Clean.
* Dense enough for business workflows.
* Highly readable.
* Practical.
* Modern.
* Restrained.

Avoid:

* Excessive gradients.
* Glassmorphism.
* Decorative animations.
* Large unnecessary illustrations.
* Excessive shadows.
* Excessive rounded containers.
* Gaming-style dashboards.
* Visually noisy charts.

---

# 9. Theme System

Create a centralized:

```text
AppTheme
├── ColorScheme
├── Typography
├── Shapes
├── Component Themes
├── Spacing
├── Elevation
└── Motion
```

Support:

* Light mode.
* Dark mode.
* System theme.

All colors must come from Material 3 `ColorScheme`.

Never hardcode colors inside feature widgets unless explicitly required by a semantic status component.

---

# 10. Typography

Use a highly readable Material 3 type scale.

Required hierarchy:

```text
Display
Headline
Title
Body
Label
```

Numbers such as:

* PKR amounts.
* Budget.
* Outstanding.
* Expenses.

must receive strong visual emphasis.

Currency values must remain readable on small Android devices.

---

# 11. Localization

Architecture must support localization from the beginning.

Initial language:

**English**

Prepared for:

* Urdu.
* Roman Urdu where appropriate.
* Additional languages later.

Never hardcode user-facing strings directly inside business widgets.

Use localization keys.

Example:

```dart
AppLocalizations.of(context).addExpense
```

---

# 12. Currency

Primary currency:

**PKR**

Display examples:

```text
Rs 18,500
Rs 1.25M
Rs 18.50M
```

The underlying database must store monetary values safely.

Avoid floating-point representation for financial amounts.

Prefer:

```text
integer minor units
```

or another deterministic decimal representation.

---

# 13. Application Architecture

Recommended architecture:

```text
lib/
│
├── app/
│   ├── app.dart
│   ├── router/
│   ├── theme/
│   └── localization/
│
├── core/
│   ├── database/
│   ├── errors/
│   ├── logging/
│   ├── networking/
│   ├── storage/
│   ├── permissions/
│   ├── formatting/
│   ├── validation/
│   └── utilities/
│
├── shared/
│   ├── widgets/
│   ├── components/
│   ├── dialogs/
│   ├── forms/
│   ├── charts/
│   └── states/
│
└── features/
    ├── onboarding/
    ├── dashboard/
    ├── projects/
    ├── expenses/
    ├── suppliers/
    ├── labour/
    ├── reports/
    ├── settings/
    └── backup/
```

Feature modules must not directly depend on unrelated feature implementations.

---

# 14. State Management

Use a predictable reactive state-management solution such as:

**Riverpod**

Requirements:

* No global mutable state.
* Feature-scoped providers.
* Repository-backed state.
* Proper loading/error/data states.
* Automatic disposal where appropriate.
* Testable providers.
* No business logic inside UI widgets.

Example:

```text
UI
 ↓
Controller / Notifier
 ↓
Use Case
 ↓
Repository
 ↓
Local Database
```

---

# 15. Domain Architecture

Separate:

```text
Presentation
Application
Domain
Data
Infrastructure
```

Example:

```text
ExpenseScreen
      ↓
ExpenseController
      ↓
CreateExpenseUseCase
      ↓
ExpenseRepository
      ↓
ExpenseLocalDataSource
      ↓
SQLite
```

The UI must never directly execute SQL.

---

# 16. Database

Recommended:

**SQLite**

Use a mature Flutter SQLite abstraction suitable for production.

Database requirements:

* Transactions.
* Foreign keys.
* Indexes.
* Migration system.
* WAL where appropriate.
* Atomic writes.
* Referential integrity.
* Backup/export compatibility.

---

# 17. Core Data Model

## Project

```text
Project
├── id
├── name
├── description
├── clientName
├── location
├── budgetAmount
├── startDate
├── expectedEndDate
├── status
├── currency
├── createdAt
├── updatedAt
└── archivedAt
```

Status:

```text
active
completed
archived
```

---

# 18. Expense Entity

```text
Expense
├── id
├── projectId
├── categoryId
├── supplierId?
├── labourId?
├── amount
├── description
├── paymentMethod
├── expenseDate
├── receiptPath?
├── notes?
├── createdBy?
├── createdAt
├── updatedAt
└── deletedAt?
```

Expenses must be immutable from an accounting-history perspective.

Edits should produce audit information rather than silently rewriting historical records.

---

# 19. Expense Categories

Default categories:

### Materials

* Cement.
* Steel.
* Bricks.
* Sand.
* Crush.
* Blocks.
* Tiles.
* Marble.
* Paint.
* Wood.
* Glass.
* Plumbing.
* Electrical.
* Hardware.

### Labour

* Mason.
* General Labour.
* Plumber.
* Electrician.
* Carpenter.
* Painter.
* Welder.

### Equipment

* Excavator.
* Mixer.
* Crane.
* Generator.
* Tools.
* Scaffolding.

### Transport

* Truck.
* Loader.
* Delivery.
* Fuel.
* Transportation.

### Other

* Water.
* Electricity.
* Permits.
* Food/Tea.
* Miscellaneous.

Users can create custom categories.

---

# 20. Supplier Entity

```text
Supplier
├── id
├── name
├── phone
├── address
├── notes
├── openingBalance
├── createdAt
└── updatedAt
```

Supplier information must be reusable across projects where applicable.

---

# 21. Supplier Ledger

Every supplier transaction must be represented as a ledger entry.

```text
SupplierLedgerEntry
├── id
├── supplierId
├── projectId?
├── type
├── amount
├── referenceId
├── description
├── date
└── createdAt
```

Transaction types:

```text
purchase
payment
adjustment
refund
```

Example:

```text
Purchases       Rs 482,500
Payments        Rs 350,000
Outstanding     Rs 132,500
```

---

# 22. Labour Model

V1 labour tracking should remain intentionally simple.

```text
LabourEntry
├── id
├── projectId
├── workerName
├── role
├── rate
├── days
├── advance
├── amount
├── date
└── notes
```

The architecture must allow future worker entities and attendance.

---

# 23. Dashboard

The dashboard is the primary business screen.

Required sections:

### Project selector

```text
Hayatabad House ▼
```

### Financial summary

```text
Budget
Rs 15.80M

Spent
Rs 8.42M

Remaining
Rs 7.38M
```

### Budget utilization

```text
████████████░░░░ 53.3%
```

### Current-period spending

```text
Materials       Rs 412,500
Labour          Rs 185,000
Transport        Rs 42,000
Equipment        Rs 31,500
Other            Rs 18,200
```

### Recent expenses

Display the latest 5–10 transactions.

### Quick actions

```text
+ Expense
+ Labour
+ Supplier Payment
Reports
```

---

# 24. Project Dashboard

Each project must have its own dashboard.

Sections:

1. Financial overview.
2. Budget utilization.
3. Expense distribution.
4. Recent expenses.
5. Supplier outstanding.
6. Labour spending.
7. Monthly spending.
8. Quick actions.

---

# 25. Project Creation UX

Creation should be a short form.

Required:

* Project name.
* Budget.

Optional:

* Client.
* Location.
* Start date.
* Expected completion date.
* Description.

Do not make users complete unnecessary fields before creating a project.

---

# 26. Expense Creation UX

Expense entry is the most important workflow.

Target:

**Expense should be recordable in approximately 10–20 seconds.**

Primary fields:

```text
Amount
Category
Date
Payment Method
Supplier
Description
Receipt
```

The amount field must receive autofocus when the form opens where practical.

Use numeric keyboard.

---

# 27. Quick Expense Mode

Provide an ultra-fast mode:

```text
Amount
Category
Supplier
Save
```

Optional details can be added later.

This mode is specifically designed for site supervisors.

---

# 28. Receipt Capture

The receipt workflow must support:

* Camera.
* Gallery.
* Image preview.
* Crop.
* Retake.
* Remove.
* Compression.
* Secure local storage.

Images must not unnecessarily consume excessive storage.

The application should create optimized receipt copies while preserving sufficient readability.

---

# 29. OCR Architecture

OCR should be designed as an optional service.

```text
Receipt
 ↓
Image preprocessing
 ↓
OCR
 ↓
Extracted fields
 ↓
User confirmation
 ↓
Expense
```

OCR must **never automatically create a financial transaction without user confirmation**.

Potential extracted values:

* Supplier.
* Date.
* Total.
* Invoice number.
* Line items.

---

# 30. Search

Global and feature-level search must support:

* Expense description.
* Supplier.
* Category.
* Project.
* Amount.
* Date.
* Reference.

Search should be fast on thousands of local records.

Database indexes must support common queries.

---

# 31. Filters

Expense filtering:

```text
Date
Category
Supplier
Payment Method
Amount Range
Project
```

Filters must be combinable.

Provide:

**Clear all**

and visible active-filter indicators.

---

# 32. Expense List

Each row/card should show:

```text
Cement
ABC Building Store

Rs 25,000

17 Sep • Cash
```

Use semantic category icons.

Avoid oversized cards that waste screen space.

---

# 33. Expense Details

Display:

* Amount.
* Category.
* Supplier.
* Date.
* Payment method.
* Description.
* Receipt.
* Project.
* Creation timestamp.
* Modification information where applicable.

Actions:

* Edit.
* Duplicate.
* Delete/void.
* Share.

Destructive actions require confirmation.

---

# 34. Budget vs Actual

For every project:

```text
Category       Budget       Actual       Variance

Cement        1,200,000    1,380,000    +180,000
Steel         2,100,000    1,940,000    -160,000
Labour        1,500,000    1,240,000    -260,000
```

Variance calculations must be deterministic.

---

# 35. Spending Analytics

Required charts:

1. Expense by category.
2. Monthly spending.
3. Budget utilization.
4. Supplier spending.

Charts must:

* Have accessible labels.
* Provide textual equivalents.
* Remain readable on small screens.
* Avoid decorative chart effects.

---

# 36. Reports

Report types:

### Project Summary

* Project information.
* Budget.
* Total spent.
* Remaining.
* Category breakdown.

### Expense Report

* Date range.
* Expenses.
* Categories.
* Suppliers.
* Totals.

### Supplier Report

* Purchases.
* Payments.
* Outstanding.

### Labour Report

* Labour expenses.
* Worker/role summaries.

### Budget Report

* Budget.
* Actual.
* Variance.

---

# 37. PDF Generation

PDF reports must be professionally formatted.

Include:

```text
Company / Project Name
Report Title
Date Range
Generated Date
Summary
Detailed Transactions
Totals
```

PDF must support:

* A4.
* Proper pagination.
* Repeating table headers.
* Currency formatting.
* Long descriptions.
* Receipt thumbnails where appropriate.

---

# 38. Sharing

Use Android's native share mechanism.

Supported destinations should include any installed compatible apps such as:

* WhatsApp.
* Email.
* Telegram.
* Google Drive.
* Bluetooth/file sharing.

The app should not require direct API integration with each destination.

---

# 39. Backup

V1 should support local export.

Recommended format:

```text
ConstructionTrackerBackup.zip
```

Contents:

```text
database
receipts/
metadata
version.json
```

Backup must be encrypted where appropriate.

Restore must validate:

* File integrity.
* Schema version.
* Application compatibility.

---

# 40. Offline-First Requirement

The application must remain fully functional without internet.

Offline operations:

* Create project.
* Create expense.
* Edit expense.
* View reports.
* Search.
* View supplier ledger.
* Attach receipts.
* Generate PDFs.
* Backup locally.

Network connectivity must never block basic financial workflows.

---

# 41. Future Cloud Sync

Architecture must support:

```text
Local Database
      ↕
Sync Engine
      ↕
Cloud Database
```

Every syncable record should eventually have:

```text
id
createdAt
updatedAt
deletedAt
syncStatus
serverVersion
```

Potential states:

```text
local
pending
synced
conflict
failed
```

Do not implement cloud synchronization by tightly coupling UI screens to network calls.

---

# 42. Multi-User Architecture

Future roles:

```text
Owner
Admin
Accountant
Supervisor
Viewer
```

Permissions must be capability-based.

Example:

Supervisor:

```text
Create expense      ✓
Edit own expense    ✓
Delete expense      ✕
View reports        ✓
Manage suppliers    ✕
Manage users        ✕
```

---

# 43. Security

Security requirements:

* No secrets embedded in Flutter client.
* Sensitive configuration must be externalized.
* Local database should support encryption where appropriate.
* Backup files should be protected.
* Destructive operations require confirmation.
* Financial records require auditability.
* Authentication should use established identity providers when cloud functionality is introduced.
* Never trust client-side authorization in a future cloud backend.

---

# 44. Audit Trail

For financial records, maintain:

```text
Created
Edited
Voided
Restored
Payment Added
Backup Restored
```

Audit records should include:

```text
timestamp
userId
action
entityType
entityId
oldValue
newValue
```

Do not permanently erase historical financial transactions merely because the UI exposes a "delete" action.

Prefer:

**Void / archive**

where appropriate.

---

# 45. Validation

Examples:

### Project

Budget:

```text
must be >= 0
```

Name:

```text
required
```

### Expense

Amount:

```text
must be > 0
```

Category:

```text
required
```

Date:

```text
valid date
```

All validation must exist at the domain/application layer, not only in widgets.

---

# 46. Error Handling

Every feature must have:

```text
Loading
Success
Empty
Error
Offline
Retry
```

Errors must be human-readable.

Bad:

> SQLiteException 2067

Good:

> This expense could not be saved. Your existing data is safe. Try again.

Developer logs may contain the technical exception.

---

# 47. Empty States

Empty states should explain the next action.

Example:

```text
No expenses yet

Start tracking your project spending.

[ Add Expense ]
```

Do not display blank screens.

---

# 48. Loading UX

Use:

* Skeletons where useful.
* Progress indicators for operations.
* Immediate optimistic UI only where data integrity permits.

Avoid full-screen loading indicators for small local database operations.

---

# 49. Navigation

Recommended mobile navigation:

```text
Dashboard
Projects
Expenses
Reports
More
```

The primary action should remain easy to reach.

For expense-heavy users, a persistent:

**+ Add Expense**

action should be available from major screens.

---

# 50. Responsive Design

Support:

* Small Android phones.
* Standard Android phones.
* Large phones.
* Tablets.
* Landscape where practical.

Use:

```text
LayoutBuilder
MediaQuery
NavigationRail
NavigationBar
AdaptiveScaffold
```

Avoid hardcoded screen dimensions.

---

# 51. Accessibility

Required:

* Minimum touch target around 48dp.
* Screen-reader labels.
* Sufficient contrast.
* Semantic icons.
* Do not communicate state only through color.
* Support larger text sizes.
* Proper focus order.
* Accessible dialogs.
* Accessible charts.

---

# 52. Motion

Motion should communicate state, not decorate the application.

Use Material motion patterns for:

* Navigation.
* Dialogs.
* Expanding details.
* Confirmation.
* List insertion/removal.

Avoid:

* Constant animated backgrounds.
* Excessive parallax.
* Heavy blur.
* GPU-intensive effects.

---

# 53. Shared UI Component Library

Create a reusable internal component system.

Example:

```text
AppScaffold
AppTopBar
AppSectionHeader
AppCard
AppStatCard
AppMoneyText
AppAmountField
AppSearchField
AppFilterChip
AppDatePicker
AppDropdownField
AppPrimaryButton
AppSecondaryButton
AppDangerButton
AppEmptyState
AppErrorState
AppLoadingState
AppConfirmDialog
AppBottomSheet
AppStatusChip
AppExpenseTile
AppSupplierTile
AppProjectTile
AppMetricRow
AppChartCard
AppReceiptPreview
AppCurrencyText
```

No feature should repeatedly reinvent these components.

---

# 54. Money Display Component

Create a standardized:

```text
MoneyText
```

Requirements:

* PKR formatting.
* Thousands separators.
* Compact notation when appropriate.
* Accessibility-friendly spoken output.
* Negative values.
* Zero values.

Examples:

```text
Rs 1,250
Rs 18,500
Rs 1.25M
```

---

# 55. Date Handling

Use a centralized date service.

Requirements:

* Local timezone.
* Locale-aware formatting.
* Consistent storage.
* Safe date comparisons.
* Date range filtering.

Never scatter custom date formatting throughout the application.

---

# 56. Performance Requirements

The application should feel instant for normal local operations.

Targets:

* Dashboard local data render: preferably <300ms.
* Expense save: preferably <200ms excluding image processing.
* Search: preferably <100ms for normal datasets.
* App cold start: target <2 seconds on representative mid-range Android hardware.
* No unnecessary rebuilds.
* No blocking synchronous work on the UI isolate.

Large operations such as:

* PDF generation.
* OCR preprocessing.
* Large backup creation.

should not freeze the UI.

---

# 57. Memory Requirements

Avoid:

* Loading all receipt images simultaneously.
* Unbounded in-memory lists.
* Large uncompressed images.
* Rebuilding entire dashboards unnecessarily.

Lists should use pagination or incremental loading when datasets become large.

---

# 58. Image Optimization

Receipt images should be:

1. Captured.
2. Cropped.
3. Resized if necessary.
4. Compressed.
5. Stored using stable local identifiers.

Generate thumbnails for list/detail previews.

Do not decode full-resolution images unnecessarily.

---

# 59. Database Performance

Indexes should exist for frequent queries such as:

```text
projectId
expenseDate
categoryId
supplierId
createdAt
```

Composite indexes should be introduced based on measured query patterns.

Use transactions for:

* Expense + ledger operations.
* Supplier payment + balance changes.
* Restore.
* Bulk imports.

---

# 60. Data Integrity

Financial calculations must not depend on cached UI state.

For example:

```text
Project spent
```

must derive from authoritative expense records or a transactionally maintained aggregate.

Never allow a user interface bug to create a financial discrepancy.

---

# 61. Calculation Rules

Project:

```text
Total Spent =
sum(all valid project expenses)
```

Remaining:

```text
Remaining =
Budget - Total Spent
```

Utilization:

```text
Utilization =
Total Spent / Budget × 100
```

Supplier outstanding:

```text
Outstanding =
Purchases
- Payments
+ Adjustments
```

All calculations must have unit tests.

---

# 62. Deletion Strategy

Do not hard-delete financial transactions by default.

Recommended:

```text
Active
Voided
```

Voided transactions remain available to audit.

The UI should clearly distinguish:

```text
Rs 25,000
VOIDED
```

---

# 63. Notifications

V1 optional notifications:

* Project budget threshold.
* Supplier payment due.
* Backup reminder.

Future:

* Labour payment reminders.
* Project inactivity.
* Cloud synchronization failures.

Notifications must be configurable.

---

# 64. Budget Alerts

Allow project-level thresholds:

```text
75%
90%
100%
```

Example:

> Hayatabad House has reached 90% of its Cement budget.

Users should be able to disable alerts.

---

# 65. Project Archive

Completed projects should be archived rather than deleted.

Archived projects remain:

* Searchable.
* Reportable.
* Restorable.

They should not appear in default active-project lists.

---

# 66. Onboarding

Onboarding should be short.

Screen 1:

**Track every rupee spent on construction.**

Screen 2:

**Work offline. Capture receipts. Monitor budgets.**

Screen 3:

**Create your first project.**

Avoid long feature-tour carousels.

---

# 67. First-Run Experience

After onboarding:

```text
Create your first project
```

The user should reach a usable dashboard within minutes.

Recommended flow:

```text
Create Project
      ↓
Set Budget
      ↓
Dashboard
      ↓
Add First Expense
```

---

# 68. Searchable Project Selection

If the user has:

```text
3 projects
```

a simple dropdown is sufficient.

If:

```text
20+ projects
```

use a searchable modal/bottom sheet.

The component should adapt automatically.

---

# 69. Confirmation Patterns

Require confirmation for:

* Voiding expense.
* Restoring backup.
* Deleting project/archive actions.
* Clearing local data.
* Removing receipt.

Do not require confirmation for:

* Opening details.
* Applying filters.
* Saving valid normal records.

---

# 70. Snackbar Strategy

Use snackbars for lightweight confirmation:

> Expense saved.

With optional action:

> Expense saved. **UNDO**

Undo must be implemented only where transactional rollback is safe.

---

# 71. Reporting UX

Reports screen:

```text
Reports

Project Summary
Expense Report
Supplier Ledger
Labour Report
Budget vs Actual
```

Each report should provide:

```text
Date Range
Project
Filters

[ Generate PDF ]
[ Share ]
```

---

# 72. Export Formats

V1:

* PDF.
* CSV.
* Full backup.

CSV export should support:

```text
Date
Project
Category
Supplier
Description
Payment Method
Amount
```

---

# 73. Backup/Restore UX

Backup:

```text
Settings
 → Backup & Restore
 → Create Backup
```

Display:

```text
Last Backup
17 Sep 2026, 10:42 AM
```

Restore must include a clear warning:

> Restoring a backup can replace current local data.

Require explicit confirmation.

---

# 74. Settings

Sections:

### Business

* Business name.
* Phone.
* Address.
* Logo.

### Appearance

* Theme.
* Language.

### Currency

* Default currency.

### Data

* Backup.
* Restore.
* Export.
* Clear local data.

### Notifications

* Budget alerts.
* Reminders.

### About

* Version.
* Privacy.
* Terms.
* Support.

---

# 75. Business Branding

Reports should support:

* Business name.
* Logo.
* Phone.
* Address.
* Optional registration information.

Example:

```text
AFRIDI CONSTRUCTION

Hayatabad House
Project Expense Report

17 September 2026
```

---

# 76. Analytics / Telemetry

If analytics are introduced:

Collect only necessary product telemetry.

Potential events:

```text
project_created
expense_created
expense_voided
report_generated
backup_created
backup_restored
ocr_used
```

Never collect financial transaction amounts as analytics unless explicitly justified and disclosed.

---

# 77. Privacy

The application handles potentially sensitive financial information.

Requirements:

* Clear privacy policy.
* No unnecessary data collection.
* Local data remains local in offline mode.
* User controls backup/export.
* Cloud synchronization must be opt-in or clearly disclosed.
* Receipt images must be treated as private business documents.

---

# 78. Testing Strategy

Required layers:

### Unit Tests

* Calculations.
* Validators.
* Use cases.
* Repository logic.
* Currency formatting.
* Budget calculations.

### Widget Tests

* Forms.
* Dialogs.
* Lists.
* Empty states.
* Error states.

### Integration Tests

* Create project.
* Create expense.
* Add supplier.
* Record supplier payment.
* Generate report.
* Backup/restore.

### Golden Tests

Use for:

* Core dashboard.
* Expense tile.
* Project card.
* Reports.

---

# 79. Critical Acceptance Tests

### Test 1 — Create Project

Given no projects exist:

1. Open app.
2. Create project.
3. Enter name.
4. Enter budget.
5. Save.

Expected:

Project immediately appears on dashboard.

---

### Test 2 — Create Expense Offline

1. Disable network.
2. Open project.
3. Add expense.
4. Save.

Expected:

Expense is persisted locally and visible immediately.

---

### Test 3 — Budget Calculation

Budget:

```text
Rs 1,000,000
```

Expenses:

```text
200,000
300,000
```

Expected:

```text
Spent: Rs 500,000
Remaining: Rs 500,000
Utilization: 50%
```

---

### Test 4 — Supplier Ledger

Purchases:

```text
Rs 100,000
```

Payments:

```text
Rs 60,000
```

Expected:

```text
Outstanding: Rs 40,000
```

---

### Test 5 — Receipt

1. Capture receipt.
2. Save expense.
3. Close application.
4. Reopen.

Expected:

Receipt remains available.

---

# 80. Crash Recovery

The app must handle:

* Unexpected termination.
* Interrupted writes.
* Database errors.
* Corrupt image references.
* Failed PDF generation.

Database transactions must prevent partial financial records.

---

# 81. Logging

Use structured logging.

Levels:

```text
debug
info
warning
error
fatal
```

Never log:

* Passwords.
* Authentication tokens.
* Sensitive financial data unnecessarily.
* Private receipt contents.

---

# 82. Release Build Requirements

Production release must:

* Remove debug logging where inappropriate.
* Disable debug banners.
* Use production configuration.
* Enable crash reporting only according to privacy requirements.
* Verify database migrations.
* Verify backup compatibility.
* Verify Android permissions.
* Verify app signing.
* Verify ProGuard/R8 configuration where applicable.

---

# 83. Android Permissions

Request only permissions required for the current operation.

Potential permissions:

* Camera.
* Notifications.
* Storage/media access where required by Android version.

Do not request broad permissions during onboarding unnecessarily.

---

# 84. Deep Linking

Architecture should allow future links such as:

```text
buildledger://project/{projectId}
buildledger://expense/{expenseId}
```

Useful for future cloud sharing and client portals.

---

# 85. Future SaaS Architecture

The product should eventually support:

```text
Mobile App
    │
    ├── Local SQLite
    │
    └── Sync Layer
             │
             ▼
        API / Backend
             │
       ┌─────┴─────┐
       │           │
   PostgreSQL   Object Storage
       │           │
       └─────┬─────┘
             │
       Authentication
```

Cloud architecture must remain independent of Flutter presentation code.

---

# 86. Future AI Features

AI should be introduced only where it removes manual work.

Potential features:

### Receipt Intelligence

```text
Photo
 ↓
OCR
 ↓
Supplier
Amount
Date
Items
 ↓
User Confirmation
```

### Natural-language expense entry

User writes:

> Paid Ahmed 15 thousand for brick delivery.

The system proposes:

```text
Amount: Rs 15,000
Category: Materials
Subcategory: Bricks
Supplier: Ahmed
Description: Brick delivery
```

User confirms before saving.

### Financial questions

Examples:

> How much did I spend on cement this month?

> Which supplier has the highest outstanding balance?

AI responses must be generated from authoritative application data rather than invented information.

---

# 87. Future BOQ

Architecture should eventually support:

```text
BOQ
├── Item
├── Quantity
├── Unit
├── Estimated Rate
├── Estimated Cost
├── Actual Quantity
├── Actual Cost
└── Variance
```

This allows:

**Estimated construction cost → actual construction cost**

---

# 88. Future Inventory

Potential model:

```text
Material
├── Cement
├── Steel
├── Bricks
└── etc.
```

Transactions:

```text
Purchase
Consumption
Adjustment
Transfer
Return
```

Inventory should not be implemented as a superficial stock counter.

---

# 89. Future Project Progress

Eventually:

```text
Foundation       100%
Structure          80%
Brickwork          55%
Electrical         20%
Plumbing           10%
Finishing           0%
```

This allows financial data to be compared with physical project progress.

---

# 90. UX Principle: Construction Site First

Every major workflow must answer:

> **Can a supervisor use this while standing on a construction site with one hand, sunlight on the screen, limited connectivity, and little patience for complicated forms?**

If not, simplify the workflow.

---

# 91. UX Principle: Progressive Disclosure

Do not show every field immediately.

Basic:

```text
Amount
Category
Supplier
Save
```

Advanced:

```text
Description
Receipt
Reference
Notes
Additional metadata
```

This keeps the primary workflow fast.

---

# 92. UX Principle: Financial Clarity

The interface must make these values obvious:

```text
Budget
Spent
Remaining
Outstanding
Paid
Variance
```

Never make the user navigate through several screens to discover basic project financial status.

---

# 93. UX Principle: No Spreadsheet Mental Model

The application may use tables internally and in reports, but mobile UX should not feel like Excel.

Prefer:

```text
cards
sections
transaction lists
bottom sheets
quick actions
visual summaries
```

Use tables primarily for detailed reports.

---

# 94. UX Principle: Safe Financial Actions

Every financial action must have a clear state.

Example:

```text
ACTIVE
VOIDED
PENDING
SYNCED
FAILED
```

Never silently discard financial information.

---

# 95. Production Definition of Done

A feature is complete only when:

* UI implemented using shared Material 3 components.
* Responsive layouts tested.
* Dark/light themes tested.
* Localization keys added.
* Validation implemented.
* Domain logic tested.
* Database migration implemented.
* Loading state implemented.
* Empty state implemented.
* Error state implemented.
* Offline behavior verified.
* Accessibility checked.
* Performance checked.
* Analytics/privacy implications reviewed.
* Integration tests added where appropriate.

---

# 96. Recommended V1 Navigation

```text
┌─────────────────────────────┐
│ Construction Tracker        │
│                             │
│ Hayatabad House ▼           │
│                             │
│ Rs 8.42M                    │
│ Total Spent                 │
│                             │
│ Budget Utilization          │
│ ███████████░░░ 53%          │
│                             │
│ ┌──────────┐ ┌──────────┐   │
│ │ +Expense │ │ Reports  │   │
│ └──────────┘ └──────────┘   │
│                             │
│ Recent Expenses             │
│                             │
│ Cement       Rs 25,000      │
│ Steel        Rs 82,000      │
│ Labour       Rs 18,500      │
│                             │
│ Dashboard Projects Expenses │
│ Reports       More          │
└─────────────────────────────┘
```

---

# 97. Recommended Feature Roadmap

## Phase 1 — Foundation

* Flutter architecture.
* Material 3 design system.
* Theme.
* Routing.
* SQLite.
* Riverpod.
* Shared components.
* Localization.
* Error handling.

## Phase 2 — Core Financials

* Projects.
* Budgets.
* Expenses.
* Categories.
* Suppliers.
* Supplier ledger.

## Phase 3 — Business Intelligence

* Dashboard.
* Budget vs actual.
* Analytics.
* Reports.
* PDF.
* CSV.

## Phase 4 — Site Productivity

* Receipt camera.
* Image optimization.
* Labour.
* Quick expense mode.
* WhatsApp sharing.

## Phase 5 — Reliability

* Backup.
* Restore.
* Migration framework.
* Crash recovery.
* Performance optimization.
* Accessibility.

## Phase 6 — Commercial SaaS

* Authentication.
* Cloud sync.
* Multi-user.
* Supervisor accounts.
* Subscription system.
* Organization/workspace model.

## Phase 7 — Intelligence

* OCR.
* AI expense extraction.
* Natural-language queries.
* Expense anomaly detection.
* Budget forecasting.

---

# 98. Commercial Product Positioning

The application should not be marketed as:

> "Another expense tracker."

Position it around the specific problem:

> **Construction money tracking without Excel.**

Potential marketing messages:

**Track every rupee. Know every project cost.**

**From receipt to report — built for construction.**

**Your construction site's financial control center.**

---

# 99. Core Product Loop

The entire product should reinforce this loop:

```text
SPEND
  ↓
RECORD
  ↓
CATEGORIZE
  ↓
ANALYZE
  ↓
CONTROL
```

The application succeeds when the contractor can answer these questions immediately:

1. How much have I spent?
2. How much budget remains?
3. Where did the money go?
4. Who do I owe?
5. How much did labour cost?
6. Which category is exceeding budget?
7. What did we spend today?
8. What did we spend this month?
9. Which project is consuming the most money?
10. Can I produce a professional report immediately?

---

# 100. Final Product Standard

The finished application must feel like a **professional construction-business product**, not a hobby expense tracker.

The quality bar is:

**Fast + Offline + Accurate + Simple + Professional + Auditable**

The first release should resist feature bloat.

The strongest V1 is:

```text
PROJECTS
     ↓
BUDGETS
     ↓
EXPENSES
     ↓
RECEIPTS
     ↓
SUPPLIERS
     ↓
LABOUR
     ↓
REPORTS
     ↓
BUDGET CONTROL
```

Everything else should be added only when it strengthens this core workflow.

# End of SRS
