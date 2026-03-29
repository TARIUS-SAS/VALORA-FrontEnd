// ═══════════════════════════════════════════════════════════════
//  UNIDADES DE MEDIDA — métricas, imperiales e incontables
//  Las "incontables" son para materiales que no se pueden medir
//  con precisión: goma, barniz, purpurina, pintura, etc.
// ═══════════════════════════════════════════════════════════════

class UnitGroup {
  final String label;
  final List<String> units;
  const UnitGroup({required this.label, required this.units});
}

// Grupos del sistema MÉTRICO
const List<UnitGroup> kMetricGroups = [
  UnitGroup(label: 'Peso', units: ['kg', 'g', 'mg']),
  UnitGroup(label: 'Volumen', units: ['lt', 'ml', 'cl']),
  UnitGroup(label: 'Longitud', units: ['m', 'cm', 'mm']),
];

// Grupos del sistema IMPERIAL
const List<UnitGroup> kImperialGroups = [
  UnitGroup(label: 'Peso', units: ['lb', 'oz', 'stone']),
  UnitGroup(label: 'Volumen', units: ['gal', 'fl oz', 'pt', 'qt']),
  UnitGroup(label: 'Longitud', units: ['ft', 'in', 'yd']),
];

// Unidades INCONTABLES — para cosas que no se miden con precisión
const List<String> kUncountableUnits = [
  'unidad',       // una goma, un palo de pegamento
  'gota',         // colorante, esencia, aceite esencial
  'pizca',        // sal, polvo decorativo, purpurina
  'chorrito',     // aceite, salsa, pegamento líquido
  'cucharada',    // ingredientes de cocina o manualidades
  'cucharadita',  // ingredientes pequeños
  'taza',         // ingredientes de volumen informal
  'puñado',       // semillas, granos, material a granel
  'al gusto',     // no afecta el costo (valor $0)
  'a discreción', // igual que al gusto
];

/// Retorna todas las unidades disponibles según el sistema elegido.
/// Se usa para los dropdowns de "unidad de compra" y "unidad de uso".
List<String> allUnitsForSystem(String measureSystem) {
  final groups = measureSystem == 'imperial' ? kImperialGroups : kMetricGroups;
  return [
    ...kUncountableUnits,
    ...groups.expand((g) => g.units),
  ];
}

/// Retorna las unidades agrupadas para mostrar en el picker con secciones.
List<UnitGroup> groupedUnitsForSystem(String measureSystem) {
  final measurable = measureSystem == 'imperial' ? kImperialGroups : kMetricGroups;
  return [
    const UnitGroup(label: 'Incontables / Estimadas', units: kUncountableUnits),
    ...measurable,
  ];
}

// ── Tabla de conversiones para la regla de 3 ─────────────────────
// Si compra y uso tienen la misma categoría (ambos peso, ambos volumen…)
// se convierte automáticamente. Si no, se usa proporción 1:1.

const _massToGrams = <String, double>{
  'kg': 1000, 'g': 1, 'mg': 0.001,
  'lb': 453.592, 'oz': 28.3495, 'stone': 6350.29,
};
const _volToMl = <String, double>{
  'lt': 1000, 'l': 1000, 'ml': 1, 'cl': 10,
  'gal': 3785.41, 'fl oz': 29.5735, 'pt': 473.176, 'qt': 946.353,
};
const _lenToCm = <String, double>{
  'm': 100, 'cm': 1, 'mm': 0.1, 'km': 100000,
  'ft': 30.48, 'in': 2.54, 'yd': 91.44,
};

/// Factor de conversión de [from] a [to].
/// Retorna 1.0 si no hay conversión conocida (unidades iguales o incontables).
double conversionFactor({required String from, required String to}) {
  final f = from.toLowerCase().trim();
  final t = to.toLowerCase().trim();
  if (f == t) return 1.0;

  if (_massToGrams.containsKey(f) && _massToGrams.containsKey(t)) {
    return _massToGrams[f]! / _massToGrams[t]!;
  }
  if (_volToMl.containsKey(f) && _volToMl.containsKey(t)) {
    return _volToMl[f]! / _volToMl[t]!;
  }
  if (_lenToCm.containsKey(f) && _lenToCm.containsKey(t)) {
    return _lenToCm[f]! / _lenToCm[t]!;
  }
  return 1.0;
}

/// Indica si una unidad es "incontable" (al gusto, a discreción, etc.)
bool isUncountable(String unit) =>
    unit == 'al gusto' || unit == 'a discreción';