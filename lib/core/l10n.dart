// ═══════════════════════════════════════════════════════════════
//  L10n — Sistema de multilenguaje
//  El idioma se asigna automáticamente según el país del usuario.
//  El usuario puede cambiarlo desde Configuración.
//  Idiomas: español (es), inglés (en), portugués (pt)
// ═══════════════════════════════════════════════════════════════

// ── Mapeo país → idioma por defecto ──────────────────────────
const Map<String, String> kCountryToLang = {
  // Español
  'AR': 'es', 'BO': 'es', 'CL': 'es', 'CO': 'es', 'CR': 'es',
  'CU': 'es', 'DO': 'es', 'EC': 'es', 'SV': 'es', 'GT': 'es',
  'HN': 'es', 'MX': 'es', 'NI': 'es', 'PA': 'es', 'PY': 'es',
  'PE': 'es', 'ES': 'es', 'UY': 'es', 'VE': 'es', 'GQ': 'es',
  // Portugués
  'BR': 'pt', 'PT': 'pt', 'AO': 'pt', 'MZ': 'pt', 'CV': 'pt',
  'ST': 'pt', 'GW': 'pt', 'TL': 'pt',
  // El resto → inglés por defecto
};

String langForCountry(String countryCode) =>
    kCountryToLang[countryCode.toUpperCase()] ?? 'en';

// ── Textos de la app en los 3 idiomas ────────────────────────
class AppL10n {
  final String lang;
  const AppL10n(this.lang);

  // ── Auth ────────────────────────────────────────────────────
  String get appName        => 'Valora';
  String get tagline        => _t('Tu valor, nuestro compromiso',
                                  'Your value, our commitment',
                                  'Seu valor, nosso compromisso');
  String get welcome        => _t('Bienvenido de vuelta',
                                  'Welcome back',
                                  'Bem-vindo de volta');
  String get loginSubtitle  => _t('Ingresa a tu cuenta para continuar',
                                  'Sign in to your account to continue',
                                  'Entre na sua conta para continuar');
  String get email          => _t('Correo electrónico', 'Email', 'E-mail');
  String get password       => _t('Contraseña', 'Password', 'Senha');
  String get confirmPw      => _t('Confirmar contraseña', 'Confirm password', 'Confirmar senha');
  String get forgotPw       => _t('¿Olvidaste tu contraseña?', 'Forgot your password?', 'Esqueceu sua senha?');
  String get signIn         => _t('Iniciar sesión', 'Sign in', 'Entrar');
  String get signUp         => _t('Crear cuenta', 'Create account', 'Criar conta');
  String get noAccount      => _t('¿No tienes cuenta? ', "Don't have an account? ", 'Não tem conta? ');
  String get hasAccount     => _t('¿Ya tienes cuenta? ', 'Already have an account? ', 'Já tem conta? ');
  String get signUpLink     => _t('Regístrate', 'Sign up', 'Cadastre-se');
  String get signInLink     => _t('Inicia sesión', 'Sign in', 'Entre');
  String get continueGoogle => _t('Continuar con Google', 'Continue with Google', 'Continuar com Google');
  String get terms          => _t('Acepto los ', 'I accept the ', 'Aceito os ');
  String get termsLink      => _t('Términos y condiciones', 'Terms and conditions', 'Termos e condições');
  String get fullName       => _t('Nombre completo', 'Full name', 'Nome completo');

  // ── Errores de auth ─────────────────────────────────────────
  String get errUserNotFound  => _t(
    'No encontramos una cuenta con ese correo. ¿Quieres registrarte?',
    'No account found with that email. Would you like to sign up?',
    'Nenhuma conta encontrada com esse e-mail. Deseja se cadastrar?');
  String get errWrongPassword => _t(
    'Contraseña incorrecta. Inténtalo de nuevo.',
    'Incorrect password. Please try again.',
    'Senha incorreta. Tente novamente.');
  String get errEmailNotConfirmed => _t(
    'Confirma tu correo antes de ingresar.',
    'Please confirm your email before signing in.',
    'Confirme seu e-mail antes de entrar.');
  String get errTooManyRequests => _t(
    'Demasiados intentos. Espera un momento.',
    'Too many attempts. Please wait a moment.',
    'Muitas tentativas. Aguarde um momento.');
  String get errConnection => _t(
    'Error de conexión. Intenta de nuevo.',
    'Connection error. Please try again.',
    'Erro de conexão. Tente novamente.');

