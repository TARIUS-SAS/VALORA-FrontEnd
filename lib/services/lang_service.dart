// ═══════════════════════════════════════════════════════════════
//  LangService — maneja el idioma activo de la app
//  - El idioma se asigna automáticamente por país al registrarse
//  - Se guarda en Supabase para persistir entre sesiones
//  - El usuario puede cambiarlo desde Configuración
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../core/l10n.dart';

class LangService extends ChangeNotifier {
  static final LangService _instance = LangService._();
  factory LangService() => _instance;
  LangService._();

  String _lang = 'es';

  String  get lang => _lang;
  AppL10n get t    => AppL10n(_lang);

  /// Cambia el idioma y notifica a los widgets que escuchan
  void setLang(String lang) {
    if (_lang == lang) return;
    _lang = lang;
    notifyListeners();
  }

  /// Deduce el idioma del código de país y lo aplica
  /// Retorna el idioma asignado para poder usarlo directamente
  String setFromCountryCode(String countryCode) {
    final lang = langForCountry(countryCode);
    setLang(lang);
    return lang;
  }
}

// Acceso global rápido: l10n.signIn, l10n.email, etc.
AppL10n get l10n => LangService().t;
