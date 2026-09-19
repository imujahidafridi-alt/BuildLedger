import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Modal dialog displaying BuildLedger application metadata, platform, and diagnostics export.
class AboutSystemDialog extends StatelessWidget {
  const AboutSystemDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AboutSystemDialog(),
    );
  }

  String _getPlatformDescription() {
    if (kIsWeb) return 'Web (Browser)';
    try {
      final os = Platform.operatingSystem.toUpperCase();
      final ver = Platform.operatingSystemVersion.split('\n').first.trim();
      final cleanVer = ver.length > 20 ? '${ver.substring(0, 20)}…' : ver;
      return '$os ($cleanVer)';
    } catch (_) {
      return defaultTargetPlatform.name.toUpperCase();
    }
  }

  void _copySystemInfo(BuildContext context) {
    final platform = _getPlatformDescription();
    final info = '''
BuildLedger 1.0.0 (Build 1)
Lead Developer: Mujahid Afridi (afridilabz@gmail.com)
Platform: $platform
Target: ${defaultTargetPlatform.name}
Architecture: Local Zero-Latency Offline
Database: SQLite WAL Mode
Status: Production Grade
'''.trim();

    Clipboard.setData(ClipboardData(text: info));
    ShadToast.show(
      context,
      title: 'System Info Copied',
      message: 'Diagnostic & developer details copied to clipboard.',
      variant: ShadToastVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final platformDesc = _getPlatformDescription();

    return ShadDialog(
      title: const Text('About BuildLedger'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.primary.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Icon(Icons.apartment, color: tokens.primary, size: 30),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'BuildLedger',
              style: tokens.typography.h3,
            ),
          ),
          Center(
            child: Text(
              'Version 1.0.0 (Build 1)',
              style: tokens.typography.small.copyWith(color: tokens.mutedForeground),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: tokens.border, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Platform', style: tokens.typography.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  platformDesc,
                  style: tokens.typography.small.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Engine Mode', style: tokens.typography.muted),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Local SQLite (WAL)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Security', style: tokens.typography.muted),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AES-256-GCM / SHA-256',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: tokens.border, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lead Developer', style: tokens.typography.muted),
              const SizedBox(width: 12),
              const Text(
                'Mujahid Afridi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Email / Contact', style: tokens.typography.muted),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'afridilabz@gmail.com'));
                  ShadToast.show(
                    context,
                    title: 'Email Copied',
                    message: 'afridilabz@gmail.com copied to clipboard',
                    variant: ShadToastVariant.success,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'afridilabz@gmail.com',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: tokens.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.copy, size: 12, color: tokens.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'High-precision financial control and site expense tracking for modern construction contractors.',
            style: tokens.typography.muted.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        ShadButton.outline(
          label: 'Copy System Info',
          icon: Icons.copy,
          onPressed: () => _copySystemInfo(context),
        ),
        const SizedBox(width: 8),
        ShadButton(
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