  // ── Registro ────────────────────────────────────────────────
  String get selectCountry     => _t('Selecciona tu país', 'Select your country', 'Selecione seu país');
  String get currencyDetected  => _t('Moneda detectada automáticamente',
                                     'Currency detected automatically',
                                     'Moeda detectada automaticamente');
  String get minWageEstimated  => _t('Salario mínimo estimado por hora',
                                     'Estimated minimum wage per hour',
                                     'Salário mínimo estimado por hora');
  String get canAdjustLater    => _t('(puedes ajustarlo después)',
                                     '(you can adjust it later)',
                                     '(você pode ajustar depois)');
  String get measureSystem     => _t('Sistema de medidas', 'Measurement system', 'Sistema de medidas');
  String get metric            => _t('Sistema Métrico', 'Metric System', 'Sistema Métrico');
  String get imperial          => _t('Sistema Imperial', 'Imperial System', 'Sistema Imperial');

  // ── Home ────────────────────────────────────────────────────
  String get myProducts        => _t('Mis productos', 'My products', 'Meus produtos');
  String get newProduct        => _t('Nuevo producto', 'New product', 'Novo produto');
  String get noProducts        => _t('Sin productos aún', 'No products yet', 'Sem produtos ainda');
  String get noProductsHint   => _t('Crea tu primer producto para comenzar a costear',
                                    'Create your first product to start costing',
                                    'Crie seu primeiro produto para começar a costar');
  String get createProduct     => _t('Crear producto', 'Create product', 'Criar produto');

  // ── Productos ───────────────────────────────────────────────
  String get productName       => _t('Nombre del producto', 'Product name', 'Nome do produto');
  String get description       => _t('Descripción', 'Description', 'Descrição');
  String get optional          => _t('(opcional)', '(optional)', '(opcional)');
  String get saveAndContinue   => _t('Guardar y continuar', 'Save and continue', 'Salvar e continuar');
  String get update            => _t('Actualizar', 'Update', 'Atualizar');
  String get editProduct       => _t('Editar producto', 'Edit product', 'Editar produto');

  // ── Materiales ──────────────────────────────────────────────
  String get materials         => _t('Materiales', 'Materials', 'Materiais');
  String get addMaterial       => _t('Agregar material', 'Add material', 'Adicionar material');
  String get whatMaterial      => _t('¿Qué material es?', 'What material is it?', 'Qual é o material?');
  String get howMuchBought     => _t('¿Cuánto compraste y cuánto pagaste?',
                                     'How much did you buy and how much did you pay?',
                                     'Quanto comprou e quanto pagou?');
  String get howMuchUsed       => _t('¿Cuánto vas a usar en este producto?',
                                     'How much will you use in this product?',
                                     'Quanto vai usar neste produto?');
  String get purchaseQty       => _t('Cantidad comprada', 'Purchase quantity', 'Quantidade comprada');
  String get purchaseUnit      => _t('Unidad de compra', 'Purchase unit', 'Unidade de compra');
  String get purchaseCost      => _t('¿Cuánto pagaste por ese paquete?',
                                     'How much did you pay for that package?',
                                     'Quanto pagou por esse pacote?');
  String get usedQty           => _t('Cantidad a usar', 'Quantity to use', 'Quantidade a usar');
  String get usedUnit          => _t('Unidad de uso', 'Unit of use', 'Unidade de uso');
  String get realCost          => _t('Eso te cuesta', 'That costs you', 'Isso te custa');
  String get batchCount        => _t('Con lo que compraste puedes hacer',
                                     'With what you bought you can make',
                                     'Com o que comprou você pode fazer');
  String get units             => _t('unidades', 'units', 'unidades');

  // ── Mano de obra ────────────────────────────────────────────
  String get laborTitle        => _t('Tu tiempo de trabajo', 'Your work time', 'Seu tempo de trabalho');
  String get laborHours        => _t('Horas trabajadas', 'Hours worked', 'Horas trabalhadas');
  String get laborMinutes      => _t('Minutos', 'Minutes', 'Minutos');
  String get laborHourRate     => _t('Tu pago por hora', 'Your hourly rate', 'Seu pagamento por hora');
  String get laborHourRateHint => _t('Salario mínimo de tu país. Puedes cambiarlo.',
                                     'Your country\'s minimum wage. You can change it.',
                                     'Salário mínimo do seu país. Você pode alterar.');
  String get laborResult       => _t('Tu mano de obra vale', 'Your labor is worth', 'Sua mão de obra vale');
  String get laborFormula      => _t('horas × salario/hora', 'hours × hourly rate', 'horas × salário/hora');

