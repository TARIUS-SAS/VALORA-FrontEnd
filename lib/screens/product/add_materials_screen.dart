import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/units.dart';
import '../../models/material_item.dart';
import '../../models/product.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/material_card.dart';

class AddMaterialsScreen extends StatefulWidget {
  const AddMaterialsScreen({super.key, required this.product});
  final Product product;
  @override
  State<AddMaterialsScreen> createState() => _AddMaterialsScreenState();
}

class _AddMaterialsScreenState extends State<AddMaterialsScreen> {
  final _repo     = ProductRepository();
  final _authRepo = AuthRepository();

  final _formKey        = GlobalKey<FormState>();
  final _matNameCtrl    = TextEditingController();
  final _purchaseQtyCtrl= TextEditingController();
  final _purchaseCostCtrl=TextEditingController();
  final _usedQtyCtrl    = TextEditingController();

  // Mano de obra — un solo campo HH:MM
  final _hoursCtrl = TextEditingController(text: '00:00');

  String _purchaseUnit = 'Unidad';
  String _usedUnit     = 'Unidad';

  bool _loadingList = true;
  bool _saving      = false;

  List<MaterialItem> _materials = [];
  double             _profitExtra = 0; // ganancia extra en dinero

  // ── Accesores de moneda y salario ────────────────────────────
  String get _sym   => _authRepo.currencySymbol;
  double get _wage  => _authRepo.minWagePerHour;

  // ── Cálculos ─────────────────────────────────────────────────
  double get _materialsCost =>
      _materials.fold(0.0, (s, m) => s + m.actualCost);

  /// Parsea el campo HH:MM y retorna horas decimales.
  /// Ejemplos: "01:30" → 1.5,  "2:00" → 2.0,  "0:45" → 0.75
  double get _laborHours {
    final text = _hoursCtrl.text.trim();
    if (text.contains(':')) {
      final parts = text.split(':');
      final h = double.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (double.tryParse(parts[1]) ?? 0) : 0;
      return h + m / 60;
    }
    // Si el usuario escribe solo un número, lo trata como horas
    return double.tryParse(text) ?? 0;
  }

  double get _laborCost => _laborHours * _wage;

  double get _totalCost => _materialsCost + _laborCost;

  double get _suggestedPrice => _totalCost + _profitExtra;

  // ── Preview del material en tiempo real ──────────────────────
  MaterialItem? get _previewItem {
    final name  = _matNameCtrl.text.trim();
    final pQty  = double.tryParse(_purchaseQtyCtrl.text.replaceAll(',', '.'));
    final pCost = double.tryParse(_purchaseCostCtrl.text.replaceAll(',', '.'));
    final uQty  = double.tryParse(_usedQtyCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || pQty == null || pCost == null) return null;
    if (pQty <= 0) return null;
    final usedQty = isUncountable(_usedUnit) ? 1.0 : (uQty ?? 0);
    return MaterialItem(
      productId: widget.product.id ?? '',
      name: name,
      purchaseQty: pQty, purchaseUnit: _purchaseUnit,
      purchaseCost: pCost,
      usedQty: usedQty, usedUnit: _usedUnit,
    );
  }

  @override
  void initState() {
    super.initState();
    _profitExtra = widget.product.suggestedPrice != null &&
            widget.product.totalCost != null
        ? (widget.product.suggestedPrice! - widget.product.totalCost!)
            .clamp(0, double.infinity)
        : 0;
    _hoursCtrl.addListener(() => setState(() {}));
    for (final c in [_matNameCtrl, _purchaseQtyCtrl, _purchaseCostCtrl, _usedQtyCtrl]) {
      c.addListener(() => setState(() {}));
    }
    _loadMaterials();
  }

