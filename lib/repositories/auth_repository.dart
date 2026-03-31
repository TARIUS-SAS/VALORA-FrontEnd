import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/countries.dart';
import '../core/units.dart';

class AuthRepository {
  final _client = SupabaseConfig.client;

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
      email:    email,
      password: password,
      data: {
        'full_name':       fullName,
        'country':         country?.name           ?? '',
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

  // ── Login ─────────────────────────────────────────────────────
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email, password: password,
    );
    await _syncFromProfile();
    return res;
  }

  Future<void> signOut() => _client.auth.signOut();

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

      await _client.auth.updateUser(UserAttributes(data: {
        'measure_system':  data['measure_system']  ?? 'metric',
        'min_wage_hour':   data['min_wage_hour']   ?? 5.0,
        'country_code':    data['country_code']    ?? '',
        'country':         data['country']         ?? '',
        'country_flag':    data['country_flag']    ?? '🌍',
        'currency':        data['currency']        ?? 'Dólar',
        'currency_code':   data['currency_code']   ?? 'USD',
        'currency_symbol': data['currency_symbol'] ?? '\$',
      }));
    } catch (_) {}
  }

  // ── Actualizar perfil ─────────────────────────────────────────
  Future<void> updateProfile({
    String?  fullName,
    Country? country,
    String?  measureSystem,
    double?  minWageHour,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final metaData    = <String, dynamic>{};
    final profileData = <String, dynamic>{};

    if (fullName != null) {
      metaData['full_name']    = fullName;
      profileData['full_name'] = fullName;
    }
    if (measureSystem != null) {
      metaData['measure_system']    = measureSystem;
      profileData['measure_system'] = measureSystem;
    }
    if (minWageHour != null) {
      metaData['min_wage_hour']    = minWageHour;
      profileData['min_wage_hour'] = minWageHour;
    }
    if (country != null) {
      metaData['country']         = country.name;
      metaData['country_code']    = country.code;
      metaData['country_flag']    = country.flag;
      metaData['currency']        = country.currency;
      metaData['currency_code']   = country.currencyCode;
      metaData['currency_symbol'] = country.currencySymbol;
      metaData['min_wage_hour']   = country.minWagePerHour;

      profileData['country']         = country.name;
      profileData['country_code']    = country.code;
      profileData['country_flag']    = country.flag;
      profileData['currency']        = country.currency;
      profileData['currency_code']   = country.currencyCode;
      profileData['currency_symbol'] = country.currencySymbol;
      profileData['min_wage_hour']   = country.minWagePerHour;
    }

    if (metaData.isEmpty) return;

    await _client.auth.updateUser(UserAttributes(data: metaData));
    await _client.from('profiles').update(profileData).eq('id', userId);
  }

  // ── Getters ───────────────────────────────────────────────────
  User?  get currentUser  => _client.auth.currentUser;
  bool   get isLoggedIn   => _client.auth.currentSession != null;

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
  List<String>  get allUnits     => allUnitsForSystem(measureSystem);
  List<dynamic> get groupedUnits => groupedUnitsForSystem(measureSystem);
}