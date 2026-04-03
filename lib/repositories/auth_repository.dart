import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/countries.dart';
import '../core/units.dart';

class AuthRepository {
  final _client = SupabaseConfig.client;

  // ── Google Sign-In ────────────────────────────────────────────
  // Web Client ID de Google Cloud Console
  // IMPORTANTE: Reemplaza con tu Client ID real
  // Se obtiene en: console.cloud.google.com →
  //   APIs → Credentials → OAuth 2.0 Client IDs → Web client
  static const _webClientId =
      '353044817833-tku8fiqbbcgq9p6fsohuteqfu2350a43.apps.googleusercontent.com';

  final _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: ['email', 'profile'],
  );

  Future<AuthResponse> signInWithGoogle() async {
    try {
      // 1. Abrir selector de cuenta de Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null)
        throw Exception('Inicio cancelado por el usuario');

      // 2. Obtener tokens de autenticación
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null)
        throw Exception('No se pudo obtener el token de Google');

      // 3. Autenticar en Supabase con el token de Google
      final res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      // 4. Sincronizar el perfil si es usuario nuevo
      await _ensureProfile(res.user);

      return res;
    } catch (e) {
      debugPrint('Error Google Sign-In: $e');
      rethrow;
    }
  }

  // Crea el perfil en Supabase si no existe (usuarios nuevos con Google)
  Future<void> _ensureProfile(User? user) async {
    if (user == null) return;
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        // Usuario nuevo — crear perfil con valores por defecto
        await _client.from('profiles').insert({
          'id': user.id,
          'full_name':
              user.userMetadata?['full_name'] ??
              user.userMetadata?['name'] ??
              '',
          'plan': 'trial',
          'trial_started_at': DateTime.now().toIso8601String(),
          'trial_hours': 12,
        });
      }

      await _syncFromProfile();
    } catch (e) {
      debugPrint('Error al crear perfil Google: $e');
    }
  }

  // ── Registro ──────────────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String countryCode,
    required String measureSystem,
  }) {
    final country = countryByCode(countryCode);
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'country': country?.name ?? '',
        'country_code': countryCode,
        'country_flag': country?.flag ?? '🌍',
        'currency': country?.currency ?? 'Dólar',
        'currency_code': country?.currencyCode ?? 'USD',
        'currency_symbol': country?.currencySymbol ?? '\$',
        'min_wage_hour': country?.minWagePerHour ?? 5.0,
        'measure_system': measureSystem,
      },
    );
  }

  // ── Login ─────────────────────────────────────────────────────
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _syncFromProfile();
    return res;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _client.auth.signOut();
  }

  // ── Sincronizar perfil desde BD ───────────────────────────────
  Future<void> _syncFromProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _client
          .from('profiles')
          .select(
            'measure_system, min_wage_hour, country_code, country, '
            'country_flag, currency, currency_code, currency_symbol',
          )
          .eq('id', userId)
          .single();

      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'measure_system': data['measure_system'] ?? 'metric',
            'min_wage_hour': data['min_wage_hour'] ?? 5.0,
            'country_code': data['country_code'] ?? '',
            'country': data['country'] ?? '',
            'country_flag': data['country_flag'] ?? '🌍',
            'currency': data['currency'] ?? 'Dólar',
            'currency_code': data['currency_code'] ?? 'USD',
            'currency_symbol': data['currency_symbol'] ?? '\$',
          },
        ),
      );
    } catch (_) {}
  }

  // ── Actualizar perfil ─────────────────────────────────────────
  Future<void> updateProfile({
    String? fullName,
    Country? country,
    String? measureSystem,
    double? minWageHour,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final metaData = <String, dynamic>{};
    final profileData = <String, dynamic>{};

    if (fullName != null) {
      metaData['full_name'] = fullName;
      profileData['full_name'] = fullName;
    }
    if (measureSystem != null) {
      metaData['measure_system'] = measureSystem;
      profileData['measure_system'] = measureSystem;
    }
    if (minWageHour != null) {
      metaData['min_wage_hour'] = minWageHour;
      profileData['min_wage_hour'] = minWageHour;
    }
    if (country != null) {
      metaData['country'] = country.name;
      metaData['country_code'] = country.code;
      metaData['country_flag'] = country.flag;
      metaData['currency'] = country.currency;
      metaData['currency_code'] = country.currencyCode;
      metaData['currency_symbol'] = country.currencySymbol;
      metaData['min_wage_hour'] = country.minWagePerHour;

      profileData['country'] = country.name;
      profileData['country_code'] = country.code;
      profileData['country_flag'] = country.flag;
      profileData['currency'] = country.currency;
      profileData['currency_code'] = country.currencyCode;
      profileData['currency_symbol'] = country.currencySymbol;
      profileData['min_wage_hour'] = country.minWagePerHour;
    }

    if (metaData.isEmpty) return;

    await _client.auth.updateUser(UserAttributes(data: metaData));
    await _client.from('profiles').update(profileData).eq('id', userId);
  }

  // ── Getters ───────────────────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => _client.auth.currentSession != null;

  String get fullName =>
      currentUser?.userMetadata?['full_name'] as String? ?? 'Usuario';
  String get countryName =>
      currentUser?.userMetadata?['country'] as String? ?? '';
  String get countryFlag =>
      currentUser?.userMetadata?['country_flag'] as String? ?? '🌍';
  String get countryCode =>
      currentUser?.userMetadata?['country_code'] as String? ?? '';
  String get currencyName =>
      currentUser?.userMetadata?['currency'] as String? ?? 'Dólar';
  String get currencyCode =>
      currentUser?.userMetadata?['currency_code'] as String? ?? 'USD';
  String get currencySymbol =>
      currentUser?.userMetadata?['currency_symbol'] as String? ?? '\$';
  double get minWagePerHour =>
      (currentUser?.userMetadata?['min_wage_hour'] as num?)?.toDouble() ?? 5.0;
  String get measureSystem =>
      currentUser?.userMetadata?['measure_system'] as String? ?? 'metric';

  bool get isMetric => measureSystem != 'imperial';
  List<String> get allUnits => allUnitsForSystem(measureSystem);
  List<dynamic> get groupedUnits => groupedUnitsForSystem(measureSystem);
}