  @override
  void dispose() {
    _matNameCtrl.dispose(); _purchaseQtyCtrl.dispose();
    _purchaseCostCtrl.dispose(); _usedQtyCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() => _loadingList = true);
    try {
      final list = await _repo.getMaterials(widget.product.id!);
      if (mounted) setState(() => _materials = list);
    } catch (_) { _err('Error al cargar materiales'); }
    finally { if (mounted) setState(() => _loadingList = false); }
  }

  Future<void> _addMaterial() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final usedQty = isUncountable(_usedUnit)
          ? 1.0
          : double.parse(_usedQtyCtrl.text.replaceAll(',', '.'));
      await _repo.addMaterial(MaterialItem(
        productId:    widget.product.id!,
        name:         _matNameCtrl.text.trim(),
        purchaseQty:  double.parse(_purchaseQtyCtrl.text.replaceAll(',', '.')),
        purchaseUnit: _purchaseUnit,
        purchaseCost: double.parse(_purchaseCostCtrl.text.replaceAll(',', '.')),
        usedQty:      usedQty,
        usedUnit:     _usedUnit,
      ));
      _matNameCtrl.clear(); _purchaseQtyCtrl.clear();
      _purchaseCostCtrl.clear(); _usedQtyCtrl.clear();
      await _loadMaterials();
      await _syncCosts();
      _ok('Material agregado');
    } catch (e) { _err('Error al agregar: $e'); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _deleteMaterial(MaterialItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar material'),
        content: Text('¿Eliminar "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.deleteMaterial(item.id!);
    await _loadMaterials();
    await _syncCosts();
  }

  Future<void> _syncCosts() async {
    if (widget.product.id == null) return;
    // profitPct se almacena solo como referencia; el precio sugerido es directo
    final profitPct = _totalCost > 0
        ? (_profitExtra / (_totalCost + _profitExtra) * 100)
        : 0.0;
    await _repo.updateCosts(
      productId:      widget.product.id!,
      materialsCost:  _materialsCost,
      laborCost:      _laborCost,
      profitPct:      profitPct,
      suggestedPrice: _suggestedPrice,
    );
  }

  void _err(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m), backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  void _ok(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m), backgroundColor: AppColors.accentDark,
        behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  @override
  Widget build(BuildContext context) {
    final preview        = _previewItem;
    final allUnits       = _authRepo.allUnits;
    final uncountable    = isUncountable(_usedUnit);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton.icon(
            onPressed: () async { await _syncCosts(); _ok('Guardado'); },
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ══ 1. AGREGAR MATERIAL ════════════════════════════
            _SectionCard(title: 'Agregar material', icon: Icons.add_box_outlined,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _matNameCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: '¿Qué material es?',
                        hintText: 'Ej: Harina, Goma, Tela, Pintura…',
                        prefixIcon: Icon(Icons.category_outlined, size: 18, color: AppColors.textHint),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    const SizedBox(height: 14),
                    _SubLabel(icon: Icons.shopping_bag_outlined, text: '¿Cuánto compraste y cuánto pagaste?'),
                    const SizedBox(height: 8),

                    Row(children: [
                      Expanded(flex: 2,
                        child: TextFormField(
                          controller: _purchaseQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad comprada',
                            hintText: 'Ej: 1',
                            prefixIcon: Icon(Icons.numbers, size: 18, color: AppColors.textHint),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final d = double.tryParse(v.replaceAll(',', '.'));
                            if (d == null || d <= 0) return 'Mayor a 0';
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(flex: 2,
                        child: _GroupedUnitPicker(
                          label: 'Unidad de compra',
                          value: _purchaseUnit,
                          measureSystem: _authRepo.measureSystem,
                          onChanged: (v) => setState(() => _purchaseUnit = v),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _purchaseCostCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: '¿Cuánto pagaste por ese paquete? ($_sym)',
                        hintText: 'Ej: 5.00',
                        prefixIcon: const Icon(Icons.attach_money, size: 18, color: AppColors.textHint),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido';
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    const SizedBox(height: 14),
                    _SubLabel(icon: Icons.science_outlined, text: '¿Cuánto vas a usar en este producto?'),
                    const SizedBox(height: 8),

                    Row(children: [
                      // Si la unidad de uso es incontable, se oculta el campo de cantidad
                      if (!uncountable)
                        Expanded(flex: 2,
                          child: TextFormField(
                            controller: _usedQtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _addMaterial(),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad a usar',
                              hintText: 'Ej: 500',
                              prefixIcon: Icon(Icons.colorize_outlined, size: 18, color: AppColors.textHint),
                            ),
                            validator: (v) {
                              if (uncountable) return null;
                              if (v == null || v.isEmpty) return 'Requerido';
                              final d = double.tryParse(v.replaceAll(',', '.'));
                              if (d == null || d <= 0) return 'Mayor a 0';
                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),
                        ),
                      if (!uncountable) const SizedBox(width: 10),
                      Expanded(flex: 2,
                        child: _GroupedUnitPicker(
                          label: 'Unidad de uso',
                          value: _usedUnit,
                          measureSystem: _authRepo.measureSystem,
                          onChanged: (v) => setState(() => _usedUnit = v),
                        ),
                      ),
                    ]),

                    // Nota si es incontable
                    if (uncountable) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Las unidades "Al gusto", "Gota" y "Pizca" no afectan el costo. El material queda registrado como referencia.',
                                style: TextStyle(fontSize: 11, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Preview en tiempo real
                    if (preview != null) ...[
                      const SizedBox(height: 12),
                      _CalcPreview(item: preview, symbol: _sym),
                    ],

                    const SizedBox(height: 14),
                    CustomButton(label: 'Agregar material', onPressed: _saving ? null : _addMaterial, isLoading: _saving),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ══ 2. LISTA DE MATERIALES ═════════════════════════
            _SectionCard(title: 'Materiales del producto (${_materials.length})', icon: Icons.list_alt_outlined,
              child: _loadingList
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary)))
                  : _materials.isEmpty
                      ? const _EmptyMaterials()
                      : Column(children: [
                          ..._materials.map((m) => MaterialCard(item: m, onDelete: () => _deleteMaterial(m))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal materiales', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text('$_sym ${_materialsCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ]),
            ),

            const SizedBox(height: 16),

            // ══ 3. COSTO DE MANO DE OBRA ════════════════════════
            _SectionCard(title: 'Costo de mano de obra', icon: Icons.engineering_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo único HH:MM
                  TextFormField(
                    controller: _hoursCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Tiempo invertido (HH:MM)',
                      hintText: '01:30',
                      helperText: 'Ejemplo: 01:30 = 1 hora 30 minutos',
                      prefixIcon: Icon(Icons.access_time_outlined, size: 18, color: AppColors.textHint),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  // Cálculo automático
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B6BE8).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6B6BE8).withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calculate_outlined, color: Color(0xFF6B6BE8), size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_laborHours.toStringAsFixed(2)} horas  ×  $_sym ${_authRepo.minWagePerHour.toStringAsFixed(2)}/hora',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          const Text('Costo de mano de obra:',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      )),
                      Text('$_sym ${_laborCost.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF6B6BE8))),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ══ 4. GANANCIA EXTRA ══════════════════════════════
            _SectionCard(title: '¿Cuánto quieres ganar extra?', icon: Icons.add_circle_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contexto: ya están cubiertos los costos
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.accentDark, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Ya en tu precio están cubiertos tus materiales ($_sym ${_materialsCost.toStringAsFixed(2)}) '
                        'y tu tiempo de trabajo ($_sym ${_laborCost.toStringAsFixed(2)}). '
                        'Lo que agregues aquí es ganancia extra.',
                        style: const TextStyle(fontSize: 11, color: AppColors.accentDark, height: 1.4),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // Slider de ganancia extra
                  Row(children: [
                    Expanded(
                      child: Slider(
                        value: _profitExtra.clamp(0, (_totalCost * 3).clamp(1, double.infinity)),
                        min: 0,
                        max: (_totalCost * 3).clamp(1, double.infinity),
                        activeColor: AppColors.accent,
                        inactiveColor: AppColors.divider,
                        onChanged: (v) => setState(() => _profitExtra = double.parse(v.toStringAsFixed(2))),
                        onChangeEnd: (_) => _syncCosts(),
                      ),
                    ),
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$_sym ${_profitExtra.toStringAsFixed(2)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentDark)),
                    ),
                  ]),

                  // Opciones rápidas
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [0, 5, 10, 20, 50].map((extra) {
                      final val   = extra.toDouble();
                      final active= (_profitExtra - val).abs() < 0.01;
                      return GestureDetector(
                        onTap: () { setState(() => _profitExtra = val); _syncCosts(); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.accent : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: active ? AppColors.accent : AppColors.border),
                          ),
                          child: Text(
                            extra == 0 ? 'Sin extra' : '+$_sym $extra',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: active ? Colors.white : AppColors.textSecondary),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ══ RESUMEN DEL COSTEO ═════════════════════════════
            _CostSummary(
              materialsCost:  _materialsCost,
              laborCost:      _laborCost,
              totalCost:      _totalCost,
              profitExtra:    _profitExtra,
              suggestedPrice: _suggestedPrice,
              symbol:         _sym,
            ),

            const SizedBox(height: 20),

            CustomButton(
              label: 'Guardar costeo completo',
              onPressed: () async { await _syncCosts(); _ok('Costeo guardado correctamente'); },
              isAccent: true,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ══ RESUMEN DEL COSTEO ═══════════════════════════════════════════

class _CostSummary extends StatelessWidget {
  const _CostSummary({
    required this.materialsCost, required this.laborCost,
    required this.totalCost,     required this.profitExtra,
    required this.suggestedPrice,required this.symbol,
  });
  final double materialsCost, laborCost, totalCost, profitExtra, suggestedPrice;
  final String symbol;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 32, height: 32,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6B6BE8)]), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.calculate_outlined, color: Colors.white, size: 17)),
              const SizedBox(width: 10),
              const Text('Resumen del costeo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 16),
            _SRow(icon: Icons.category_outlined, iconColor: AppColors.primary, label: 'Costo de materiales', value: '$symbol ${materialsCost.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            _SRow(icon: Icons.engineering_outlined, iconColor: const Color(0xFF6B6BE8), label: 'Mano de obra (tu tiempo)', value: '$symbol ${laborCost.toStringAsFixed(2)}'),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.divider)),
            _SRow(icon: Icons.receipt_long_outlined, iconColor: AppColors.primary, label: 'Total costo de producción', value: '$symbol ${totalCost.toStringAsFixed(2)}', bold: true, valueColor: AppColors.primary),
            const SizedBox(height: 12),
            if (profitExtra > 0) ...[
              _SRow(icon: Icons.add_circle_outline, iconColor: AppColors.accent, label: 'Ganancia extra', value: '+$symbol ${profitExtra.toStringAsFixed(2)}', bold: true, valueColor: AppColors.accentDark),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.divider, thickness: 1.5)),
            ] else ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.divider, thickness: 1.5)),
            ],
            // Precio sugerido
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6B6BE8)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                const Icon(Icons.sell_outlined, color: Colors.white70, size: 22),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Precio sugerido de venta', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('Calculado automáticamente', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ])),
                Text('$symbol ${suggestedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ]),
            ),
          ],
        ),
      );
}

class _SRow extends StatelessWidget {
  const _SRow({required this.icon, required this.iconColor, required this.label, required this.value,
      this.bold = false, this.valueColor = AppColors.textPrimary});
  final IconData icon; final Color iconColor, valueColor;
  final String label, value; final bool bold;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 30, height: 30,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 15, color: iconColor)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: bold ? FontWeight.w600 : FontWeight.normal))),
        Text(value, style: TextStyle(fontSize: bold ? 15 : 13, color: valueColor, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
      ]);
}

