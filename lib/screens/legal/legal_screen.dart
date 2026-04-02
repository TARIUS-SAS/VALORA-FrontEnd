import 'package:flutter/material.dart';
import '../../core/constants.dart';

enum LegalType { privacy, terms }

class LegalScreen extends StatelessWidget {
  final LegalType type;
  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == LegalType.privacy;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isPrivacy ? 'Política de privacidad' : 'Términos y condiciones'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: isPrivacy ? _privacyContent() : _termsContent(),
      ),
    );
  }

  static Widget _h1(String t) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      );

  static Widget _h2(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );

  static Widget _p(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6)),
      );

  static Widget _bullet(String t) => Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
            Expanded(
              child: Text(t,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5)),
            ),
          ],
        ),
      );

  static Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(color: AppColors.divider),
      );

  // ── POLÍTICA DE PRIVACIDAD ─────────────────────────────────

  static List<Widget> _privacyContent() => [
        _p('Última actualización: 02 de abril de 2026 · TARIUS S.A.S · Versión 1.0'),
        _divider(),

        _h1('1. Responsable del tratamiento'),
        _p('TARIUS S.A.S es el responsable del tratamiento de los datos personales recopilados a través de la aplicación Valora.'),
        _bullet('Correo de privacidad: privacidad@tarius.com'),
        _bullet('País de constitución: Colombia'),

        _h1('2. Normatividad aplicable'),
        _p('Esta política cumple con:'),
        _bullet('Ley 1581 de 2012 — Colombia'),
        _bullet('RGPD / GDPR — Unión Europea'),
        _bullet('CCPA — California, Estados Unidos'),
        _bullet('LGPD — Brasil'),
        _bullet('ISO/IEC 27001 — Seguridad de la información'),

        _h1('3. Datos que recopilamos'),
        _h2('Proporcionados por el usuario'),
        _bullet('Nombre completo y correo electrónico'),
        _bullet('País, moneda y sistema de medidas'),
        _bullet('Salario configurado para cálculo de mano de obra'),
        _h2('Generados por el uso'),
        _bullet('Productos, materiales, costos y precios'),
        _bullet('Plan de suscripción activo'),
        _bullet('Identificador de cliente RevenueCat'),
        _h2('NO recopilamos'),
        _bullet('Datos de tarjetas de crédito o débito'),
        _bullet('Datos biométricos ni ubicación en tiempo real'),
        _bullet('Datos de menores de 18 años'),

        _h1('4. Finalidades del tratamiento'),
        _bullet('Crear y gestionar tu cuenta en Valora'),
        _bullet('Prestar el servicio de costeo de productos'),
        _bullet('Gestionar tu plan de suscripción y período de prueba'),
        _bullet('Procesar pagos a través de Google Play y RevenueCat'),
        _bullet('Garantizar la seguridad del servicio'),
        _p('No usamos tus datos para publicidad dirigida ni los compartimos con terceros con fines comerciales.'),

        _h1('5. Seguridad'),
        _bullet('Cifrado TLS 1.3 en todas las comunicaciones'),
        _bullet('Autenticación segura mediante JWT firmados'),
        _bullet('Row Level Security (RLS): cada usuario solo accede a sus datos'),
        _bullet('Contraseñas con hash bcrypt — nunca almacenamos tu contraseña'),
        _bullet('Claves API separadas: pública para la app, privada para el servidor'),

        _h1('6. Proveedores tecnológicos'),
        _bullet('Supabase — base de datos y autenticación (SOC 2 Type 2, GDPR)'),
        _bullet('Railway — servidor backend (TLS 1.3)'),
        _bullet('RevenueCat — gestión de suscripciones (GDPR, CCPA)'),
        _bullet('Google Play — procesamiento de pagos (Google LLC)'),

        _h1('7. Tus derechos'),
        _bullet('Acceso: conocer qué datos tuyos tratamos'),
        _bullet('Rectificación: corregir datos inexactos'),
        _bullet('Supresión: solicitar la eliminación de tus datos'),
        _bullet('Portabilidad: recibir tus datos en formato estándar'),
        _bullet('Oposición: oponerte al tratamiento en ciertas circunstancias'),
        _p('Para ejercer tus derechos escríbenos a privacidad@tarius.com. Respondemos en máximo 15 días hábiles.'),

        _h1('8. Retención de datos'),
        _bullet('Cuenta activa: mientras uses Valora'),
        _bullet('Datos de pago: hasta 5 años por obligaciones fiscales'),
        _bullet('Logs técnicos: máximo 90 días'),
        _bullet('Cuentas inactivas: eliminadas tras 24 meses sin actividad'),

        _h1('9. Menores de edad'),
        _p('Valora está dirigida exclusivamente a personas mayores de 18 años. Si detectamos que un menor ha creado una cuenta, sus datos serán eliminados de inmediato.'),

        _h1('10. Contacto'),
        _p('Para consultas sobre privacidad: privacidad@tarius.com'),
        _p('© 2026 TARIUS S.A.S · Todos los derechos reservados'),
        const SizedBox(height: 40),
      ];

  // ── TÉRMINOS Y CONDICIONES ─────────────────────────────────

  static List<Widget> _termsContent() => [
        _p('Última actualización: 02 de abril de 2026 · TARIUS S.A.S · Versión 1.0'),
        _divider(),

        _h1('1. Aceptación'),
        _p('Al descargar, instalar y usar la aplicación Valora, aceptas estos términos en su totalidad. Si no estás de acuerdo, debes abstenerte de usar la aplicación.'),

        _h1('2. Descripción del servicio'),
        _p('Valora es una herramienta para calcular el costo de productos artesanales de forma automatizada. Incluye registro de materiales, cálculo de mano de obra, precio sugerido y gestión de productos.'),

        _h1('3. Cuenta de usuario'),
        _bullet('Debes proporcionar información veraz y actualizada al registrarte'),
        _bullet('Eres responsable de mantener la confidencialidad de tu contraseña'),
        _bullet('No puedes compartir tu cuenta con terceros'),
        _bullet('Debes ser mayor de 18 años para usar Valora'),

        _h1('4. Planes y pagos'),
        _h2('Período de prueba gratuita'),
        _p('Al registrarte obtienes acceso gratuito durante el período de prueba configurado. Al vencer, debes activar un plan para continuar usando la app.'),
        _h2('Planes disponibles'),
        _bullet('Plan mensual: suscripción renovada automáticamente cada mes'),
        _bullet('Plan anual: suscripción renovada automáticamente cada año'),
        _bullet('Plan vitalicio (lifetime): pago único, acceso permanente sin renovaciones'),
        _h2('Condiciones de pago'),
        _bullet('Todos los pagos se procesan a través de Google Play'),
        _bullet('Las suscripciones se renuevan automáticamente salvo que las canceles antes del período de renovación'),
        _bullet('Puedes cancelar tu suscripción desde Google Play en cualquier momento'),
        _h2('Reembolsos'),
        _p('Los reembolsos se rigen por la política de Google Play. TARIUS S.A.S no gestiona reembolsos directamente.'),

        _h1('5. Uso aceptable'),
        _p('Está expresamente prohibido:'),
        _bullet('Intentar acceder a datos de otros usuarios'),
        _bullet('Realizar ingeniería inversa del software'),
        _bullet('Usar la aplicación para actividades ilícitas o fraudulentas'),
        _bullet('Sobrecargar los servidores de forma deliberada'),
        _bullet('Compartir credenciales de acceso con terceros'),

        _h1('6. Propiedad intelectual'),
        _p('Todos los derechos sobre Valora — diseño, código, marca, logotipo y contenido — son propiedad exclusiva de TARIUS S.A.S. Queda prohibida su reproducción o uso comercial sin autorización escrita.'),

        _h1('7. Limitación de responsabilidad'),
        _p('Valora proporciona cálculos orientativos basados en los datos que ingresas. TARIUS S.A.S no garantiza que los precios sugeridos sean óptimos para cada mercado.'),
        _p('TARIUS S.A.S no será responsable por pérdidas causadas por factores externos, fallas de conectividad o uso indebido de la aplicación.'),

        _h1('8. Suspensión del servicio'),
        _p('TARIUS S.A.S puede suspender o cancelar el acceso de un usuario que incumpla estos términos, sin previo aviso y sin derecho a indemnización.'),

        _h1('9. Modificaciones'),
        _p('Nos reservamos el derecho de modificar estos términos. Los cambios sustanciales serán notificados con al menos 15 días de antelación.'),

        _h1('10. Ley aplicable'),
        _p('Estos términos se rigen por las leyes de Colombia. Para la resolución de controversias, las partes se someten a los tribunales competentes de Colombia.'),

        _h1('11. Contacto'),
        _p('Para consultas: privacidad@tarius.com'),
        _p('© 2026 TARIUS S.A.S · Todos los derechos reservados'),
        const SizedBox(height: 40),
      ];
}