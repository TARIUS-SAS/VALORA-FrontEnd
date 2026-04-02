import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'app.dart';
import 'core/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };

  // Inicializar Supabase
  try {
    await Supabase.initialize(
      url:     SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Error inicializando Supabase: $e');
  }

  // Inicializar RevenueCat
  // IMPORTANTE: Reemplaza 'YOUR_REVENUECAT_GOOGLE_API_KEY' con tu clave
  // de RevenueCat → Project Settings → API Keys → Google Play
  try {
    await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration('YOUR_REVENUECAT_GOOGLE_API_KEY');
    await Purchases.configure(config);
  } catch (e) {
    debugPrint('Error inicializando RevenueCat: $e');
  }

  runApp(const ValoraApp());
}