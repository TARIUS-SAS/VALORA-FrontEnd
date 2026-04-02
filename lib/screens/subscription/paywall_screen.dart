import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../services/subscription_service.dart';

// ── IDs de productos en RevenueCat / Google Play ──────────────
// Deben coincidir EXACTAMENTE con los que crees en:
// 1. Google Play Console → Monetización → Productos
// 2. RevenueCat Dashboard → Products
const _kLifetimeId = 'valora_lifetime';
const _kMonthlyId = 'valora_monthly';
const _kAnnualId = 'valora_annual';

class PaywallScreen extends StatefulWidget {
  /// true  = llegó aquí porque el trial venció (sin botón de salida)
  /// false = llegó voluntariamente desde Settings
  final bool trialExpired;

  const PaywallScreen({super.key, this.trialExpired = false});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Map<String, dynamic>? _config;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  // Precios reales desde Google Play vía RevenueCat
  String _lifetimePrice = '\$9.99';
  String _monthlyPrice = '\$2.99';
  String _annualPrice = '\$19.99';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadConfig(), _loadPricesFromStore()]);
    if (mounted) setState(() => _loading = false);
  }

  // Carga precios de respaldo desde tu backend
  Future<void> _loadConfig() async {
    try {
      final config = await ApiService.getConfig();
      if (mounted) {
        setState(() {
          _config = config;
          // Solo sobreescribir si no pudimos obtener precios de la tienda
        });
      }
    } catch (_) {}
  }

  // Carga precios reales desde Google Play vía RevenueCat
  Future<void> _loadPricesFromStore() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return;

      final lifetime = current.availablePackages
          .where((p) => p.storeProduct.identifier == _kLifetimeId)
          .firstOrNull;
      final monthly = current.availablePackages
          .where((p) => p.storeProduct.identifier == _kMonthlyId)
          .firstOrNull;
      final annual = current.availablePackages
          .where((p) => p.storeProduct.identifier == _kAnnualId)
          .firstOrNull;

      if (mounted) {
        setState(() {
          if (lifetime != null)
            _lifetimePrice = lifetime.storeProduct.priceString;
          if (monthly != null) _monthlyPrice = monthly.storeProduct.priceString;
          if (annual != null) _annualPrice = annual.storeProduct.priceString;
        });
      }
    } catch (e) {
      // Si falla, se muestran los precios del backend como fallback
      debugPrint('Error cargando precios de la tienda: $e');
    }
  }

  // ── Compra real vía RevenueCat → Google Play ─────────────────
  Future<void> _handlePurchase(String productId) async {
    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
      // 1. Obtener el producto de RevenueCat
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current == null) {
        throw Exception('No hay planes disponibles en este momento');
      }

      final package = current.availablePackages
          .where((p) => p.storeProduct.identifier == productId)
          .firstOrNull;

      if (package == null) {
        throw Exception('Producto no disponible: $productId');
      }

      // 2. Iniciar compra — esto abre el sheet de pago de Google Play
      final result = await Purchases.purchasePackage(package);

      // 3. Vincular el ID de RevenueCat con tu backend
      final rcId = result.originalAppUserId;
      await ApiService.linkRevenueCat(rcId);

      // 4. Verificar que el backend ya actualizó el plan
      await SubscriptionService().refresh();

      if (mounted) {
        // Compra exitosa → ir al Home sin posibilidad de volver al Paywall
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Plan activado! Bienvenido a Valora Premium 🎉'),
            backgroundColor: Color(0xFF3AAD5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      }
    } on PurchasesError catch (e) {
      // El usuario canceló — no mostrar error
      if (e.code == PurchasesErrorCode.purchaseCancelledError) {
        setState(() => _purchasing = false);
        return;
      }
      setState(() {
        _error = _mapError(e.code);
        _purchasing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _purchasing = false;
      });
    }
  }

  // ── Restaurar compras anteriores ──────────────────────────────
  Future<void> _restorePurchases() async {
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      await Purchases.restorePurchases();
      final appUserId = await Purchases.appUserID;
      await ApiService.linkRevenueCat(appUserId);
      final status = await SubscriptionService().refresh();

      if (!mounted) return;
      if (status.hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Compra restaurada correctamente!'),
            backgroundColor: Color(0xFF3AAD5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        setState(() {
          _error = 'No encontramos compras previas asociadas a esta cuenta.';
          _purchasing = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Error al restaurar compras. Intenta de nuevo.';
        _purchasing = false;
      });
    }
  }

  String _mapError(PurchasesErrorCode e) {
    switch (e) {
      case PurchasesErrorCode.networkError:
        return 'Error de conexión. Verifica tu internet.';
      case PurchasesErrorCode.storeProblemError:
        return 'Problema con Google Play. Intenta de nuevo.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Pago pendiente. Revisa tu método de pago en Google Play.';
      default:
        return 'Error al procesar el pago. Intenta de nuevo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Si el trial venció, bloquear el botón de back del sistema
      canPop: !widget.trialExpired,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // Badge trial vencido
                          if (widget.trialExpired) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.error.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_off_outlined,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Tu prueba gratuita ha vencido',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Logo
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF6B6BE8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Text(
                            'Desbloquea Valora Premium',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Costea tus productos artesanales sin límites',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 28),
                          const _BenefitsList(),
                          const SizedBox(height: 28),

                          // Error
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.error.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Plan Lifetime — más popular
                          _PlanCard(
                            title: 'Pago único — para siempre',
                            price: _lifetimePrice,
                            subtitle: 'Un solo pago, acceso de por vida',
                            badge: 'MÁS POPULAR',
                            badgeColor: AppColors.accent,
                            isHighlighted: true,
                            loading: _purchasing,
                            onTap: () => _handlePurchase(_kLifetimeId),
                          ),

                          const SizedBox(height: 12),

                          // Plan mensual
                          _PlanCard(
                            title: 'Suscripción mensual',
                            price: '$_monthlyPrice/mes',
                            subtitle: 'Cancela cuando quieras',
                            loading: _purchasing,
                            onTap: () => _handlePurchase(_kMonthlyId),
                          ),

                          const SizedBox(height: 12),

                          // Plan anual
                          _PlanCard(
                            title: 'Suscripción anual',
                            price: '$_annualPrice/año',
                            subtitle: 'Ahorra vs mensual',
                            badge: 'AHORRO',
                            badgeColor: AppColors.primary,
                            loading: _purchasing,
                            onTap: () => _handlePurchase(_kAnnualId),
                          ),

                          const SizedBox(height: 24),

                          // Restaurar compras
                          TextButton(
                            onPressed: _purchasing ? null : _restorePurchases,
                            child: const Text(
                              'Restaurar compras anteriores',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                          // Seguridad
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_outlined,
                                size: 14,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Pago seguro a través de Google Play',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),

                          // Salida voluntaria
                          if (!widget.trialExpired) ...[
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Ahora no',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // Overlay de loading durante la compra
                    if (_purchasing)
                      Container(
                        color: Colors.black.withOpacity(0.35),
                        child: const Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Procesando pago...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'No cierres la app',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Beneficios ────────────────────────────────────────────────

class _BenefitsList extends StatelessWidget {
  const _BenefitsList();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.inventory_2_outlined, 'Productos ilimitados'),
      (Icons.calculate_outlined, 'Costeo automático completo'),
      (Icons.science_outlined, 'Lógica compra vs uso de materiales'),
      (Icons.schedule_outlined, 'Mano de obra por horas'),
      (Icons.sell_outlined, 'Precio sugerido automático'),
      (Icons.public_outlined, 'Todos los países y monedas'),
      (Icons.support_agent_outlined, 'Soporte prioritario'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: benefits
            .map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(b.$1, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      b.$2,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.accentDark,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
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
    required this.loading,
    this.badge,
    this.badgeColor,
    this.isHighlighted = false,
  });

  final String title, price, subtitle;
  final VoidCallback onTap;
  final bool loading;
  final String? badge;
  final Color? badgeColor;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
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
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
                          letterSpacing: 0.5,
                          color: isHighlighted ? Colors.white : badgeColor,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isHighlighted
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isHighlighted
                          ? Colors.white70
                          : AppColors.textSecondary,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
