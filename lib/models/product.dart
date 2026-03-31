class Product {
  final String? id;
  final String  name;
  final String? description;
  final String  userId;

  // Costos
  final double? materialsCost;
  final double? laborHours;     // horas trabajadas (nuevo — para mostrar HH:MM al editar)
  final double? laborCost;      // mano de obra calculada (horas × salario)
  final double? totalCost;      // materialsCost + laborCost

  // Ganancia y precio
  final double? profitPct;
  final double? suggestedPrice;

  final DateTime? createdAt;

  const Product({
    this.id,
    required this.name,
    this.description,
    required this.userId,
    this.materialsCost,
    this.laborHours,
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
        laborHours:     (json['labor_hours']    as num?)?.toDouble(),
        laborCost:      (json['labor_cost']     as num?)?.toDouble(),
        totalCost:      (json['total_cost']     as num?)?.toDouble(),
        profitPct:      (json['profit_pct']     as num?)?.toDouble(),
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
        if (laborHours    != null) 'labor_hours':    laborHours,
        if (laborCost     != null) 'labor_cost':     laborCost,
        if (profitPct     != null) 'profit_pct':     profitPct,
        if (suggestedPrice != null) 'suggested_price': suggestedPrice,
      };

  double get profitAmount =>
      (suggestedPrice ?? 0) - (totalCost ?? 0);

  double get marginPercent =>
      (suggestedPrice ?? 0) > 0
          ? (profitAmount / (suggestedPrice ?? 1)) * 100
          : 0;

  /// Convierte laborHours a formato HH:MM para mostrar en el campo
  String get laborHoursFormatted {
    final h = laborHours ?? 0;
    final hours   = h.floor();
    final minutes = ((h - hours) * 60).round();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}