  // ── Ganancia ────────────────────────────────────────────────
  String get profitTitle       => _t('¿Cuánto quieres ganar extra?',
                                     'How much extra do you want to earn?',
                                     'Quanto a mais você quer ganhar?');
  String get profitCovered     => _t('Ya en tu precio están cubiertos tus materiales y tu tiempo de trabajo. Lo que agregues aquí es ganancia extra.',
                                     'Your materials and work time are already covered in your price. What you add here is extra profit.',
                                     'Seus materiais e tempo de trabalho já estão cobertos no preço. O que adicionar aqui é lucro extra.');
  String get noExtra           => _t('Sin extra', 'No extra', 'Sem extra');
  String get suggestedPrice    => _t('Precio sugerido de venta', 'Suggested selling price', 'Preço de venda sugerido');
  String get calculatedAuto    => _t('Calculado automáticamente', 'Calculated automatically', 'Calculado automaticamente');
  String get totalCost         => _t('Total costo de producción', 'Total production cost', 'Custo total de produção');
  String get materialsCost     => _t('Costo de materiales', 'Materials cost', 'Custo de materiais');
  String get laborCost         => _t('Mano de obra (tu tiempo)', 'Labor (your time)', 'Mão de obra (seu tempo)');
  String get extraProfit       => _t('Ganancia extra', 'Extra profit', 'Lucro extra');
  String get saveCostingFull   => _t('Guardar costeo completo', 'Save full costing', 'Salvar custeio completo');
  String get saved             => _t('Guardado', 'Saved', 'Salvo');

  // ── Configuración ───────────────────────────────────────────
  String get settings          => _t('Configuración', 'Settings', 'Configurações');
  String get profile           => _t('Perfil', 'Profile', 'Perfil');
  String get editName          => _t('Editar nombre', 'Edit name', 'Editar nome');
  String get changeCountry     => _t('Cambiar país', 'Change country', 'Alterar país');
  String get changeMeasure     => _t('Sistema de medidas', 'Measurement system', 'Sistema de medidas');
  String get changeLanguage    => _t('Idioma', 'Language', 'Idioma');
  String get minWagePerHour    => _t('Salario mínimo por hora', 'Minimum wage per hour', 'Salário mínimo por hora');
  String get signOut           => _t('Cerrar sesión', 'Sign out', 'Sair');
  String get signOutConfirm    => _t('¿Estás seguro de que quieres cerrar sesión?',
                                     'Are you sure you want to sign out?',
                                     'Tem certeza que deseja sair?');
  String get cancel            => _t('Cancelar', 'Cancel', 'Cancelar');
  String get save              => _t('Guardar', 'Save', 'Salvar');
  String get language          => _t('Idioma', 'Language', 'Idioma');
  String get preferences       => _t('Preferencias', 'Preferences', 'Preferências');
  String get information       => _t('Información', 'Information', 'Informações');
  String get appVersion        => _t('Versión de la app', 'App version', 'Versão do app');
  String get privacyPolicy     => _t('Política de privacidad', 'Privacy policy', 'Política de privacidade');

  // ── Planes ──────────────────────────────────────────────────
  String get unlockPremium     => _t('Desbloquea Valora Premium', 'Unlock Valora Premium', 'Desbloqueie Valora Premium');
  String get unlockSubtitle    => _t('Costea tus productos artesanales sin límites',
                                     'Cost your handmade products without limits',
                                     'Custos seus produtos artesanais sem limites');
  String get trialExpiredBadge => _t('Tu prueba gratuita ha vencido',
                                     'Your free trial has expired',
                                     'Seu período de teste gratuito expirou');
  String get lifetimePlan      => _t('Pago único — para siempre', 'One-time payment — forever', 'Pagamento único — para sempre');
  String get lifetimeSubtitle  => _t('Un solo pago, acceso de por vida', 'One payment, lifetime access', 'Um pagamento, acesso vitalício');
  String get monthlyPlan       => _t('Suscripción mensual', 'Monthly subscription', 'Assinatura mensal');
  String get monthlySubtitle   => _t('Cancela cuando quieras', 'Cancel anytime', 'Cancele quando quiser');
  String get annualPlan        => _t('Suscripción anual', 'Annual subscription', 'Assinatura anual');
  String get annualSubtitle    => _t('Ahorra vs mensual', 'Save vs monthly', 'Economize vs mensal');
  String get mostPopular       => _t('MÁS POPULAR', 'MOST POPULAR', 'MAIS POPULAR');
  String get savings           => _t('AHORRO', 'SAVINGS', 'ECONOMIA');
  String get getIt             => _t('Obtener', 'Get it', 'Obter');
  String get notNow            => _t('Ahora no', 'Not now', 'Agora não');
  String get securePayment     => _t('Pago seguro a través de Google Play',
                                     'Secure payment through Google Play',
                                     'Pagamento seguro pelo Google Play');

  // ── Idiomas disponibles ─────────────────────────────────────
  static const Map<String, String> langNames = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
  };

  // ── Interno ─────────────────────────────────────────────────
  String _t(String es, String en, String pt) {
    switch (lang) {
      case 'pt': return pt;
      case 'en': return en;
      default:   return es;
    }
  }
}
