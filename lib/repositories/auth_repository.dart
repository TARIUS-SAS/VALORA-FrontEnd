import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/countries.dart';
import '../core/units.dart';

class AuthRepository {
  final _client = SupabaseConfig.client;

  // ── Auth ──────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String countryCode,
    required String measureSystem,
  }) {
    final country = countryByCode(countryCode);
    return _client.auth.signUp(
      email:    email,
      password: password,
      data: {
        'full_name':       fullName,
        'country':         country?.name          ?? '',
        'country_code':    countryCode,
        'country_flag':    country?.flag           ?? '🌍',
        'currency':        country?.currency       ?? 'Dólar',
        'currency_code':   country?.currencyCode   ?? 'USD',
        'currency_symbol': country?.currencySymbol ?? '\$',
        'min_wage_hour':   country?.minWagePerHour ?? 5.0,
        'measure_system':  measureSystem,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  // ── Accesores del usuario actual ──────────────────────────────

  User? get currentUser    => _client.auth.currentUser;
  bool  get isLoggedIn     => _client.auth.currentSession != null;

  String get fullName =>
      currentUser?.userMetadata?['full_name'] as String? ?? 'Usuario';

  String get countryName =>
      currentUser?.userMetadata?['country'] as String? ?? '';

  String get countryFlag =>
      currentUser?.userMetadata?['country_flag'] as String? ?? '🌍';

  String get countryCode =>
      currentUser?.userMetadata?['country_code'] as String? ?? '';

  // ── Moneda ────────────────────────────────────────────────────

  String get currencyName =>
      currentUser?.userMetadata?['currency'] as String? ?? 'Dólar';

  String get currencyCode =>
      currentUser?.userMetadata?['currency_code'] as String? ?? 'USD';

  /// Símbolo de la moneda del usuario: $, €, £, ¥, COP, etc.
  String get currencySymbol =>
      currentUser?.userMetadata?['currency_symbol'] as String? ?? '\$';

  // ── Salario mínimo por hora ───────────────────────────────────

  /// Salario mínimo estimado por hora en la moneda local del usuario.
  double get minWagePerHour =>
      (currentUser?.userMetadata?['min_wage_hour'] as num?)?.toDouble() ?? 5.0;

  // ── Sistema de medidas ────────────────────────────────────────

  String get measureSystem =>
      currentUser?.userMetadata?['measure_system'] as String? ?? 'metric';

  bool get isMetric => measureSystem != 'imperial';

  /// Todas las unidades disponibles según el sistema elegido.
  List<String> get allUnits => allUnitsForSystem(measureSystem);

  /// Unidades agrupadas para el picker con secciones.
  List<dynamic> get groupedUnits => groupedUnitsForSystem(measureSystem);
}