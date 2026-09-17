import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:build_ledger/features/receipts/data/datasources/receipt_storage_service.dart';
import 'package:build_ledger/app/theme/app_colors.dart';

class ReceiptPickerWidget extends StatefulWidget {
  final String? initialPath;
  final ValueChanged<String?> onReceiptChanged;

  const ReceiptPickerWidget({
    super.key,
    this.initialPath,
    required this.onReceiptChanged,
  });

  @override
  State<ReceiptPickerWidget> createState() => _ReceiptPickerWidgetState();
}

class _ReceiptPickerWidgetState extends State<ReceiptPickerWidget> {
  final _storageService = ReceiptStorageService();
  String? _stagedPath;

  @override
  void initState() {
    super.initState();
    _stagedPath = widget.initialPath;
  }

  Future<void> _pickImage(ImageSource source) async {
    final path = await _storageService.stageReceipt(source: source);
    if (path != null) {
      setState(() => _stagedPath = path);
      widget.onReceiptChanged(path);
    }
  }

  void _removeReceipt() {
    if (_stagedPath != null) {
      _storageService.discardStagedReceipt(_stagedPath);
      setState(() => _stagedPath = null);
      widget.onReceiptChanged(null);
    }
  }

  void _showImagePreview(BuildContext context) {
    if (_stagedPath == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              maxScale: 4.0,
              child: Image.file(
                File(_stagedPath!),
                fit: BoxFit.contain,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close Preview'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_stagedPath != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceElevatedLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showImagePreview(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_stagedPath!),
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Receipt Attached',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => _showImagePreview(context),
                    child: const Text(
                      'Tap thumbnail to inspect',
                      style: TextStyle(fontSize: 12, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.alert),
              onPressed: _removeReceipt,
              tooltip: 'Remove Receipt',
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Capture Receipt'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('From Gallery'),
          ),
        ),
      ],
    );
  }
}