// ══ PREVIEW CÁLCULO TIEMPO REAL ══════════════════════════════════

class _CalcPreview extends StatelessWidget {
  const _CalcPreview({required this.item, required this.symbol});
  final MaterialItem item;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    if (item.isUncountableMaterial) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Este material no afecta el costo — se registra como referencia',
              style: const TextStyle(fontSize: 11, color: AppColors.primary)),
        ]),
      );
    }
    final pct    = item.usagePercent;
    final isOver = pct > 100;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOver ? AppColors.error.withOpacity(0.06) : AppColors.accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOver ? AppColors.error.withOpacity(0.3) : AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isOver ? Icons.warning_amber_outlined : Icons.calculate_outlined,
              size: 16, color: isOver ? AppColors.error : AppColors.accentDark),
          const SizedBox(width: 8),
          Text(isOver ? 'Usas más de lo que compraste' : 'Vista previa del cálculo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isOver ? AppColors.error : AppColors.accentDark)),
        ]),
        const SizedBox(height: 10),
        _PRow('Compraste', '${item.purchaseQty} ${item.purchaseUnit}  →  $symbol ${item.purchaseCost.toStringAsFixed(2)}'),
        const SizedBox(height: 4),
        _PRow('Vas a usar', '${item.usedQty} ${item.usedUnit}  (${pct.toStringAsFixed(0)}% del total)'),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: AppColors.divider, height: 1)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Eso te cuesta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text('$symbol ${item.actualCost.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ]),
        const SizedBox(height: 6),
        if (!item.isUncountableMaterial && item.batchCount != double.infinity)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.repeat, size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(
                'Con lo que compraste puedes hacer ${item.batchCount.toStringAsFixed(1)} unidades de este producto',
                style: const TextStyle(fontSize: 11, color: AppColors.primary),
              )),
            ]),
          ),
      ]),
    );
  }
}

