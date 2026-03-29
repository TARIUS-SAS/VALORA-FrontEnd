import 'package:flutter/material.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';

class ValoraApp extends StatelessWidget {
  const ValoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSession = SupabaseConfig.client.auth.currentSession != null;

    return MaterialApp(
      title: 'Valora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: hasSession ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/login':    (_) => const LoginScreen(),
        '/home':     (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
