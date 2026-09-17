import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/app/router/app_router.dart';
import 'package:build_ledger/app/theme/app_theme.dart';

import 'package:build_ledger/app/theme/theme_mode_provider.dart';

class BuildLedgerApp extends ConsumerWidget {
  const BuildLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'BuildLedger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
