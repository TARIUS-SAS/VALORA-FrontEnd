import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/countries.dart';
import '../../core/l10n.dart';
import '../../repositories/auth_repository.dart';
import '../../services/lang_service.dart';
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
  SubscriptionStatus? _status;
  bool _loadingSub = true;

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

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _auth.fullName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.editName),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.fullName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text(l10n.save, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _auth.updateProfile(fullName: result);
      if (mounted) setState(() {});
    }
  }

  Future<void> _changeCountry() async {
    final country = await Navigator.push<Country>(
      context,
      MaterialPageRoute(builder: (_) => _CountryPickerScreen(selected: countryByCode(_auth.countryCode))),
    );
    if (country != null) {
      await _auth.updateProfile(country: country);
      if (mounted) setState(() {});
    }
  }

  Future<void> _changeMeasureSystem() async {
    final current = _auth.measureSystem;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.changeMeasure),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _MeasureOption(
            icon: '📏', label: l10n.metric, subtitle: 'kg, lt, m, cm',
            selected: current == 'metric',
            onTap: () => Navigator.pop(context, 'metric'),
          ),
          const SizedBox(height: 10),
          _MeasureOption(
            icon: '📐', label: l10n.imperial, subtitle: 'lb, oz, ft, in',
            selected: current == 'imperial',
            onTap: () => Navigator.pop(context, 'imperial'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ],
      ),
    );
    if (result != null && result != current) {
      await _auth.updateProfile(measureSystem: result);
      if (mounted) setState(() {});
    }
  }


  Future<void> _editMinWage() async {
    final ctrl = TextEditingController(text: _auth.minWagePerHour.toStringAsFixed(2));
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.minWagePerHour),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Este valor se usa para calcular el costo de tu mano de obra. '
            'El valor sugerido es el salario mínimo de ${_auth.countryName}.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${_auth.currencySymbol} por hora',
              prefixText: '${_auth.currencySymbol} ',
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text(l10n.save, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (result != null) {
      final val = double.tryParse(result.replaceAll(',', '.'));
      if (val != null && val > 0) {
        await _auth.updateProfile(minWageHour: val);
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.signOut, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _sub.clear();
    await _auth.signOut();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t    = l10n;
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Perfil ────────────────────────────────────────────
        GestureDetector(
          onTap: _editName,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  _auth.fullName.isNotEmpty ? _auth.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_auth.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.textHint),
                ]),
                const SizedBox(height: 2),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(_auth.countryFlag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text('${_auth.countryName} · ${_auth.currencyCode}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ])),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // ── Estado del plan ───────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _status?.isPaid == true
                    ? [AppColors.primary, const Color(0xFF6B6BE8)]
                    : [const Color(0xFFBA7517), const Color(0xFFEF9F27)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _loadingSub
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Row(children: [
                    Icon(
                      _status?.isPaid == true ? Icons.workspace_premium_outlined : Icons.timer_outlined,
                      color: Colors.white, size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        _status?.isPaid == true ? 'Plan Premium activo' : 'Plan gratuito',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Text(_status?.displayLabel ?? '...',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ])),
                    if (_status?.isPaid != true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Mejorar',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                  ]),
          ),
        ),

        const SizedBox(height: 20),
        _SectionLabel(t.preferences),
        const SizedBox(height: 10),

        // ── País ──────────────────────────────────────────────
        _SettingsTile(
          icon: Icons.flag_outlined,
          title: t.changeCountry,
          subtitle: '${_auth.countryFlag} ${_auth.countryName} · ${_auth.currencyName}',
          onTap: _changeCountry,
        ),

        // ── Sistema de medidas ────────────────────────────────
        _SettingsTile(
          icon: Icons.straighten_outlined,
          title: t.changeMeasure,
          subtitle: _auth.measureSystem == 'metric'
              ? '${t.metric} — kg, lt, m'
              : '${t.imperial} — lb, oz, ft',
          onTap: _changeMeasureSystem,
        ),


        // ── Salario mínimo ────────────────────────────────────
        _SettingsTile(
          icon: Icons.payments_outlined,
          title: t.minWagePerHour,
          subtitle: '${_auth.currencySymbol} ${_auth.minWagePerHour.toStringAsFixed(2)} / hora',
          onTap: _editMinWage,
        ),

        const SizedBox(height: 20),
        _SectionLabel(t.information),
        const SizedBox(height: 10),

        _SettingsTile(
          icon: Icons.info_outline,
          title: t.appVersion,
          subtitle: '1.0.0',
          onTap: null,
        ),

        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: t.privacyPolicy,
          subtitle: 'valora.app/privacy',
          onTap: () {},
        ),

        const SizedBox(height: 20),

        // ── Cerrar sesión ─────────────────────────────────────
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
            title: Text(t.signOut,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
            onTap: _signOut,
          ),
        ),

        const SizedBox(height: 40),
      ]),
    );
  }
}

// ── Picker de país ────────────────────────────────────────────

class _CountryPickerScreen extends StatefulWidget {
  const _CountryPickerScreen({this.selected});
  final Country? selected;
  @override
  State<_CountryPickerScreen> createState() => _CountryPickerScreenState();
}

class _CountryPickerScreenState extends State<_CountryPickerScreen> {
  final _searchCtrl = TextEditingController();
  List<Country> _filtered = kCountries;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase().trim();
      setState(() {
        _filtered = q.isEmpty
            ? kCountries
            : kCountries.where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.currencyCode.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(l10n.selectCountry)),
        body: Column(children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar país o moneda…',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textHint),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textHint),
                        onPressed: () { _searchCtrl.clear(); FocusScope.of(context).unfocus(); })
                    : null,
                filled: true, fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final c = _filtered[i];
              final isSelected = widget.selected?.code == c.code;
              return InkWell(
                onTap: () => Navigator.pop(context, c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
                    border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.8)),
                  ),
                  child: Row(children: [
                    Text(c.flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name, style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                      Row(children: [
                        Text('${c.currency} ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                          child: Text(c.currencyCode, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ])),
                    if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  ]),
                ),
              );
            },
          )),
        ]),
      );
}

// ── Widgets auxiliares ────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, letterSpacing: 0.5));
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon; final String title, subtitle; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          leading: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.09), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.primary, size: 18)),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          trailing: onTap != null ? const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint) : null,
          onTap: onTap,
        ),
      );
}

class _MeasureOption extends StatelessWidget {
  const _MeasureOption({required this.icon, required this.label, required this.subtitle, required this.selected, required this.onTap});
  final String icon, label, subtitle; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.8 : 1.2),
          ),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ]),
        ),
      );
}