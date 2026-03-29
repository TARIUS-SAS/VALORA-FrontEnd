import '../core/supabase_client.dart';
import '../models/material_item.dart';
import '../models/product.dart';

class ProductRepository {
  final _db = SupabaseConfig.client;

  // ── Productos ─────────────────────────────────────────────────

  Future<List<Product>> getAll(String userId) async {
    final data = await _db
        .from('products')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> create(Product product) async {
    final data = await _db
        .from('products')
        .insert(product.toJson())
        .select()
        .single();
    return Product.fromJson(data);
  }

  Future<Product> update(Product product) async {
    final data = await _db
        .from('products')
        .update(product.toJson())
        .eq('id', product.id!)
        .select()
        .single();
    return Product.fromJson(data);
  }

  Future<void> delete(String productId) =>
      _db.from('products').delete().eq('id', productId);

  // ── Actualizar costos calculados ──────────────────────────────

  Future<void> updateCosts({
    required String productId,
    required double materialsCost,
    required double laborCost,
    required double profitPct,
    required double suggestedPrice,
  }) async {
    await _db.from('products').update({
      'materials_cost':  materialsCost,
      'labor_cost':      laborCost,
      'total_cost':      materialsCost + laborCost,
      'profit_pct':      profitPct,
      'suggested_price': suggestedPrice,
    }).eq('id', productId);
  }

  // ── Materiales ────────────────────────────────────────────────

  Future<List<MaterialItem>> getMaterials(String productId) async {
    final data = await _db
        .from('materials')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => MaterialItem.fromJson(e)).toList();
  }

  Future<MaterialItem> addMaterial(MaterialItem item) async {
    final data = await _db
        .from('materials')
        .insert(item.toJson())
        .select()
        .single();
    return MaterialItem.fromJson(data);
  }

  Future<void> deleteMaterial(String materialId) =>
      _db.from('materials').delete().eq('id', materialId);
}