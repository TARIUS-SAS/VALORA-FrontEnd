import 'package:flutter/material.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/subscription/paywall_screen.dart';

class ValoraApp extends StatelessWidget {
  const ValoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool hasSession = false;
    try {
      hasSession = SupabaseConfig.client.auth.currentSession != null;
    } catch (_) {}

    return MaterialApp(
      title:                     'Valora',
      debugShowCheckedModeBanner: false,
      theme:                     AppTheme.light,
      home:                      hasSession ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/login':    (_) => const LoginScreen(),
        '/home':     (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/paywall':  (_) => const PaywallScreen(),
      },
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Color(0xFFE25A4A)),
                    const SizedBox(height: 16),
                    const Text('Algo salió mal',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(details.exceptionAsString(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (_) => false),
                      child: const Text('Volver al inicio'),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}