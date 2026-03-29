import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/custom_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _repo = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await _repo.signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      if (mounted) _err(_map(e.message));
    } catch (_) {
      if (mounted) _err('Error de conexión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _map(String m) {
    if (m.contains('Invalid login credentials'))
      return 'Correo o contraseña incorrectos';
    if (m.contains('Email not confirmed'))
      return 'Confirma tu correo antes de ingresar';
    if (m.contains('Too many requests'))
      return 'Demasiados intentos. Espera un momento';
    return 'Error al iniciar sesión';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const ValoraLogo(),
                  const SizedBox(height: 40),
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenido de vuelta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ingresa a tu cuenta para continuar',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailCtrl,
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
                        TextFormField(
                          controller: _passCtrl,
                          focusNode: _passFocus,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              AppStrings.forgot,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        CustomButton(
                          label: AppStrings.login,
                          onPressed: _loading ? null : _login,
                          isLoading: _loading,
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
                            AppStrings.google,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        AppStrings.noAccount,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text(
                          AppStrings.signUpLink,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.accent,
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

// ─── Shared auth widgets ──────────────────────────────────────────

class GradientBg extends StatelessWidget {
  const GradientBg({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEFF6FF), Colors.white, Color(0xFFF5FFF8)],
        stops: [0, 0.5, 1],
      ),
    ),
    child: child,
  );
}

class ValoraLogo extends StatelessWidget {
  const ValoraLogo();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF6B6BE8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'V',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6B6BE8)],
        ).createShader(b),
        child: const Text(
          AppStrings.appName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        AppStrings.tagline,
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ],
  );
}

class Card extends StatelessWidget {
  const Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: child,
  );
}

class OrDivider extends StatelessWidget {
  const OrDivider();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'o',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
      Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
    ],
  );
}
