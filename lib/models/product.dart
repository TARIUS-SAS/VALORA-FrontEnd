class Product {
  final String? id;
  final String  name;
  final String? description;
  final String  userId;

  // Costos
  final double? materialsCost;   // suma de materiales (calculado)
  final double? laborCost;       // mano de obra (ingresado)
  final double? totalCost;       // materialsCost + laborCost (calculado)

  // Ganancia y precio
  final double? profitPct;       // % ganancia deseada (ingresado)
  final double? suggestedPrice;  // precio sugerido calculado (NO se ingresa)

  final DateTime? createdAt;

  const Product({
    this.id,
    required this.name,
    this.description,
    required this.userId,
    this.materialsCost,
    this.laborCost,
    this.totalCost,
    this.profitPct,
    this.suggestedPrice,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id:             json['id'] as String?,
        name:           json['name'] as String,
        description:    json['description'] as String?,
        userId:         json['user_id'] as String,
        materialsCost:  (json['materials_cost'] as num?)?.toDouble(),
        laborCost:      (json['labor_cost'] as num?)?.toDouble(),
        totalCost:      (json['total_cost'] as num?)?.toDouble(),
        profitPct:      (json['profit_pct'] as num?)?.toDouble(),
        suggestedPrice: (json['suggested_price'] as num?)?.toDouble(),
        createdAt:      json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name':           name,
        'description':    description,
        'user_id':        userId,
        if (laborCost       != null) 'labor_cost':      laborCost,
        if (profitPct       != null) 'profit_pct':      profitPct,
        if (suggestedPrice  != null) 'suggested_price': suggestedPrice,
      };

  // Ganancia en dinero
  double get profitAmount =>
      (suggestedPrice ?? 0) - (totalCost ?? 0);

  // Margen real (puede diferir del deseado por redondeo)
  double get marginPercent =>
      (suggestedPrice ?? 0) > 0
          ? (profitAmount / (suggestedPrice ?? 1)) * 100
          : 0;
}