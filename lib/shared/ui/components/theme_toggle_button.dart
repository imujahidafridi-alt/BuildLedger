import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/app/theme/theme_mode_provider.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/shared/ui/components/toast/shad_toast.dart';

/// Quick theme toggle button for AppBars and navigation headers.
/// Cycles smoothly between: System Default -> Light -> Dark -> System Default.
class ThemeToggleButton extends ConsumerWidget {
  final Color? color;
  final double size;

  const ThemeToggleButton({
    super.key,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final tokens = context.shad;

    final IconData icon;
    final String tooltip;
    switch (themeMode) {
      case ThemeMode.system:
        icon = Icons.brightness_auto;
        tooltip = 'Theme: System Default (Follows OS)';
        break;
      case ThemeMode.light:
        icon = Icons.light_mode_outlined;
        tooltip = 'Theme: Light Mode';
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode_outlined;
        tooltip = 'Theme: Dark Mode';
        break;
    }

    return IconButton(
      icon: Icon(icon, color: color ?? tokens.foreground, size: size),
      tooltip: tooltip,
      onPressed: () {
        final notifier = ref.read(themeModeProvider.notifier);
        notifier.cycleTheme();

        // Compute next mode for feedback
        final nextMode = themeMode == ThemeMode.system
            ? 'Light Mode'
            : (themeMode == ThemeMode.light ? 'Dark Mode' : 'System Default');

        ShadToast.show(
          context,
          title: 'Theme Updated',
          message: 'Switched to $nextMode',
        );
      },
    );
  }
}
