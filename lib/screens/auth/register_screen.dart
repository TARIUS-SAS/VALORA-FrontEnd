import 'package:flutter/material.dart' hide Card;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../core/countries.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart'
    show
        GradientBg,
        ValoraLogo,
        Card,
        OrDivider,
        OrDivider,
        ValoraLogo,
        GradientBg;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _repo = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _loading = false;
  bool _obscure = true;
  bool _obscureC = true;
  bool _terms = false;

  Country? _selectedCountry;
  String _measureSystem = 'metric';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      _err('Selecciona tu país de origen');
      return;
    }
    if (!_terms) {
      _err('Acepta los términos y condiciones');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final res = await _repo.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        fullName: _nameCtrl.text.trim(),
        countryCode: _selectedCountry!.code,
        measureSystem: _measureSystem,
      );
      if (!mounted) return;
      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '¡Cuenta creada! Revisa tu correo para confirmar.',
            ),
            backgroundColor: AppColors.accentDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) _err(_map(e.message));
    } catch (_) {
      if (mounted) _err('Error de conexión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _map(String m) {
    if (m.contains('User already registered'))
      return 'Este correo ya tiene una cuenta';
    if (m.contains('Password should be'))
      return 'La contraseña debe tener al menos 6 caracteres';
    return m;
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ),
  );

  int _strength(String p) {
    if (p.isEmpty) return 0;
    if (p.length < 6) return 1;
    if (p.length < 8) return 2;
    if (p.contains(RegExp(r'\d'))) return 3;
    return 4;
  }

  Color _sColor(int s) => [
    AppColors.divider,
    AppColors.error,
    AppColors.warning,
    AppColors.accent,
    AppColors.accentDark,
  ][s];
  String _sLabel(int s) => ['', 'Muy débil', 'Débil', 'Media', 'Fuerte'][s];

  Future<void> _pickCountry() async {
    final result = await Navigator.push<Country>(
      context,
      MaterialPageRoute(
        builder: (_) => _CountryPickerScreen(selected: _selectedCountry),
      ),
    );
    if (result != null) setState(() => _selectedCountry = result);
  }

  @override
  Widget build(BuildContext context) {
    final pw = _passCtrl.text;
    final s = _strength(pw);
    final country = _selectedCountry;

    return Scaffold(
      body: GradientBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  const ValoraLogo(),
                  const SizedBox(height: 32),

                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Únete a Valora hoy mismo',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Nombre
                        TextFormField(
                          controller: _nameCtrl,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_emailFocus),
                          decoration: const InputDecoration(
                            labelText: AppStrings.fullName,
                            prefixIcon: Icon(
                              Icons.person_outline,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'El nombre es obligatorio';
                            if (v.trim().length < 2)
                              return 'Nombre demasiado corto';
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                        const SizedBox(height: 12),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passFocus),
                          decoration: const InputDecoration(
                            labelText: AppStrings.email,
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'El correo es obligatorio';
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                            ).hasMatch(v.trim()))
                              return 'Correo inválido';
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                        const SizedBox(height: 12),

                        // Contraseña
                        TextFormField(
                          controller: _passCtrl,
                          focusNode: _passFocus,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_confirmFocus),
                          decoration: InputDecoration(
                            labelText: AppStrings.password,
                            prefixIcon: const Icon(
                              Icons.lock_outlined,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: AppColors.textHint,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'La contraseña es obligatoria';
                            if (v.length < 8) return 'Mínimo 8 caracteres';
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),

                        // Indicador fortaleza
                        if (pw.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(
                              4,
                              (i) => Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  height: 4,
                                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                                  decoration: BoxDecoration(
                                    color: i < s
                                        ? _sColor(s)
                                        : AppColors.divider,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (s > 0)
                            Text(
                              _sLabel(s),
                              style: TextStyle(fontSize: 11, color: _sColor(s)),
                            ),
                        ],
                        const SizedBox(height: 12),

                        // Confirmar contraseña
                        TextFormField(
                          controller: _confirmCtrl,
                          focusNode: _confirmFocus,
                          obscureText: _obscureC,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).unfocus(),
                          decoration: InputDecoration(
                            labelText: AppStrings.confirmPw,
                            prefixIcon: const Icon(
                              Icons.lock_open_outlined,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureC
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: AppColors.textHint,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureC = !_obscureC),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Confirma tu contraseña';
                            if (v != _passCtrl.text)
                              return 'Las contraseñas no coinciden';
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),

                        const SizedBox(height: 20),
                        _SectionDivider(label: 'Preferencias'),
                        const SizedBox(height: 16),

                        // ── Selector de país ──────────────────
                        GestureDetector(
                          onTap: _pickCountry,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: country == null
                                    ? AppColors.border
                                    : AppColors.primary,
                                width: country == null ? 1.2 : 1.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: country == null
                                        ? const Icon(
                                            Icons.flag_outlined,
                                            size: 16,
                                            color: AppColors.textHint,
                                          )
                                        : Text(
                                            country.flag,
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    country?.name ?? 'Selecciona tu país',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: country == null
                                          ? AppColors.textHint
                                          : AppColors.textPrimary,
                                      fontWeight: country != null
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Moneda cargada automáticamente ────
                        if (country != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on_outlined,
                                  size: 16,
                                  color: AppColors.accentDark,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Moneda detectada automáticamente',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.accentDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${country.currency} (${country.currencyCode}) — ${country.currencySymbol}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Salario mínimo estimado
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Salario mínimo estimado por hora',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${country.currencySymbol} ${country.minWagePerHour.toStringAsFixed(2)} / hora  (puedes ajustarlo después)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // ── Sistema de medidas ────────────────
                        const Text(
                          'Sistema de medidas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _MeasureOption(
                              icon: '📏',
                              label: 'Sistema Métrico',
                              subtitle: 'kg, lt, m, cm',
                              selected: _measureSystem == 'metric',
                              onTap: () =>
                                  setState(() => _measureSystem = 'metric'),
                            ),
                            const SizedBox(width: 10),
                            _MeasureOption(
                              icon: '📐',
                              label: 'Sistema Imperial',
                              subtitle: 'lb, oz, ft, in',
                              selected: _measureSystem == 'imperial',
                              onTap: () =>
                                  setState(() => _measureSystem = 'imperial'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Términos ──────────────────────────
                        Row(
                          children: [
                            Checkbox(
                              value: _terms,
                              onChanged: (v) =>
                                  setState(() => _terms = v ?? false),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(text: AppStrings.terms),
                                    TextSpan(
                                      text: AppStrings.termsLink,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        CustomButton(
                          label: AppStrings.register,
                          onPressed: (_loading || !_terms) ? null : _register,
                          isLoading: _loading,
                          isAccent: true,
                        ),
                        const SizedBox(height: 16),
                        const OrDivider(),
                        const SizedBox(height: 16),

                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Registrarse con Google',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        AppStrings.hasAccount,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          AppStrings.signInLink,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══ PANTALLA SELECTOR DE PAÍS ════════════════════════════════════

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
            : kCountries
                  .where(
                    (c) =>
                        c.name.toLowerCase().contains(q) ||
                        c.code.toLowerCase().contains(q) ||
                        c.currencyCode.toLowerCase().contains(q),
                  )
                  .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona tu país')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar país o moneda…',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textHint,
                  size: 20,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} países',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Sin resultados',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final c = _filtered[i];
                      final isSelected = widget.selected?.code == c.code;
                      return InkWell(
                        onTap: () => Navigator.pop(context, c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.06)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.divider,
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                c.flag,
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${c.currency} ',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            c.currencyCode,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '  ${c.currencySymbol}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 18,
                                )
                              else
                                const SizedBox(width: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ══ WIDGETS LOCALES ═══════════════════════════════════════════════

class _MeasureOption extends StatelessWidget {
  const _MeasureOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String icon, label, subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ),
      const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
    ],
  );
}
