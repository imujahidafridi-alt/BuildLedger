import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/database/transaction_runner.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/core/security/backup_encryptor.dart';

import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/projects/data/repositories/project_repository_impl.dart';

import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier_ledger_entry.dart';
import 'package:build_ledger/features/suppliers/data/repositories/supplier_repository_impl.dart';

import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/expenses/data/repositories/expense_repository_impl.dart';

import 'package:build_ledger/features/labour/domain/entities/labour_entry.dart';
import 'package:build_ledger/features/labour/data/repositories/labour_repository_impl.dart';

import 'package:build_ledger/features/dashboard/data/datasources/dashboard_query_dao.dart';
import 'package:build_ledger/features/reports/data/pdf_report_generator.dart';
import 'package:build_ledger/features/reports/data/csv_report_generator.dart';

void main() {
  late Database db;
  late TransactionRunner transactionRunner;
  late ProjectRepositoryImpl projectRepo;
  late SupplierRepositoryImpl supplierRepo;
  late ExpenseRepositoryImpl expenseRepo;
  late LabourRepositoryImpl labourRepo;
  late DashboardQueryDao dashboardDao;
  late BackupEncryptor backupEncryptor;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // 1. Initialize isolated in-memory test database with full schema & constraints
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await DatabaseHelper.createSchema(db, version);
        },
      ),
    );

    // 2. Mock injector for all repositories and DAOs
    DatabaseHelper.setMockDatabase(db);
    transactionRunner = TransactionRunner();
    projectRepo = ProjectRepositoryImpl(dbHelper: DatabaseHelper(), transactionRunner: transactionRunner);
    supplierRepo = SupplierRepositoryImpl(dbHelper: DatabaseHelper(), transactionRunner: transactionRunner);
    expenseRepo = ExpenseRepositoryImpl(dbHelper: DatabaseHelper(), transactionRunner: transactionRunner);
    labourRepo = LabourRepositoryImpl(dbHelper: DatabaseHelper(), transactionRunner: transactionRunner);
    dashboardDao = DashboardQueryDao(DatabaseHelper());
    backupEncryptor = BackupEncryptor();
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.setMockDatabase(null);
  });

  group('Full Enterprise Financial Flow Integration Test', () {
    test('End-to-End Financial Lifecycle: Project -> Supplier -> Credit & Cash -> Labour -> Void -> Reports', () async {
      final now = DateTime.now();

      // =======================================================================
      // STEP 1: Create Project with 15,000,000 PKR Budget
      // =======================================================================
      final projectId = const Uuid().v4();
      final project = Project(
        id: projectId,
        name: 'Bahria Phase 8 Executive Villa',
        description: 'Luxury 1-Kanal Spanish Villa Construction',
        clientName: 'Chaudhry Tariq Mehmood',
        location: 'Sector C, Bahria Town Phase 8, Rawalpindi',
        budgetAmount: Money.fromMajor(15000000), // 15,000,000 PKR
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final projectResult = await projectRepo.createProject(project);
      expect(projectResult, isA<Success<Project>>());
      final createdProject = (projectResult as Success<Project>).data;
      expect(createdProject.id, projectId);
      expect(createdProject.budgetAmount.majorValue, 15000000);
      expect(createdProject.isActive, isTrue);

      // Verify Initial Dashboard Summary
      var summary = await dashboardDao.getProjectFinancialSummary(projectId);
      expect(summary.actualCost.minorUnits, 0);
      expect(summary.cashOutflow.minorUnits, 0);
      expect(summary.supplierPayables.minorUnits, 0);
      expect(summary.remainingBudget.majorValue, 15000000);
      expect(summary.utilizationPercent, 0);

      // =======================================================================
      // STEP 2: Create Supplier with 50,000 PKR Opening Balance
      // =======================================================================
      final supplierId = const Uuid().v4();
      final initialOpeningBalance = Money.fromMajor(50000); // 50,000 PKR
      final supplier = Supplier(
        id: supplierId,
        name: 'Pak Steel Mills & Hardware',
        phone: '0300-1234567',
        address: 'I-9 Industrial Area, Islamabad',
        currentBalance: Money.zero,
        createdAt: now,
        updatedAt: now,
      );

      final supplierResult = await supplierRepo.createSupplier(supplier, openingBalance: initialOpeningBalance);
      expect(supplierResult, isA<Success<Supplier>>());
      final createdSupplier = (supplierResult as Success<Supplier>).data;
      expect(createdSupplier.currentBalance.majorValue, 50000);

      // Verify Supplier Ledger has the opening balance entry
      final ledgerResult = await supplierRepo.getSupplierLedger(supplierId);
      expect(ledgerResult, isA<Success<List<SupplierLedgerEntry>>>());
      final ledgerEntries = (ledgerResult as Success<List<SupplierLedgerEntry>>).data;
      expect(ledgerEntries.length, 1);
      expect(ledgerEntries.first.entryType, LedgerEntryType.openingBalance);
      expect(ledgerEntries.first.direction, LedgerDirection.credit);
      expect(ledgerEntries.first.amount.majorValue, 50000);

      // =======================================================================
      // STEP 3: Record 250,000 PKR Credit Expense (Purchase on Credit)
      // =======================================================================
      final creditExpenseId = const Uuid().v4();
      final creditExpense = Expense(
        id: creditExpenseId,
        projectId: projectId,
        categoryId: 'cat_mat_steel',
        supplierId: supplierId,
        amount: Money.fromMajor(250000), // 250,000 PKR
        paymentMethod: PaymentMethod.credit,
        expenseDate: now,
        description: '2 Tons Deformed Steel Rebar 60-Grade',
        createdAt: now,
        updatedAt: now,
      );

      final expenseResult = await expenseRepo.recordExpense(creditExpense);
      expect(expenseResult, isA<Success<Expense>>());

      // Verify Supplier Ledger automatically updated with credit purchase entry
      final updatedLedgerRes = await supplierRepo.getSupplierLedger(supplierId);
      final updatedEntries = (updatedLedgerRes as Success<List<SupplierLedgerEntry>>).data;
      expect(updatedEntries.length, 2);

      final purchaseEntry = updatedEntries.firstWhere((e) => e.referenceId == creditExpenseId);
      expect(purchaseEntry.direction, LedgerDirection.credit);
      expect(purchaseEntry.entryType, LedgerEntryType.purchase);
      expect(purchaseEntry.amount.majorValue, 250000);

      // Verify Supplier Balance is now 300,000 PKR (50k opening + 250k purchase)
      final supplierAfterCredit = (await supplierRepo.getSupplierById(supplierId) as Success<Supplier?>).data;
      expect(supplierAfterCredit!.currentBalance.majorValue, 300000);

      // Verify Three-Pillar Financial Engine Dashboard:
      // - Project Cost: 250,000 PKR (Incurred)
      // - Cash Outflow: 0 PKR (Liquid cash has NOT left pocket)
      // - Supplier Payable: 250,000 PKR (Payable for this project)
      summary = await dashboardDao.getProjectFinancialSummary(projectId);
      expect(summary.actualCost.majorValue, 250000);
      expect(summary.cashOutflow.minorUnits, 0);
      expect(summary.supplierPayables.majorValue, 250000);

      // =======================================================================
      // STEP 4: Record 80,000 PKR Cash Expense (Direct Cash Purchase)
      // =======================================================================
      final cashExpenseId = const Uuid().v4();
      final cashExpense = Expense(
        id: cashExpenseId,
        projectId: projectId,
        categoryId: 'cat_mat_cement',
        supplierId: null,
        amount: Money.fromMajor(80000), // 80,000 PKR
        paymentMethod: PaymentMethod.cash,
        expenseDate: now,
        description: '50 Bags Bestway OPC Cement',
        createdAt: now,
        updatedAt: now,
      );

      await expenseRepo.recordExpense(cashExpense);

      // Verify Dashboard:
      // - Project Cost: 250,000 + 80,000 = 330,000 PKR
      // - Cash Outflow: 80,000 PKR
      // - Supplier Payable: 250,000 PKR
      summary = await dashboardDao.getProjectFinancialSummary(projectId);
      expect(summary.actualCost.majorValue, 330000);
      expect(summary.cashOutflow.majorValue, 80000);
      expect(summary.supplierPayables.majorValue, 250000);

      // =======================================================================
      // STEP 5: Record 100,000 PKR Cash Payment to Supplier
      // =======================================================================
      final paymentResult = await supplierRepo.recordPayment(
        supplierId: supplierId,
        projectId: projectId,
        amount: Money.fromMajor(100000),
        description: 'Cheque/Cash payment on account',
        date: now,
        referenceId: 'CHQ-8821',
      );
      expect(paymentResult, isA<Success<SupplierLedgerEntry>>());

      // Verify Supplier Balance drops from 300,000 to 200,000 PKR
      final supplierAfterPayment = (await supplierRepo.getSupplierById(supplierId) as Success<Supplier?>).data;
      expect(supplierAfterPayment!.currentBalance.majorValue, 200000);

      // Verify Dashboard:
      // - Project Cost: 330,000 PKR (Settling liability does NOT increase project cost)
      // - Cash Outflow: 80,000 (cement) + 100,000 (payment) = 180,000 PKR
      // - Supplier Payable: 250,000 - 100,000 = 150,000 PKR for this project
      summary = await dashboardDao.getProjectFinancialSummary(projectId);
      expect(summary.actualCost.majorValue, 330000);
      expect(summary.cashOutflow.majorValue, 180000);
      expect(summary.supplierPayables.majorValue, 150000);

      // =======================================================================
      // STEP 6: Record Labour Shift with Fixed-Point Days (2.5 days = 250)
      // =======================================================================
      final labourId = const Uuid().v4();
      final dailyWage = Money.fromMajor(3500); // 3,500 PKR/day
      const daysX100 = 250; // 2.5 days
      final advance = Money.fromMajor(1500); // 1,500 PKR advance
      // Net = (3,500 * 250 / 100) - 1,500 = 8,750 - 1,500 = 7,250 PKR
      final netWage = LabourEntry.calculateNetWage(rate: dailyWage, daysX100: daysX100, advance: advance);
      expect(netWage.majorValue, 7250);

      final labourEntry = LabourEntry(
        id: labourId,
        projectId: projectId,
        workerName: 'Ustad Rasheed (Mason Lead)',
        role: 'Mason (Mistri)',
        rate: dailyWage,
        daysX100: daysX100,
        advance: advance,
        netAmount: netWage,
        entryDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final labourResult = await labourRepo.recordLabourShift(labourEntry, autoCreateProjectExpense: true);
      expect(labourResult, isA<Success<LabourEntry>>());

      // Verify Dashboard:
      // - Project Cost: 330,000 + 7,250 = 337,250 PKR
      // - Cash Outflow: 180,000 + 7,250 = 187,250 PKR
      summary = await dashboardDao.getProjectFinancialSummary(projectId);
      expect(summary.actualCost.minorUnits, 33725000);
      expect(summary.cashOutflow.minorUnits, 18725000);

      // =======================================================================
      // STEP 7: Audit-Preserving Void Semantics & Automatic Reversal
      // =======================================================================
      // Void the 80,000 PKR Cash Expense
      final voidCashResult = await expenseRepo.voidExpense(
        expenseId: cashExpenseId,
        reason: 'Duplicate voucher entered in error',
        actor: 'site_engineer',
      );
      expect(voidCashResult, isA<Success<void>>());

      // Attempting to void an already voided record must fail
      final doubleVoidResult = await expenseRepo.voidExpense(
        expenseId: cashExpenseId,
        reason: 'Second attempt',
        actor: 'site_engineer',
      );
      expect(doubleVoidResult, isA<FailureResult<void>>());

      // Verify Dashboard after voiding cash expense:
      // - Project Cost drops by 80,000 PKR -> 257,250 PKR
      // - Cash Outflow drops by 80,000 PKR -> 107,250 PKR
      summary = await dashboardDao.getProjectFinancialSummary(projectId);
      expect(summary.actualCost.minorUnits, 25725000);
      expect(summary.cashOutflow.minorUnits, 10725000);

      // Void the 250,000 PKR Credit Expense
      final voidCreditResult = await expenseRepo.voidExpense(
        expenseId: creditExpenseId,
        reason: 'Material batch returned to supplier',
        actor: 'project_manager',
      );
      expect(voidCreditResult, isA<Success<void>>());

      // Verify Compensating Reversal Entry added to Supplier Ledger:
      // A debit adjustment of 250,000 PKR must exist
      final ledgerAfterCreditVoid = (await supplierRepo.getSupplierLedger(supplierId) as Success<List<SupplierLedgerEntry>>).data;
      final reversalEntry = ledgerAfterCreditVoid.firstWhere((e) => e.entryType == LedgerEntryType.adjustment);
      expect(reversalEntry.direction, LedgerDirection.debit);
      expect(reversalEntry.amount.majorValue, 250000);

      // Supplier balance adjusts:
      // Initial 50k + 250k (purchase) - 100k (payment) - 250k (void reversal) = -50,000 PKR (we overpaid by 50k)
      final supplierAfterReversal = (await supplierRepo.getSupplierById(supplierId) as Success<Supplier?>).data;
      expect(supplierAfterReversal!.currentBalance.minorUnits, -5000000);

      // =======================================================================
      // STEP 8: Multi-Page PDF & CSV Report Generation
      // =======================================================================
      final expensesList = (await expenseRepo.getExpenses(projectId: projectId, includeVoided: true) as Success<List<Expense>>).data;
      expect(expensesList.length, 3);

      // 1. Generate Project Summary PDF
      final projectPdfBytes = await PdfReportGenerator.generateProjectSummaryReport(summary: summary);
      expect(projectPdfBytes, isNotEmpty);
      expect(projectPdfBytes.length, greaterThan(1500));

      // 2. Generate Supplier Ledger PDF
      final supplierPdfBytes = await PdfReportGenerator.generateSupplierLedgerReport(
        supplier: supplierAfterReversal,
        ledgerEntries: ledgerAfterCreditVoid,
      );
      expect(supplierPdfBytes, isNotEmpty);
      expect(supplierPdfBytes.length, greaterThan(1500));

      // 3. Generate Expense Ledger PDF
      final expensePdfBytes = await PdfReportGenerator.generateExpenseReport(
        projectName: createdProject.name,
        expenses: expensesList,
      );
      expect(expensePdfBytes, isNotEmpty);
      expect(expensePdfBytes.length, greaterThan(1500));

      // 4. Generate CSV Export
      final csvString = CsvReportGenerator.generateExpenseCsv(expensesList);
      expect(csvString, contains('Expense ID,Date,Project,Category'));
      expect(csvString, contains('VOIDED'));
      expect(csvString, contains('Duplicate voucher entered in error'));

      // =======================================================================
      // STEP 9: Project Archive & Restore Lifecycle
      // =======================================================================
      await projectRepo.archiveProject(projectId);
      final activeProjectsAfterArchive = (await projectRepo.getProjects(includeArchived: false) as Success<List<Project>>).data;
      expect(activeProjectsAfterArchive.any((p) => p.id == projectId), isFalse);

      final archivedProjects = (await projectRepo.getProjects(includeArchived: true) as Success<List<Project>>).data;
      final retrievedArchived = archivedProjects.firstWhere((p) => p.id == projectId);
      expect(retrievedArchived.isArchived, isTrue);
      expect(retrievedArchived.archivedAt, isNotNull);

      // Restore Project
      await projectRepo.restoreProject(projectId);
      final activeProjectsAfterRestore = (await projectRepo.getProjects(includeArchived: false) as Success<List<Project>>).data;
      expect(activeProjectsAfterRestore.any((p) => p.id == projectId), isTrue);

      // =======================================================================
      // STEP 10: Authenticated Backup Encryption, Tamper-Resistance & Round-trip
      // =======================================================================
      final rawMockDbPayload = Uint8List.fromList([
        0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00,
        ...List.generate(200, (i) => (i * 7) % 256),
      ]);

      const securePassphrase = 'Enterprise#Secure#Passphrase!2026';

      // 1. Authenticated Encryption (AES-256-GCM with 100k PBKDF2 iterations)
      final encryptedBytes = await backupEncryptor.encryptBytes(
        plainBytes: rawMockDbPayload,
        passphrase: securePassphrase,
      );
      expect(encryptedBytes.length, greaterThan(rawMockDbPayload.length));

      // 2. Tamper resistance: Flip a single byte in ciphertext
      final tamperedBytes = Uint8List.fromList(encryptedBytes);
      tamperedBytes[45] ^= 0xFF; // Mutate byte

      // Tampered payload must fail authenticated decryption immediately
      expect(
        () async => await backupEncryptor.decryptBytes(
          encryptedData: tamperedBytes,
          passphrase: securePassphrase,
        ),
        throwsA(isA<FormatException>()),
      );

      // Wrong passphrase must fail
      expect(
        () async => await backupEncryptor.decryptBytes(
          encryptedData: encryptedBytes,
          passphrase: 'WrongPassphraseAttempt',
        ),
        throwsA(isA<FormatException>()),
      );

      // Correct passphrase recovers exact binary payload
      final decryptedBytes = await backupEncryptor.decryptBytes(
        encryptedData: encryptedBytes,
        passphrase: securePassphrase,
      );
      expect(decryptedBytes, equals(rawMockDbPayload));
    });
  });
}
