import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/countries.dart';
import '../../repositories/auth_repository.dart';

/// Pantalla que aparece la primera vez que un usuario
/// entra con Google — para configurar país y unidad de medida.
class GoogleSetupScreen extends StatefulWidget {
  const GoogleSetupScreen({super.key});

  @override
  State<GoogleSetupScreen> createState() => _GoogleSetupScreenState();
}

class _GoogleSetupScreenState extends State<GoogleSetupScreen> {
  final _authRepo = AuthRepository();

  Country? _country;
  String   _measureSystem = 'metric';
  bool     _loading = false;

  Future<void> _pickCountry() async {
    final result = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(selected: _country),
    );
    if (result != null) setState(() => _country = result);
  }

  Future<void> _save() async {
    if (_country == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu país'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _authRepo.updateProfile(
        country:       _country,
        measureSystem: _measureSystem,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar. Intenta de nuevo.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Header
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF6B6BE8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.tune_outlined,
                      color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('Una última cosa',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Configura tu país y sistema de medidas\npara calcular costos correctamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
              ),

              const SizedBox(height: 40),

              // País
              const Text('Tu país',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickCountry,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _country != null
                          ? AppColors.primary
                          : AppColors.border,
                      width: _country != null ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _country?.flag ?? '🌍',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _country?.name ?? 'Selecciona tu país',
                          style: TextStyle(
                            fontSize: 15,
                            color: _country != null
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                      if (_country != null)
                        Text(
                          '${_country!.currencySymbol} ${_country!.currencyCode}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_outlined,
                          color: AppColors.textHint),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Sistema de medidas
              const Text('Sistema de medidas',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _MeasureOption(
                      icon: '📏',
                      label: 'Sistema métrico',
                      subtitle: 'kg, lt, m, cm',
                      selected: _measureSystem == 'metric',
                      onTap: () => setState(() => _measureSystem = 'metric'),
                      isFirst: true,
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _MeasureOption(
                      icon: '📐',
                      label: 'Sistema imperial',
                      subtitle: 'lb, oz, ft, in',
                      selected: _measureSystem == 'imperial',
                      onTap: () => setState(() => _measureSystem = 'imperial'),
                      isFirst: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Comenzar',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Opción de medida ──────────────────────────────────────────

class _MeasureOption extends StatelessWidget {
  final String icon, label, subtitle;
  final bool   selected, isFirst;
  final VoidCallback onTap;

  const _MeasureOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top:    Radius.circular(isFirst ? 12 : 0),
            bottom: Radius.circular(isFirst ? 0 : 12),
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selector de país (bottom sheet) ──────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final Country? selected;
  const _CountryPickerSheet({this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _ctrl = TextEditingController();
  List<Country> _filtered = kCountries;

  void _filter(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? kCountries
          : kCountries
              .where((c) =>
                  c.name.toLowerCase().contains(q.toLowerCase()) ||
                  c.code.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Selecciona tu país',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _ctrl,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Buscar país...',
                prefixIcon: const Icon(Icons.search_outlined,
                    color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final sel = c.code == widget.selected?.code;
                return ListTile(
                  leading: Text(c.flag,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(c.name,
                      style: TextStyle(
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.normal,
                          color: sel
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  subtitle: Text(
                      '${c.currencySymbol} ${c.currencyCode}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  trailing: sel
                      ? const Icon(Icons.check_circle,
                          color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}