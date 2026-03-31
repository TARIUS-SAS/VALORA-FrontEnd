// lang_service.dart — español fijo
import '../core/l10n.dart';

class LangService {
  static final LangService _instance = LangService._();
  factory LangService() => _instance;
  LangService._();

  String get lang => 'es';
  AppL10n get t   => const AppL10n('es');
}

// Acceso global: l10n.signIn, l10n.email, etc.
AppL10n get l10n => const AppL10n('es');