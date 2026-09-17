import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:build_ledger/features/settings/data/backup_service.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _backupService = BackupService();
  bool _isProcessing = false;

  void _createBackup() {
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    ShadDialog.show(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Create Encrypted Backup'),
        description: const Text(
          'Your database and receipt photographs will be secured using authenticated AES-256-GCM encryption.',
        ),
        content: KeyboardDismissible(
          child: Form(
            key: formKey,
            child: ShadInput(
              controller: passCtrl,
              obscureText: true,
              label: 'Backup Encryption Password *',
              hint: 'Enter a strong passphrase (min 6 chars)',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) async {
                if (!formKey.currentState!.validate()) return;
                final password = passCtrl.text.trim();
                Navigator.of(ctx).pop();
                _performBackup(password);
              },
              validator: (v) {
                if (v == null || v.trim().length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
          ),
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(),
            size: ShadButtonSize.small,
            label: 'Cancel',
          ),
          ShadButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final password = passCtrl.text.trim();
              Navigator.of(ctx).pop();
              _performBackup(password);
            },
            variant: ShadButtonVariant.primary,
            size: ShadButtonSize.small,
            label: 'Encrypt & Backup',
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup(String password) async {
    setState(() => _isProcessing = true);
    try {
      final exportPath = await _backupService.exportEncryptedBackup(passphrase: password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup encrypted and created successfully!')),
        );
        await Share.shareXFiles(
          [XFile(exportPath)],
          text: 'BuildLedger Encrypted Backup (.buildledger)',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _restoreBackup() async {
    final confirmed = await ShadConfirmDialog.show(
      context,
      title: 'Warning: Restore Data',
      message: 'Restoring an existing backup will replace your current local project and expense data. Ensure you have backed up any recent site changes.',
      confirmLabel: 'Proceed to Restore',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    final passCtrl = TextEditingController();
    final pathCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final passFocusNode = FocusNode();

    Future<void> executeRestore(BuildContext ctx) async {
      if (!formKey.currentState!.validate()) return;
      final path = pathCtrl.text.trim();
      final pass = passCtrl.text.trim();
      Navigator.of(ctx).pop();

      setState(() => _isProcessing = true);
      try {
        await _backupService.restoreEncryptedBackup(filePath: path, passphrase: pass);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored and verified successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }

    ShadDialog.show(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Restore from Encrypted Backup'),
        content: KeyboardDismissible(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadInput(
                  controller: pathCtrl,
                  label: 'Backup File Path *',
                  hint: '/storage/.../BuildLedger.buildledger',
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => passFocusNode.requestFocus(),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Path is required' : null,
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: passCtrl,
                  focusNode: passFocusNode,
                  obscureText: true,
                  label: 'Decryption Password *',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => executeRestore(ctx),
                  validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(),
            size: ShadButtonSize.small,
            label: 'Cancel',
          ),
          ShadButton(
            onPressed: () => executeRestore(ctx),
            variant: ShadButtonVariant.primary,
            size: ShadButtonSize.small,
            label: 'Decrypt & Restore',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          ShadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tokens.successContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.cloud_upload, color: tokens.success, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authenticated Encrypted Backup',
                            style: tokens.typography.p.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AES-256-GCM + SHA-256 Checksum',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tokens.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Package your entire local SQLite database, supplier ledgers, and receipt photographs into an authenticated, encrypted archive (.buildledger). Protect your business data against accidental device loss.',
                  style: tokens.typography.small.copyWith(color: tokens.mutedForeground, height: 1.4),
                ),
                const SizedBox(height: 16),
                ShadButton(
                  onPressed: _isProcessing ? null : _createBackup,
                  icon: Icons.lock,
                  isLoading: _isProcessing,
                  variant: ShadButtonVariant.primary,
                  size: ShadButtonSize.medium,
                  label: 'Create Encrypted Backup Now',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ShadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tokens.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.settings_backup_restore, color: tokens.warning, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restore Database',
                            style: tokens.typography.p.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Integrity & Hash Verified',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tokens.warning),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Restore your projects, expenses, and supplier ledgers from an existing encrypted .buildledger backup file.',
                  style: tokens.typography.small.copyWith(color: tokens.mutedForeground, height: 1.4),
                ),
                const SizedBox(height: 16),
                ShadButton.outline(
                  onPressed: _isProcessing ? null : _restoreBackup,
                  icon: Icons.restore,
                  size: ShadButtonSize.medium,
                  label: 'Restore from Backup File',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

