import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../repositories/auth_repository.dart';
import '../../services/subscription_service.dart';
import '../subscription/paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthRepository();
  final _sub  = SubscriptionService();
  bool _loadingSub = true;
  SubscriptionStatus? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final s = await _sub.refresh();
      if (mounted) setState(() { _status = s; _loadingSub = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSub = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _sub.clear();
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Perfil del usuario ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    _auth.fullName.isNotEmpty ? _auth.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_auth.fullName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(_auth.countryFlag, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '${_auth.countryName} · ${_auth.currencyCode}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Estado del plan ─────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _status?.isPaid == true
                      ? [AppColors.primary, const Color(0xFF6B6BE8)]
                      : [const Color(0xFFBA7517), const Color(0xFFEF9F27)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _loadingSub
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Row(
                      children: [
                        Icon(
                          _status?.isPaid == true
                              ? Icons.workspace_premium_outlined
                              : Icons.timer_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _status?.isPaid == true ? 'Plan Premium activo' : 'Plan gratuito',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _status?.displayLabel ?? 'Cargando...',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (_status?.isPaid != true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Mejorar',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),
          const _SectionLabel('Preferencias'),
          const SizedBox(height: 10),

          // ── Sistema de medidas ──────────────────────────────
          _SettingsTile(
            icon: Icons.straighten_outlined,
            title: 'Sistema de medidas',
            subtitle: _auth.measureSystem == 'metric' ? 'Sistema Métrico (kg, lt, m)' : 'Sistema Imperial (lb, oz, ft)',
            onTap: null,
          ),

          // ── Salario mínimo ──────────────────────────────────
          _SettingsTile(
            icon: Icons.payments_outlined,
            title: 'Salario mínimo por hora',
            subtitle: '${_auth.currencySymbol} ${_auth.minWagePerHour.toStringAsFixed(2)} / hora',
            onTap: null,
          ),

          const SizedBox(height: 20),
          const _SectionLabel('Información'),
          const SizedBox(height: 10),

          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Versión de la app',
            subtitle: '1.0.0',
            onTap: null,
          ),

          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Política de privacidad',
            subtitle: 'Ver términos y condiciones',
            onTap: () {},
          ),

          const SizedBox(height: 20),

          // ── Cerrar sesión ────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.logout_outlined, color: AppColors.error, size: 18),
              ),
              title: const Text('Cerrar sesión',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
              onTap: _signOut,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5));
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String   title, subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.09), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          trailing: onTap != null ? const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint) : null,
          onTap: onTap,
        ),
      );
}
