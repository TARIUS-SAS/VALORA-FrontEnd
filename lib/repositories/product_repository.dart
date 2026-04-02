import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/material_item.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductRepository {
  final _db = SupabaseConfig.client;

  // ── Productos ─────────────────────────────────────────────────
  // Nota: Supabase RLS con fn_has_full_access bloquea automáticamente
  // a usuarios con trial vencido devolviendo array vacío o error.
  // Cuando eso pasa lanzamos TrialExpiredException para que la app
  // muestre el paywall.

  Future<List<Product>> getAll(String userId) async {
    try {
      final data = await _db
          .from('products')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => Product.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      // RLS bloqueó el acceso — trial vencido
      if (e.code == '42501' || // insufficient_privilege
          e.message.contains('policy') ||
          e.message.contains('RLS')) {
        throw const TrialExpiredException();
      }
      rethrow;
    }
  }

  Future<Product> create(Product product) async {
    try {
      final data = await _db
          .from('products')
          .insert(product.toJson())
          .select()
          .single();
      return Product.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('policy')) {
        throw const TrialExpiredException();
      }
      rethrow;
    }
  }

  Future<Product> update(Product product) async {
    try {
      final data = await _db
          .from('products')
          .update(product.toJson())
          .eq('id', product.id!)
          .select()
          .single();
      return Product.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('policy')) {
        throw const TrialExpiredException();
      }
      rethrow;
    }
  }

  Future<void> delete(String productId) async {
    try {
      await _db.from('products').delete().eq('id', productId);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('policy')) {
        throw const TrialExpiredException();
      }
      rethrow;
    }
  }

  Future<void> updateCosts({
    required String productId,
    required double materialsCost,
    required double laborHours,
    required double laborCost,
    required double profitPct,
    required double suggestedPrice,
  }) async {
    try {
      await _db.from('products').update({
        'materials_cost':  materialsCost,
        'labor_hours':     laborHours,
        'labor_cost':      laborCost,
        'total_cost':      materialsCost + laborCost,
        'profit_pct':      profitPct,
        'suggested_price': suggestedPrice,
      }).eq('id', productId);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('policy')) {
        throw const TrialExpiredException();
      }
      rethrow;
    }
  }

  // ── Materiales ────────────────────────────────────────────────

  Future<List<MaterialItem>> getMaterials(String productId) async {
    try {
      final data = await _db
          .from('materials')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: true);
      return (data as List).map((e) => MaterialItem.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('policy')) {
        throw const TrialExpiredException();
      }
      rethrow;
    }
  }

  Future<MaterialItem> addMaterial(MaterialItem item) async {
    try {
      final data = await _db
          .from('materials')
          .insert(item.toJson())
          .select()
          .single();
      return MaterialItem.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('policy')) {
        throw const TrialExpiredException();
      }
      rethrow;
    }
  }

  Future<void> deleteMaterial(String materialId) async {
    try {
      await _db.from('materials').delete().eq('id', materialId);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('policy')) {
        throw const TrialExpiredException();
      }
      rethrow;
    }
  }

  Future<MaterialItem> updateMaterial(MaterialItem item) async {
    try {
      final data = await _db
          .from('materials')
          .update({
            'name':          item.name,
            'purchase_qty':  item.purchaseQty,
            'purchase_unit': item.purchaseUnit,
            'purchase_cost': item.purchaseCost,
            'used_qty':      item.usedQty,
            'used_unit':     item.usedUnit,
          })
          .eq('id', item.id!)
          .select()
          .single();
      return MaterialItem.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('policy')) {
        throw const TrialExpiredException();
      }
      rethrow;
    }
  }
}