import '../core/units.dart';

class MaterialItem {
  final String? id;
  final String  productId;
  final String  name;

  // Lo que compró
  final double purchaseQty;
  final String purchaseUnit;
  final double purchaseCost;

  // Lo que usa en este producto
  final double usedQty;
  final String usedUnit;

  const MaterialItem({
    this.id,
    required this.productId,
    required this.name,
    required this.purchaseQty,
    required this.purchaseUnit,
    required this.purchaseCost,
    required this.usedQty,
    required this.usedUnit,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
        id:           json['id'] as String?,
        productId:    json['product_id'] as String,
        name:         json['name'] as String,
        purchaseQty:  (json['purchase_qty']  as num).toDouble(),
        purchaseUnit: json['purchase_unit']  as String,
        purchaseCost: (json['purchase_cost'] as num).toDouble(),
        usedQty:      (json['used_qty']      as num).toDouble(),
        usedUnit:     json['used_unit']      as String,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'product_id':    productId,
        'name':          name,
        'purchase_qty':  purchaseQty,
        'purchase_unit': purchaseUnit,
        'purchase_cost': purchaseCost,
        'used_qty':      usedQty,
        'used_unit':     usedUnit,
      };

  // ── Cálculos ──────────────────────────────────────────────────

  /// Si la unidad es incontable (al gusto / a discreción) el costo es 0.
  bool get isUncountableMaterial =>
      isUncountable(purchaseUnit) || isUncountable(usedUnit);

  /// usedQty convertida a la misma unidad que purchaseUnit para la regla de 3.
  double get _usedQtyNormalized {
    if (purchaseUnit == usedUnit) return usedQty;
    final factor = conversionFactor(from: usedUnit, to: purchaseUnit);
    return usedQty * factor;
  }

  /// Costo real de lo que se usa: purchaseCost × (usedNorm / purchaseQty).
  /// Si es incontable → $0.
  double get actualCost {
    if (isUncountableMaterial) return 0;
    if (purchaseQty <= 0) return 0;
    return purchaseCost * (_usedQtyNormalized / purchaseQty);
  }

  /// Cuántas unidades del producto puedo hacer con lo que compré.
  double get batchCount {
    if (isUncountableMaterial) return double.infinity;
    if (_usedQtyNormalized <= 0) return 0;
    return purchaseQty / _usedQtyNormalized;
  }

  /// Porcentaje del total comprado que se va a usar (0-100).
  double get usagePercent {
    if (isUncountableMaterial) return 0;
    if (purchaseQty <= 0) return 0;
    return (_usedQtyNormalized / purchaseQty * 100).clamp(0, 100);
  }

  /// Texto resumen en lenguaje simple.
  String get summaryText {
    if (isUncountableMaterial) {
      return 'Uso: $usedQty $usedUnit  (no afecta el costo)';
    }
    return 'Usas $usedQty $usedUnit de $purchaseQty $purchaseUnit';
  }
}