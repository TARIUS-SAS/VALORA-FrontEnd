import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/product.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/product_repository.dart';
import '../product/create_product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authRepo    = AuthRepository();
  final _productRepo = ProductRepository();

  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _productRepo.getAll(_authRepo.currentUser!.id);
      if (mounted) setState(() => _products = list);
    } catch (_) {
      if (mounted) _err('Error al cargar productos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _productRepo.delete(p.id!);
    _load();
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );

  void _goCreate({Product? product}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateProductScreen(existing: product)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepo.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Usuario';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authRepo.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header usuario ────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6B6BE8)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text(user?.email ?? '',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_products.length} producto${_products.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // ── Lista ─────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _products.isEmpty
                    ? _EmptyState(onAdd: _goCreate)
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          itemBuilder: (_, i) => _ProductTile(
                            product: _products[i],
                            onTap: () => _goCreate(product: _products[i]),
                            onDelete: () => _delete(_products[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goCreate,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo producto',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Tarjeta de producto ───────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });
  final Product product;
  final VoidCallback onTap, onDelete;

  @override
  Widget build(BuildContext context) {
    final total     = product.totalCost ?? 0;
    final suggested = product.suggestedPrice ?? 0;
    final profit    = product.profitAmount;
    final pct       = product.profitPct ?? 0;
    final hasData   = suggested > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre + acciones
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      if (product.description != null && product.description!.isNotEmpty)
                        Text(product.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textHint),
                  onPressed: onDelete,
                ),
              ],
            ),

            if (hasData) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 12),

              // Stats de costeo
              Row(
                children: [
                  _Stat('Costo total', '\$${total.toStringAsFixed(2)}', AppColors.textSecondary),
                  _Stat('Precio sugerido', '\$${suggested.toStringAsFixed(2)}', AppColors.primary),
                  _Stat('Ganancia', '\$${profit.toStringAsFixed(2)}',
                      profit >= 0 ? AppColors.accent : AppColors.error),
                  _Stat('Margen', '${pct.toStringAsFixed(0)}%',
                      profit >= 0 ? AppColors.accentDark : AppColors.error),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  const Text('Toca para agregar materiales y calcular precio',
                      style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label, value;
  final Color  color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text('Sin productos aún',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Crea tu primer producto para comenzar a costear',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Crear producto'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
          ],
        ),
      );
}