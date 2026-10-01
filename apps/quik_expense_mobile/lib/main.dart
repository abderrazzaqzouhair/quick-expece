import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:networking/networking.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit/ui_kit.dart';

import 'config/providers/preferences_providers.dart';
import 'config/router/app_router.dart';
import 'shared/haptics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DioClient.instance.init();
  TokenService.instance.onSessionExpired = () {
    appRouter.go('/sign-in');
  };

  // TODO: remove once real sign-in/session-restore is wired. The router's
  // auth-gate only lets `AppRoutes.home` (the initial route) through when
  // `TokenService.instance.accessToken` is set — without this, launching
  // straight into Home would just get redirected back to sign-in.
  await TokenService.instance.setSession(
    accessToken: 'mock-access-token',
    refreshToken: 'mock-refresh-token',
    userId: 'mock-user-id',
  );

  final prefs = await SharedPreferences.getInstance();
  // Applied before the first frame so early taps already respect it.
  Haptics.enabled = prefs.getBool('settings.haptics') ?? true;

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const QuikExpenseApp(),
    ),
  );
}

class QuikExpenseApp extends StatelessWidget {
  const QuikExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QuikExpense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedLocales,
    );
  }
}
