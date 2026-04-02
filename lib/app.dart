import 'package:flutter/material.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/subscription/paywall_screen.dart';
import 'services/subscription_service.dart';

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
      // Si hay sesión activa, primero verifica la suscripción
      home: hasSession ? const _SplashGate() : const LoginScreen(),
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

// ── Splash Gate ───────────────────────────────────────────────
// Se muestra mientras se verifica la suscripción al arrancar.
// Evita el parpadeo de pantallas mostrando un loading limpio.
class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final status = await SubscriptionService().refresh();
      if (!mounted) return;

      if (status.hasAccess) {
        // Tiene acceso → Home normal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // Trial vencido o sin plan → Paywall bloqueante (sin back)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PaywallScreen(trialExpired: true),
          ),
        );
      }
    } catch (_) {
      // Si falla la conexión, dejamos entrar (no bloquear por error de red)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading mientras verifica
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF6B6BE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('V',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color(0xFF4A90E2),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}