class _PRow extends StatelessWidget {
  const _PRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 76, child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ]);
}

// ══ PICKER DE UNIDADES AGRUPADO ═══════════════════════════════════

class _GroupedUnitPicker extends StatelessWidget {
  const _GroupedUnitPicker({required this.label, required this.value, required this.measureSystem, required this.onChanged});
  final String label, value, measureSystem;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final groups = groupedUnitsForSystem(measureSystem);
    final allUnits = groups.expand((g) => g.units).toList();
    final safeValue = allUnits.contains(value) ? value : allUnits.first;

    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _UnitPickerSheet(groups: groups, selected: safeValue),
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(safeValue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          )),
          const Icon(Icons.expand_more, size: 18, color: AppColors.textHint),
        ]),
      ),
    );
  }
}

class _UnitPickerSheet extends StatelessWidget {
  const _UnitPickerSheet({required this.groups, required this.selected});
  final List<UnitGroup> groups;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Selecciona unidad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            children: groups.map((group) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                  child: Text(group.label.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary, letterSpacing: 1)),
                ),
                ...group.units.map((unit) {
                  final isSel = unit == selected;
                  return ListTile(
                    title: Text(unit, style: TextStyle(
                        fontSize: 14,
                        color: isSel ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.normal)),
                    trailing: isSel ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
                    onTap: () => Navigator.pop(context, unit),
                  );
                }),
              ],
            )).toList(),
          ),
        ),
      ]),
    );
  }
}

// ══ AUXILIARES ════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});
  final String title; final IconData icon; final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 32, height: 32,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.primary, size: 17)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _SubLabel extends StatelessWidget {
  const _SubLabel({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]);
}

class _EmptyMaterials extends StatelessWidget {
  const _EmptyMaterials();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Column(children: [
          Icon(Icons.inbox_outlined, size: 40, color: AppColors.textHint),
          SizedBox(height: 8),
          Text('Aún no hay materiales', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Agrega el primero con el formulario de arriba', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        ])),
      );
}