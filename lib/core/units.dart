// ═══════════════════════════════════════════════════════════════
//  UNIDADES DE MEDIDA
//  Sistema métrico, imperial e incontables para manualidades
// ═══════════════════════════════════════════════════════════════

class UnitGroup {
  final String       label;
  final List<String> units;
  const UnitGroup({required this.label, required this.units});
}

// ── Incontables — sin medida exacta ──────────────────────────
const List<String> kUncountableUnits = [
  'Unidad',    // una goma, un botón, un palo de madera
  'Gota',      // colorante, esencia, aceite esencial
  'Pizca',     // polvo decorativo, purpurina, sal
  'Al gusto',  // no afecta el costo (valor $0)
];

// ── Sistema MÉTRICO ───────────────────────────────────────────
const List<UnitGroup> kMetricGroups = [
  UnitGroup(label: 'Peso',     units: ['kg', 'g', 'mg']),
  UnitGroup(label: 'Volumen',  units: ['lt', 'ml', 'cl']),
  UnitGroup(label: 'Longitud', units: ['m', 'cm', 'mm']),
];

// ── Sistema IMPERIAL ──────────────────────────────────────────
const List<UnitGroup> kImperialGroups = [
  UnitGroup(label: 'Peso',     units: ['lb', 'oz']),
  UnitGroup(label: 'Volumen',  units: ['gal', 'qt', 'pt', 'fl oz']),
  UnitGroup(label: 'Longitud', units: ['yd', 'ft', 'in']),
];

// ── Helpers ───────────────────────────────────────────────────

/// Todas las unidades en una lista plana (para dropdowns simples)
List<String> allUnitsForSystem(String measureSystem) {
  final groups = measureSystem == 'imperial' ? kImperialGroups : kMetricGroups;
  return [
    ...kUncountableUnits,
    ...groups.expand((g) => g.units),
  ];
}

/// Unidades agrupadas con secciones (para pickers con cabeceras)
List<UnitGroup> groupedUnitsForSystem(String measureSystem) {
  final measurable = measureSystem == 'imperial' ? kImperialGroups : kMetricGroups;
  return [
    const UnitGroup(label: 'General', units: kUncountableUnits),
    ...measurable,
  ];
}

// ── Conversiones automáticas ──────────────────────────────────
// Si compra y uso tienen la misma categoría (ambos peso, volumen…)
// se convierte automáticamente. Si no, se usa proporción 1:1.

const _massToGrams = <String, double>{
  'kg': 1000, 'g': 1, 'mg': 0.001,
  'lb': 453.592, 'oz': 28.3495,
};

const _volToMl = <String, double>{
  'lt': 1000, 'ml': 1, 'cl': 10,
  'gal': 3785.41, 'qt': 946.353, 'pt': 473.176, 'fl oz': 29.5735,
};

const _lenToCm = <String, double>{
  'm': 100, 'cm': 1, 'mm': 0.1,
  'yd': 91.44, 'ft': 30.48, 'in': 2.54,
};

/// Factor de conversión de [from] a [to].
/// Retorna 1.0 si no hay conversión conocida (incontables o distintas categorías).
double conversionFactor({required String from, required String to}) {
  final f = from.toLowerCase().trim();
  final t = to.toLowerCase().trim();
  if (f == t) return 1.0;

  if (_massToGrams.containsKey(f) && _massToGrams.containsKey(t))
    return _massToGrams[f]! / _massToGrams[t]!;
  if (_volToMl.containsKey(f) && _volToMl.containsKey(t))
    return _volToMl[f]! / _volToMl[t]!;
  if (_lenToCm.containsKey(f) && _lenToCm.containsKey(t))
    return _lenToCm[f]! / _lenToCm[t]!;

  return 1.0;
}

/// Indica si una unidad no tiene medida exacta (no afecta cálculos de cantidad)
bool isUncountable(String unit) =>
    unit == 'Al gusto' || unit == 'Gota' || unit == 'Pizca';