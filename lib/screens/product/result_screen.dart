import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/material_item.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.product});
  final Product product;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _repo = ProductRepository();
  List<MaterialItem> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.getMaterials(widget.product.id!);
      if (mounted) setState(() => _materials = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p             = widget.product;
    final materialsCost = p.materialsCost ?? 0;
    final laborCost     = p.laborCost     ?? 0;
    final totalCost     = p.totalCost     ?? 0;
    final profitPct     = p.profitPct     ?? 0;
    final suggested     = p.suggestedPrice ?? 0;
    final profit        = suggested - totalCost;
    final isOk          = profit >= 0 && suggested > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado del costeo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  // ══ HERO CARD ══════════════════════════════════
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOk
                            ? [AppColors.primary, const Color(0xFF6B6BE8)]
                            : [AppColors.error,   const Color(0xFFFF7A6B)],
                        begin: Alignment.topLeft,
                        end:   Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: (isOk ? AppColors.primary : AppColors.error)
                              .withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                suggested == 0
                                    ? Icons.hourglass_empty_outlined
                                    : isOk
                                        ? Icons.check_circle_outline
                                        : Icons.warning_amber_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                suggested == 0
                                    ? 'Sin datos de costeo'
                                    : isOk
                                        ? 'Producto rentable'
                                        : 'Revisar precios',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Nombre
                        Text(p.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                        if (p.description != null &&
                            p.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(p.description!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ),

                        const SizedBox(height: 22),

                        // Stats principales
                        Row(
                          children: [
                            _HeroStat(
                                label: 'Costo total',
                                value:
                                    '\$${totalCost.toStringAsFixed(2)}'),
                            _HeroStat(
                                label: 'Precio venta',
                                value:
                                    '\$${suggested.toStringAsFixed(2)}'),
                            _HeroStat(
                                label: 'Ganancia',
                                value:
                                    '\$${profit.toStringAsFixed(2)}',
                                highlight: true),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Barra de margen
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Margen de ganancia',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.7),
                                        fontSize: 12)),
                                Text('${profitPct.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (profitPct.clamp(0, 100) / 100),
                                backgroundColor: Colors.white24,
                                valueColor:
                                    const AlwaysStoppedAnimation(Colors.white),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ══ RESUMEN DEL COSTEO ═════════════════════════
                  _ResultCard(
                    title: 'Resumen del costeo',
                    icon: Icons.calculate_outlined,
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.category_outlined,
                          iconColor: AppColors.primary,
                          label: 'Costo de materiales',
                          value:
                              '\$${materialsCost.toStringAsFixed(2)}',
                          valueColor: AppColors.textPrimary,
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.engineering_outlined,
                          iconColor: const Color(0xFF6B6BE8),
                          label: 'Mano de obra',
                          value: '\$${laborCost.toStringAsFixed(2)}',
                          valueColor: AppColors.textPrimary,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppColors.divider),
                        ),
                        _DetailRow(
                          icon: Icons.receipt_long_outlined,
                          iconColor: AppColors.primary,
                          label: 'Total costo de producción',
                          value: '\$${totalCost.toStringAsFixed(2)}',
                          valueColor: AppColors.primary,
                          bold: true,
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.percent,
                          iconColor: AppColors.accentDark,
                          label:
                              'Ganancia deseada ${profitPct.toStringAsFixed(0)}%',
                          value: '+\$${profit.toStringAsFixed(2)}',
                          valueColor: AppColors.accentDark,
                          bold: true,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                              color: AppColors.divider, thickness: 1.5),
                        ),
                        _DetailRow(
                          icon: Icons.sell_outlined,
                          iconColor: AppColors.primary,
                          label: 'Precio sugerido de venta',
                          value: '\$${suggested.toStringAsFixed(2)}',
                          valueColor: AppColors.primary,
                          bold: true,
                          largeValue: true,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 13, color: AppColors.textHint),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Fórmula: \$${totalCost.toStringAsFixed(2)} ÷ (1 − ${profitPct.toStringAsFixed(0)}%) = \$${suggested.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ══ DESGLOSE DE MATERIALES ══════════════════════
                  _ResultCard(
                    title: 'Desglose de materiales',
                    icon: Icons.category_outlined,
                    child: _materials.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 36, color: AppColors.textHint),
                                  SizedBox(height: 8),
                                  Text('Sin materiales registrados',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              // Encabezado columnas
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: const [
                                    Expanded(
                                        child: Text('Material',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppColors.textSecondary))),
                                    Text('Comprado',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                    SizedBox(width: 12),
                                    Text('Usado',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                    SizedBox(width: 12),
                                    Text('Costo',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const Divider(
                                  color: AppColors.divider, height: 1),
                              const SizedBox(height: 8),

                              // Filas de materiales
                              ..._materials.map((m) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 7),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Nombre
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(m.name,
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .textPrimary)),
                                                  Text(
                                                    '${m.usagePercent.toStringAsFixed(0)}% del paquete',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: m.usagePercent >
                                                                100
                                                            ? AppColors.error
                                                            : AppColors
                                                                .textHint),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Comprado
                                            Text(
                                              '${m.purchaseQty} ${m.purchaseUnit}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondary),
                                            ),
                                            const SizedBox(width: 12),
                                            // Usado
                                            Text(
                                              '${m.usedQty} ${m.usedUnit}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondary),
                                            ),
                                            const SizedBox(width: 12),
                                            // Costo real
                                            Text(
                                              '\$${m.actualCost.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        // Mini barra de uso
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          child: LinearProgressIndicator(
                                            value: (m.usagePercent / 100)
                                                .clamp(0.0, 1.0),
                                            backgroundColor: AppColors.divider,
                                            valueColor:
                                                AlwaysStoppedAnimation(
                                              m.usagePercent > 100
                                                  ? AppColors.error
                                                  : AppColors.accent,
                                            ),
                                            minHeight: 4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),

                              const Divider(
                                  height: 20, color: AppColors.divider),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total materiales',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  Text(
                                    '\$${materialsCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary),
                                  ),
                                ],
                              ),

                              // Cuántos productos puede hacer
                              if (_materials.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _BatchInfo(materials: _materials),
                              ],
                            ],
                          ),
                  ),

                  const SizedBox(height: 16),

                  // ══ ANÁLISIS DE RENTABILIDAD ════════════════════
                  _ResultCard(
                    title: 'Análisis de rentabilidad',
                    icon: Icons.trending_up,
                    child: Column(
                      children: [
                        // Insight principal
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isOk
                                ? AppColors.accent.withOpacity(0.08)
                                : AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOk
                                  ? AppColors.accent.withOpacity(0.3)
                                  : AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOk
                                    ? Icons.lightbulb_outline
                                    : Icons.warning_amber_outlined,
                                color: isOk
                                    ? AppColors.accentDark
                                    : AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isOk
                                      ? 'Por cada \$${suggested.toStringAsFixed(2)} que cobras, '
                                          'tu ganancia es \$${profit.toStringAsFixed(2)} '
                                          '(${profitPct.toStringAsFixed(0)}% del precio de venta).'
                                      : suggested == 0
                                          ? 'Agrega materiales y ajusta el % de ganancia para calcular el precio sugerido.'
                                          : 'El costo supera el precio sugerido. Revisa tus materiales o ajusta el porcentaje.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isOk
                                        ? AppColors.accentDark
                                        : AppColors.error,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tabla por unidad
                        _CompareRow('Por cada unidad vendida a',
                            '\$${suggested.toStringAsFixed(2)}'),
                        _CompareRow(
                            'Recuperas en costos',
                            '-\$${totalCost.toStringAsFixed(2)}',
                            negative: true),
                        _CompareRow(
                            'Tu ganancia neta',
                            '\$${profit.toStringAsFixed(2)}',
                            accent: true),

                        const SizedBox(height: 8),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 8),

                        // Proyección x10
                        const Text('Proyección (10 unidades)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        _CompareRow('Ingresos',
                            '\$${(suggested * 10).toStringAsFixed(2)}'),
                        _CompareRow(
                            'Costos',
                            '-\$${(totalCost * 10).toStringAsFixed(2)}',
                            negative: true),
                        _CompareRow(
                            'Ganancia total',
                            '\$${(profit * 10).toStringAsFixed(2)}',
                            accent: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón volver
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver al producto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
    );
  }
}

// ══ WIDGET: cuántos productos puede hacer ════════════════════════

class _BatchInfo extends StatelessWidget {
  const _BatchInfo({required this.materials});
  final List<MaterialItem> materials;

  @override
  Widget build(BuildContext context) {
    // El material más limitante es el que tiene el menor batchCount
    final limiting = materials.reduce(
        (a, b) => a.batchCount < b.batchCount ? a : b);
    final count = limiting.batchCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.repeat, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Con tus compras actuales puedes hacer',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${count.toStringAsFixed(1)} unidades ',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary),
                      ),
                      TextSpan(
                        text: '(limitado por: ${limiting.name})',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
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

// ══ WIDGETS LOCALES ═══════════════════════════════════════════════

class _HeroStat extends StatelessWidget {
  const _HeroStat(
      {required this.label, required this.value, this.highlight = false});
  final String label, value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: highlight ? 19 : 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(
      {required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 17),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold       = false,
    this.largeValue = false,
  });
  final IconData icon;
  final Color    iconColor, valueColor;
  final String   label, value;
  final bool     bold, largeValue;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight:
                        bold ? FontWeight.w600 : FontWeight.normal)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: largeValue ? 17 : bold ? 14 : 13,
                  color: valueColor,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      );
}

class _CompareRow extends StatelessWidget {
  const _CompareRow(this.label, this.value,
      {this.negative = false, this.accent = false});
  final String label, value;
  final bool   negative, accent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        accent ? FontWeight.w700 : FontWeight.w600,
                    color: negative
                        ? AppColors.error
                        : accent
                            ? AppColors.accent
                            : AppColors.textPrimary)),
          ],
        ),
      );
}