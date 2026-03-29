// ═══════════════════════════════════════════════════════════════
//  SubscriptionService — estado del plan en memoria
//  La app llama a checkAccess() al abrir y al volver a primer plano.
//  Todos los widgets que necesiten saber si hay acceso usan este servicio.
// ═══════════════════════════════════════════════════════════════

import 'api_service.dart';

class SubscriptionStatus {
  final String plan;
  final bool   hasAccess;
  final String statusLabel;
  final int?   minutesLeft;
  final String trialEndsAt;

  const SubscriptionStatus({
    required this.plan,
    required this.hasAccess,
    required this.statusLabel,
    this.minutesLeft,
    required this.trialEndsAt,
  });

  bool get isTrial    => plan == 'trial';
  bool get isLifetime => plan == 'lifetime';
  bool get isPaid     => plan == 'monthly' || plan == 'annual' || plan == 'lifetime';
  bool get isExpired  => !hasAccess;

  /// Texto amigable para mostrar al usuario
  String get displayLabel {
    if (isLifetime) return 'Plan Vitalicio';
    if (plan == 'monthly') return 'Suscripción Mensual';
    if (plan == 'annual')  return 'Suscripción Anual';
    if (isTrial && hasAccess) {
      final h = (minutesLeft ?? 0) ~/ 60;
      final m = (minutesLeft ?? 0) % 60;
      if (h > 0) return 'Prueba gratis: ${h}h ${m}min';
      return 'Prueba gratis: ${minutesLeft ?? 0} min';
    }
    return 'Prueba vencida';
  }
}

class SubscriptionService {
  // Singleton
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  SubscriptionStatus? _status;
  bool _loading = false;

  SubscriptionStatus? get status => _status;
  bool get hasAccess   => _status?.hasAccess ?? false;
  bool get isLoading   => _loading;

  /// Llama al backend y actualiza el estado del plan.
  /// Úsalo al: abrir la app, volver al home, después de un pago.
  Future<SubscriptionStatus> refresh() async {
    _loading = true;
    try {
      final data = await ApiService.getSubscriptionStatus();
      _status = SubscriptionStatus(
        plan:        data['plan']        as String,
        hasAccess:   data['hasAccess']   as bool,
        statusLabel: data['statusLabel'] as String,
        minutesLeft: data['minutesLeft'] as int?,
        trialEndsAt: data['trialEndsAt'] as String,
      );
      return _status!;
    } finally {
      _loading = false;
    }
  }

  /// Versión rápida: retorna el último estado conocido sin llamar al backend.
  /// Si no hay estado, llama a refresh().
  Future<SubscriptionStatus> get() async {
    return _status ?? await refresh();
  }

  void clear() => _status = null;
}
