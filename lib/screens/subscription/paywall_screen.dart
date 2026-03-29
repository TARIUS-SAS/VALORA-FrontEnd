import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  /// Si es true, el usuario llegó aquí porque su trial venció.
  /// Si es false, llegó voluntariamente desde settings.
  final bool trialExpired;

  const PaywallScreen({super.key, this.trialExpired = false});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Map<String, dynamic>? _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await ApiService.getConfig();
      if (mounted) setState(() { _config = config; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _lifetime => _config?['price_lifetime_usd'] ?? '9.99';
  String get _monthly  => _config?['price_monthly_usd']  ?? '2.99';
  String get _annual   => _config?['price_annual_usd']   ?? '19.99';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Header
                    if (widget.trialExpired) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_off_outlined, size: 16, color: AppColors.error),
                            SizedBox(width: 6),
                            Text('Tu prueba gratuita ha vencido',
                                style: TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Ícono y título
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF6B6BE8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 36),
                    ),

                    const SizedBox(height: 20),
                    const Text('Desbloquea Valora Premium',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text('Costea tus productos artesanales sin límites',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        textAlign: TextAlign.center),

                    const SizedBox(height: 28),

                    // Beneficios
                    _BenefitsList(),

                    const SizedBox(height: 28),

                    // Plan Lifetime
                    _PlanCard(
                      title: 'Pago único — para siempre',
                      price: '\$$_lifetime USD',
                      subtitle: 'Un solo pago, acceso de por vida',
                      badge: 'MÁS POPULAR',
                      badgeColor: AppColors.accent,
                      isHighlighted: true,
                      onTap: () => _handlePurchase('lifetime'),
                    ),

                    const SizedBox(height: 12),

                    // Plan mensual
                    _PlanCard(
                      title: 'Suscripción mensual',
                      price: '\$$_monthly USD/mes',
                      subtitle: 'Cancela cuando quieras',
                      onTap: () => _handlePurchase('monthly'),
                    ),

                    const SizedBox(height: 12),

                    // Plan anual
                    _PlanCard(
                      title: 'Suscripción anual',
                      price: '\$$_annual USD/año',
                      subtitle: 'Ahorra vs mensual',
                      badge: 'AHORRO',
                      badgeColor: AppColors.primary,
                      onTap: () => _handlePurchase('annual'),
                    ),

                    const SizedBox(height: 24),

                    // Nota de pago seguro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outlined, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        const Text('Pago seguro a través de Google Play',
                            style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                      ],
                    ),

                    // Botón de salida (solo si llegó voluntariamente)
                    if (!widget.trialExpired) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Ahora no',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _handlePurchase(String plan) async {
    // Por ahora mostramos un mensaje informativo.
    // Cuando integres RevenueCat SDK en Flutter, aquí llamas a:
    // await Purchases.purchaseProduct('valora_$plan');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Próximamente'),
        content: Text(
          'El pago con Google Play estará disponible cuando la app esté publicada en la tienda.\n\n'
          'Plan seleccionado: $plan\n\n'
          'Por ahora puedes usar la app durante tu período de prueba.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// ── Beneficios ────────────────────────────────────────────────

class _BenefitsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.inventory_2_outlined,  'Productos ilimitados'),
      (Icons.calculate_outlined,    'Costeo automático completo'),
      (Icons.science_outlined,      'Lógica compra vs uso'),
      (Icons.schedule_outlined,     'Mano de obra por horas'),
      (Icons.sell_outlined,         'Precio sugerido automático'),
      (Icons.store_outlined,        'Catálogo público del negocio'),
      (Icons.public_outlined,       'Todos los países y monedas'),
      (Icons.support_agent_outlined,'Soporte prioritario'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: benefits.map((b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(b.$1, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(b.$2, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              const Spacer(),
              const Icon(Icons.check_circle, size: 18, color: AppColors.accentDark),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// ── Tarjeta de plan ────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.isHighlighted = false,
  });

  final String   title, price, subtitle;
  final VoidCallback onTap;
  final String?  badge;
  final Color?   badgeColor;
  final bool     isHighlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? AppColors.primary : AppColors.border,
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: isHighlighted
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? Colors.white.withOpacity(0.25)
                            : badgeColor!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isHighlighted ? Colors.white : badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isHighlighted ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isHighlighted ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isHighlighted ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHighlighted ? Colors.white : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Obtener',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isHighlighted ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
