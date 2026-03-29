class ProductVersion {
  final String? id;
  final String productId;
  final int versionNumber;
  final double sellingPrice;
  final double totalCost;
  final List<Map<String, dynamic>> materialsSnapshot;
  final DateTime? createdAt;

  const ProductVersion({
    this.id,
    required this.productId,
    required this.versionNumber,
    required this.sellingPrice,
    required this.totalCost,
    required this.materialsSnapshot,
    this.createdAt,
  });

  factory ProductVersion.fromJson(Map<String, dynamic> json) => ProductVersion(
        id:            json['id'] as String?,
        productId:     json['product_id'] as String,
        versionNumber: json['version_number'] as int,
        sellingPrice:  (json['selling_price'] as num).toDouble(),
        totalCost:     (json['total_cost'] as num).toDouble(),
        materialsSnapshot: List<Map<String, dynamic>>.from(
            json['materials_snapshot'] as List),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'product_id':         productId,
        'version_number':     versionNumber,
        'selling_price':      sellingPrice,
        'total_cost':         totalCost,
        'materials_snapshot': materialsSnapshot,
      };
}
