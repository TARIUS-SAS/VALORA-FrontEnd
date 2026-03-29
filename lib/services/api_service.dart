// ═══════════════════════════════════════════════════════════════
//  ApiService — cliente centralizado del backend de Railway
//  Todas las llamadas al backend pasan por aquí.
//  La URL base se puede cambiar en un solo lugar.
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String _baseUrl =
      'https://valora-backend-production.up.railway.app';

  // ── Token JWT del usuario actual ────────────────────────────
  static String? get _token =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Configuración pública de la app ─────────────────────────
  /// Lee precios y duración del trial desde config_app en Supabase.
  /// No requiere auth.
  static Future<Map<String, dynamic>> getConfig() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/config'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error al obtener configuración: ${res.statusCode}');
  }

  // ── Estado del plan del usuario ──────────────────────────────
  /// Retorna: plan, hasAccess, statusLabel, minutesLeft, trialEndsAt
  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/subscription/status'),
      headers: _authHeaders,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error al obtener estado del plan: ${res.statusCode}');
  }

  /// Retorna: trialActive, hoursLeft, minutesLeft, totalMinutesLeft
  static Future<Map<String, dynamic>> getTrialStatus() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/subscription/trial-status'),
      headers: _authHeaders,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error al obtener trial: ${res.statusCode}');
  }

  // ── Productos ────────────────────────────────────────────────
  static Future<List<dynamic>> getProducts() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/products'),
      headers: _authHeaders,
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    if (res.statusCode == 403) throw const TrialExpiredException();
    throw Exception('Error al obtener productos: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> createProduct({
    required String name,
    String? description,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/products'),
      headers: _authHeaders,
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    if (res.statusCode == 403) throw const TrialExpiredException();
    throw Exception('Error al crear producto: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/api/products/$productId'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    if (res.statusCode == 403) throw const TrialExpiredException();
    throw Exception('Error al actualizar producto: ${res.statusCode}');
  }

  static Future<void> deleteProduct(String productId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/api/products/$productId'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) {
      throw Exception('Error al eliminar producto: ${res.statusCode}');
    }
  }

  // ── Materiales ───────────────────────────────────────────────
  static Future<List<dynamic>> getMaterials(String productId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/materials/$productId'),
      headers: _authHeaders,
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    if (res.statusCode == 403) throw const TrialExpiredException();
    throw Exception('Error al obtener materiales: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> addMaterial({
    required String productId,
    required String name,
    required double purchaseQty,
    required String purchaseUnit,
    required double purchaseCost,
    required double usedQty,
    required String usedUnit,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/materials'),
      headers: _authHeaders,
      body: jsonEncode({
        'productId':    productId,
        'name':         name,
        'purchaseQty':  purchaseQty,
        'purchaseUnit': purchaseUnit,
        'purchaseCost': purchaseCost,
        'usedQty':      usedQty,
        'usedUnit':     usedUnit,
      }),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    if (res.statusCode == 403) throw const TrialExpiredException();
    throw Exception('Error al agregar material: ${res.statusCode}');
  }

  static Future<void> deleteMaterial(String materialId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/api/materials/$materialId'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) {
      throw Exception('Error al eliminar material: ${res.statusCode}');
    }
  }
}

// ── Excepción especial para trial vencido ────────────────────
/// Se lanza cuando el backend devuelve 403 trial_expired.
/// La app la captura y muestra el paywall.
class TrialExpiredException implements Exception {
  const TrialExpiredException();
  @override
  String toString() => 'trial_expired';
}
