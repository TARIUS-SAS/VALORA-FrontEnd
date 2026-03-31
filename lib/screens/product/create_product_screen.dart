import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/material_item.dart';
import '../../models/product.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/material_card.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key, this.existing});
  final Product? existing;

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _laborCtrl= TextEditingController(text: '00:00');

  // Formulario de material
  final _matFormKey       = GlobalKey<FormState>();
  final _matNameCtrl      = TextEditingController();
  final _matPurchQtyCtrl  = TextEditingController();
  final _matPurchCostCtrl = TextEditingController();
  final _matUsedQtyCtrl   = TextEditingController();
  String _matPurchUnit    = 'kg';
  String _matUsedUnit     = 'g';
  bool   _hasLeftover     = false; // ¿Sobró material?

  final _repo     = ProductRepository();
  final _auth     = AuthRepository();

  bool _savingInfo     = false;
  bool _savingMaterial = false;
  bool _isLoadingMats  = false;

  Product?           _savedProduct;
  List<MaterialItem> _materials = [];
  double             _profitPct = 30.0;

  bool get _isEdit => widget.existing != null;

  List<String> get _allUnits => _auth.allUnits;

  // ── Cálculos ──────────────────────────────────────────────────
  double get _materialsCost =>
      _materials.fold(0.0, (s, m) => s + m.actualCost);

  /// Parsea HH:MM y retorna horas decimales
  double get _laborHours {
    final text = _laborCtrl.text.trim();
    if (text.contains(':')) {
      final parts = text.split(':');
      final h = double.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (double.tryParse(parts[1]) ?? 0) : 0;
      return h + m / 60;
    }
    return double.tryParse(text) ?? 0;
  }

  double get _laborCost => _laborHours * _auth.minWagePerHour;

  double get _totalCost => _materialsCost + _laborCost;

  double get _suggestedPrice => _profitPct >= 100
      ? _totalCost * 2
      : _totalCost > 0
          ? _totalCost / (1 - _profitPct / 100)
          : 0;

  double get _profitAmount => _suggestedPrice - _totalCost;

  // Preview en tiempo real
  MaterialItem? get _previewItem {
    final name  = _matNameCtrl.text.trim();
    final pQty  = double.tryParse(_matPurchQtyCtrl.text.replaceAll(',', '.'));
    final pCost = double.tryParse(_matPurchCostCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || pQty == null || pCost == null) return null;
    if (pQty <= 0) return null;

    // Si no sobró: usa toda la cantidad comprada
    // Si sobró: usa lo que el usuario indicó en el campo
    double usedQty;
    String usedUnit;
    if (!_hasLeftover) {
      usedQty  = pQty;
      usedUnit = _matPurchUnit;
    } else {
      final uQty = double.tryParse(_matUsedQtyCtrl.text.replaceAll(',', '.'));
      if (uQty == null || uQty <= 0) return null;
      usedQty  = uQty;
      usedUnit = _matUsedUnit;
    }

    return MaterialItem(
      productId:    _savedProduct?.id ?? '',
      name:         name,
      purchaseQty:  pQty,
      purchaseUnit: _matPurchUnit,
      purchaseCost: pCost,
      usedQty:      usedQty,
      usedUnit:     usedUnit,
    );
  }

  @override
  void initState() {
    super.initState();
    _matPurchUnit = _auth.isMetric ? 'kg' : 'lb';
    _matUsedUnit  = _auth.isMetric ? 'g'  : 'oz';

    if (_isEdit) {
      _nameCtrl.text   = widget.existing!.name;
      _descCtrl.text   = widget.existing!.description ?? '';
      _laborCtrl.text  = widget.existing!.laborHoursFormatted;
      _profitPct       = widget.existing!.profitPct ?? 30.0;
      _savedProduct    = widget.existing;
      _loadMaterials();
    }

    _laborCtrl.addListener(() => setState(() {}));
    for (final c in [_matNameCtrl, _matPurchQtyCtrl, _matPurchCostCtrl, _matUsedQtyCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _laborCtrl.dispose();
    _matNameCtrl.dispose(); _matPurchQtyCtrl.dispose();
    _matPurchCostCtrl.dispose(); _matUsedQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveInfo() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _savingInfo = true);
    try {
      final p = Product(
        id:          _savedProduct?.id,
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        laborHours:  _laborHours,
        laborCost:   _laborCost,
        profitPct:   _profitPct,
        userId:      _auth.currentUser!.id,
      );
      _savedProduct = _isEdit && _savedProduct?.id != null
          ? await _repo.update(p)
          : await _repo.create(p);
      await _loadMaterials();
      _showOk(_isEdit ? 'Producto actualizado' : '¡Guardado! Ahora agrega materiales');
      setState(() {});
    } catch (e) {
      _showErr('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _savingInfo = false);
    }
  }

  Future<void> _loadMaterials() async {
    if (_savedProduct?.id == null) return;
    setState(() => _isLoadingMats = true);
    try {
      final list = await _repo.getMaterials(_savedProduct!.id!);
      if (mounted) setState(() => _materials = list);
    } finally {
      if (mounted) setState(() => _isLoadingMats = false);
    }
  }

  Future<void> _addMaterial() async {
    if (_savedProduct == null) { _showErr('Guarda primero el nombre'); return; }
    if (!_matFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _savingMaterial = true);
    try {
      final pQty = double.parse(_matPurchQtyCtrl.text.replaceAll(',', '.'));

      // Si no sobró: usedQty = purchaseQty (costo total = precio pagado)
      // Si sobró: usedQty = lo que ingresó el usuario
      final usedQty  = _hasLeftover
          ? double.parse(_matUsedQtyCtrl.text.replaceAll(',', '.'))
          : pQty;
      final usedUnit = _hasLeftover ? _matUsedUnit : _matPurchUnit;

      await _repo.addMaterial(MaterialItem(
        productId:    _savedProduct!.id!,
        name:         _matNameCtrl.text.trim(),
        purchaseQty:  pQty,
        purchaseUnit: _matPurchUnit,
        purchaseCost: double.parse(_matPurchCostCtrl.text.replaceAll(',', '.')),
        usedQty:      usedQty,
        usedUnit:     usedUnit,
      ));
      _matNameCtrl.clear(); _matPurchQtyCtrl.clear();
      _matPurchCostCtrl.clear(); _matUsedQtyCtrl.clear();
      await _loadMaterials();
      await _syncCosts();
      _showOk('Material agregado');
    } catch (_) {
      _showErr('Error al agregar material');
    } finally {
      if (mounted) setState(() => _savingMaterial = false);
    }
  }

  Future<void> _deleteMaterial(MaterialItem item) async {
    await _repo.deleteMaterial(item.id!);
    await _loadMaterials();
    await _syncCosts();
  }

  Future<void> _syncCosts() async {
    if (_savedProduct?.id == null) return;
    await _repo.updateCosts(
      productId:      _savedProduct!.id!,
      materialsCost:  _materialsCost,
      laborHours:     _laborHours,
      laborCost:      _laborCost,
      profitPct:      _profitPct,
      suggestedPrice: _suggestedPrice,
    );
  }

  void _showOk(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: AppColors.accentDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));

  void _showErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));

  @override
  Widget build(BuildContext context) {
    final preview = _previewItem;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar producto' : 'Nuevo producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ══ 1. INFO BÁSICA ════════════════════════════════════
            _SectionCard(
              title: '1. Información del producto',
              icon: Icons.inventory_2_outlined,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto *',
                        prefixIcon: Icon(Icons.label_outline,
                            size: 18, color: AppColors.textHint),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El nombre es obligatorio' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        prefixIcon: Icon(Icons.notes_outlined,
                            size: 18, color: AppColors.textHint),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: _savedProduct == null
                          ? 'Guardar y continuar'
                          : 'Actualizar',
                      onPressed: _savingInfo ? null : _saveInfo,
                      isLoading: _savingInfo,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ══ 2. MATERIALES ══════════════════════════════════════
            _SectionCard(
              title: '2. Materiales',
              icon: Icons.category_outlined,
              locked: _savedProduct == null,
              lockedMsg: 'Guarda el nombre del producto primero',
              child: Form(
                key: _matFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    TextFormField(
                      controller: _matNameCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: '¿Qué ingrediente o material es?',
                        hintText: 'Ej: Harina, Aceite, Tela…',
                        prefixIcon: Icon(Icons.add_box_outlined,
                            size: 18, color: AppColors.textHint),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    const SizedBox(height: 12),
                    _SubLabel(icon: Icons.shopping_bag_outlined, text: '¿Cuánto compraste y cuánto pagaste?'),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _matPurchQtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad comprada',
                              hintText: 'Ej: 1',
                              prefixIcon: Icon(Icons.numbers,
                                  size: 18, color: AppColors.textHint),
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
                        Expanded(
                          flex: 2,
                          child: _UnitDropdown(
                            label: 'Unidad de compra',
                            value: _matPurchUnit,
                            units: _allUnits,
                            onChanged: (v) => setState(() => _matPurchUnit = v),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _matPurchCostCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '¿Cuánto pagaste por ese paquete? (\$)',
                        hintText: 'Ej: 5.00',
                        prefixIcon: Icon(Icons.attach_money,
                            size: 18, color: AppColors.textHint),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido';
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    const SizedBox(height: 12),

                    // Switch: ¿Sobró material?
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _hasLeftover
                            ? AppColors.primary.withOpacity(0.06)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasLeftover ? AppColors.primary : AppColors.border,
                          width: _hasLeftover ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('¿Sobró material?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _hasLeftover
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                )),
                            Text(
                              _hasLeftover
                                  ? 'Indica cuánto usaste en este producto'
                                  : 'Usé todo lo que compré en este producto',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        )),
                        Switch(
                          value: _hasLeftover,
                          onChanged: (v) => setState(() {
                            _hasLeftover = v;
                            if (!v) _matUsedQtyCtrl.clear();
                          }),
                          activeColor: AppColors.primary,
                        ),
                      ]),
                    ),

                    // Campo de cantidad usada — solo si sobró
                    if (_hasLeftover) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _matUsedQtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _addMaterial(),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad usada',
                              hintText: 'Ej: 500',
                              prefixIcon: Icon(Icons.colorize_outlined,
                                  size: 18, color: AppColors.textHint),
                            ),
                            validator: (v) {
                              if (!_hasLeftover) return null;
                              if (v == null || v.isEmpty) return 'Requerido';
                              final d = double.tryParse(v.replaceAll(',', '.'));
                              if (d == null || d <= 0) return 'Mayor a 0';
                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _UnitDropdown(
                            label: 'Unidad de uso',
                            value: _matUsedUnit,
                            units: _allUnits,
                            onChanged: (v) => setState(() => _matUsedUnit = v),
                          ),
                        ),
                      ]),
                    ],

                    // Preview cálculo en tiempo real
                    if (preview != null) ...[
                      const SizedBox(height: 12),
                      _CalcPreview(item: preview),
                    ],

                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Agregar material',
                      onPressed: _savingMaterial ? null : _addMaterial,
                      isLoading: _savingMaterial,
                    ),

                    // Lista de materiales agregados
                    if (_isLoadingMats)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      )
                    else if (_materials.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 8),
                      ..._materials.map((m) => MaterialCard(
                            item: m,
                            onDelete: () => _deleteMaterial(m),
                          )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal materiales',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('\$${_materialsCost.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ══ 3. MANO DE OBRA ═══════════════════════════════════
            _SectionCard(
              title: '3. Mano de obra',
              icon: Icons.engineering_outlined,
              locked: _savedProduct == null,
              lockedMsg: 'Guarda el nombre del producto primero',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo HH:MM
                  TextFormField(
                    controller: _laborCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Tiempo invertido (HH:MM)',
                      hintText: '01:30',
                      helperText: 'Ejemplo: 01:30 = 1 hora 30 minutos',
                      prefixIcon: Icon(Icons.access_time_outlined,
                          size: 18, color: AppColors.textHint),
                    ),
                    onChanged: (_) { setState(() {}); _syncCosts(); },
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
                      const Icon(Icons.calculate_outlined,
                          color: Color(0xFF6B6BE8), size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_laborHours.toStringAsFixed(2)} horas  ×  \$${_auth.minWagePerHour.toStringAsFixed(2)}/hora',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          const Text('Costo de mano de obra:',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      )),
                      Text('\$${_laborCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6B6BE8))),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ══ 4. % GANANCIA ══════════════════════════════════════
            _SectionCard(
              title: '4. % Ganancia deseada',
              icon: Icons.percent,
              locked: _savedProduct == null,
              lockedMsg: 'Guarda el nombre del producto primero',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _profitPct,
                          min: 0, max: 200, divisions: 200,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.divider,
                          onChanged: (v) {
                            setState(() => _profitPct = v);
                            _syncCosts();
                          },
                        ),
                      ),
                      Container(
                        width: 62,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${_profitPct.toStringAsFixed(0)}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [10, 20, 30, 40, 50, 100].map((pct) {
                      final active = _profitPct.round() == pct;
                      return GestureDetector(
                        onTap: () { setState(() => _profitPct = pct.toDouble()); _syncCosts(); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: active ? AppColors.primary : AppColors.border),
                          ),
                          child: Text('$pct%',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: active ? Colors.white : AppColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ══ RESUMEN ════════════════════════════════════════════
            _CostSummary(
              materialsCost:  _materialsCost,
              laborCost:      _laborCost,
              totalCost:      _totalCost,
              profitPct:      _profitPct,
              profitAmount:   _profitAmount,
              suggestedPrice: _suggestedPrice,
              isReady:        _savedProduct != null,
            ),

            const SizedBox(height: 20),

            if (_savedProduct != null)
              CustomButton(
                label: 'Guardar costeo completo',
                onPressed: () async { await _syncCosts(); _showOk('Costeo guardado'); },
                isAccent: true,
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ══ PREVIEW DEL CÁLCULO ══════════════════════════════════════════

class _CalcPreview extends StatelessWidget {
  const _CalcPreview({required this.item});
  final MaterialItem item;

  @override
  Widget build(BuildContext context) {
    final pct   = item.usagePercent;
    final isOver= pct > 100;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOver ? AppColors.error.withOpacity(0.06) : AppColors.accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOver ? AppColors.error.withOpacity(0.3) : AppColors.accent.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOver ? Icons.warning_amber_outlined : Icons.calculate_outlined,
                size: 16,
                color: isOver ? AppColors.error : AppColors.accentDark,
              ),
              const SizedBox(width: 8),
              Text(
                isOver ? 'Usas más de lo que compraste' : 'Vista previa del cálculo',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isOver ? AppColors.error : AppColors.accentDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PRow('Compraste', '${item.purchaseQty} ${item.purchaseUnit}  →  \$${item.purchaseCost.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          _PRow('Vas a usar', '${item.usedQty} ${item.usedUnit}  (${pct.toStringAsFixed(0)}% del total)'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: AppColors.divider, height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Eso te cuesta',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text('\$${item.actualCost.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.repeat, size: 13, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Con lo que compraste puedes hacer ${item.batchCount.toStringAsFixed(1)} unidades de este producto',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PRow extends StatelessWidget {
  const _PRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 76, child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      );
}

// ══ RESUMEN DE COSTEO ═════════════════════════════════════════════

class _CostSummary extends StatelessWidget {
  const _CostSummary({
    required this.materialsCost, required this.laborCost,
    required this.totalCost, required this.profitPct,
    required this.profitAmount, required this.suggestedPrice,
    required this.isReady,
  });
  final double materialsCost, laborCost, totalCost, profitPct, profitAmount, suggestedPrice;
  final bool isReady;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: isReady ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6B6BE8)]),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.calculate_outlined, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Resumen del costeo',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 18),
              _Row(icon: Icons.category_outlined, iconColor: AppColors.primary, label: 'Costo de materiales', value: '\$${materialsCost.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _Row(icon: Icons.engineering_outlined, iconColor: const Color(0xFF6B6BE8), label: 'Mano de obra', value: '\$${laborCost.toStringAsFixed(2)}'),
              const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(color: AppColors.divider)),
              _Row(icon: Icons.receipt_long_outlined, iconColor: AppColors.primary, label: 'Total costo de producción', value: '\$${totalCost.toStringAsFixed(2)}', bold: true, valueColor: AppColors.primary),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.percent, size: 16, color: AppColors.accentDark),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Ganancia deseada  ${profitPct.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentDark))),
                    Text('+\$${profitAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentDark)),
                  ],
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(color: AppColors.divider, thickness: 1.5)),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6B6BE8)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sell_outlined, color: Colors.white70, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Precio sugerido de venta', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Calculado automáticamente', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ])),
                    Text('\$${suggestedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 13, color: AppColors.textHint),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Fórmula: \$${totalCost.toStringAsFixed(2)} ÷ (1 − ${profitPct.toStringAsFixed(0)}%) = \$${suggestedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.iconColor, required this.label, required this.value, this.bold = false, this.valueColor = AppColors.textPrimary});
  final IconData icon; final Color iconColor, valueColor;
  final String label, value; final bool bold;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 30, height: 30,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
              child: Icon(icon, size: 15, color: iconColor)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: bold ? FontWeight.w600 : FontWeight.normal))),
          Text(value, style: TextStyle(fontSize: bold ? 15 : 13, color: valueColor, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      );
}

// ══ SECCIÓN CARD ══════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child, this.locked = false, this.lockedMsg});
  final String title; final IconData icon; final Widget child; final bool locked; final String? lockedMsg;
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: locked ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 32, height: 32,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(icon, color: AppColors.primary, size: 17)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                  if (locked) const Icon(Icons.lock_outline, size: 15, color: AppColors.textHint),
                ],
              ),
              if (locked && lockedMsg != null) ...[
                const SizedBox(height: 8),
                Text(lockedMsg!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ] else ...[
                const SizedBox(height: 14),
                child,
              ],
            ],
          ),
        ),
      );
}

class _SubLabel extends StatelessWidget {
  const _SubLabel({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ],
      );
}

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({required this.label, required this.value, required this.units, required this.onChanged});
  final String label, value; final List<String> units; final void Function(String) onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: units.contains(value) ? value : units.first,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 1.2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.8)),
        ),
        isExpanded: true,
        items: units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      );
}