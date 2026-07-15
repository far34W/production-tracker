// lib/models/production_entry.dart
//
// ═══════════════════════════════════════════════════════════════════════════
// FIX SUMMARY
// ═══════════════════════════════════════════════════════════════════════════
//
// • Removed cadDiff / ct2Diff / sl3Diff getters (were never persisted —
//   no migration needed, just Dart code cleanup)
// • runningHours: double? (user input, NOT calculated from shift hours)
// • All toMap() keys verified to match DatabaseService column names exactly
// • All fromMap() keys verified to match DatabaseService column names exactly
// • ShiftExtension.theoreticalHours removed (no longer used)
//
// KEY NAMING RULES (to prevent future "no such column" crashes):
//   Dart field       → SQLite column
//   operatorName     → operator_name      ✓
//   cadDebut         → cad_debut          ✓
//   cadFin           → cad_fin            ✓
//   ct2Debut         → ct2_debut          ✓
//   ct2Fin           → ct2_fin            ✓
//   ct2pDebut        → ct2p_debut         ✓
//   ct2pFin          → ct2p_fin           ✓
//   sl3Debut         → sl3_debut          ✓
//   sl3Fin           → sl3_fin            ✓
//   energyDebut      → energy_debut       ✓
//   energyFin        → energy_fin         ✓
//   amine            → amine              ✓
//   acide            → acide              ✓
//   ester            → ester              ✓
//   floculant        → floculant          ✓
//   runningHours     → running_hours      ✓
//   createdAt        → created_at         ✓
// ═══════════════════════════════════════════════════════════════════════════

enum Shift { day, night }

extension ShiftExtension on Shift {
  String get label     => this == Shift.day ? 'Day' : 'Night';
  int    get startHour => this == Shift.day ? 6 : 18;
  int    get endHour   => this == Shift.day ? 18 : 6;
}

class ProductionEntry {
  final int? id;

  // ── Identification ────────────────────────────────────────────────────────
  final DateTime date;
  final String   operatorName;
  final Shift    shift;

  // ── Meter readings ────────────────────────────────────────────────────────
  final double? cadDebut;
  final double? cadFin;
  final double? ct2Debut;
  final double? ct2Fin;
  final double? ct2pDebut;   // CT2' début
  final double? ct2pFin;     // CT2' fin
  final double? sl3Debut;
  final double? sl3Fin;

  // ── Energy ────────────────────────────────────────────────────────────────
  final double? energyDebut;
  final double? energyFin;

  // ── Process inputs ────────────────────────────────────────────────────────
  final double? amine;
  final double? acide;
  final double? ester;
  final double? floculant;

  // ── Running hours (user input — NOT auto-calculated) ─────────────────────
  final double? runningHours;

  // ── Notes ─────────────────────────────────────────────────────────────────
  final String? notes;

  final DateTime createdAt;

  const ProductionEntry({
    this.id,
    required this.date,
    required this.operatorName,
    required this.shift,
    this.cadDebut,
    this.cadFin,
    this.ct2Debut,
    this.ct2Fin,
    this.ct2pDebut,
    this.ct2pFin,
    this.sl3Debut,
    this.sl3Fin,
    this.energyDebut,
    this.energyFin,
    this.amine,
    this.acide,
    this.ester,
    this.floculant,
    this.runningHours,
    this.notes,
    required this.createdAt,
  });

  // ── Computed properties (pure Dart — NOT persisted) ───────────────────────

  double? get energyConsumption {
    if (energyDebut == null || energyFin == null) return null;
    return energyFin! - energyDebut!;
  }

  String get shiftTimeRange =>
      shift == Shift.day ? '06:00 – 18:00' : '18:00 – 06:00 (+1)';

  String get formattedDate {
    const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[date.weekday - 1]}, ${date.day} '
           '${months[date.month - 1]} ${date.year}';
  }

  // ── SQLite serialisation ──────────────────────────────────────────────────
  //
  // RULE: every key here must exist as a column in DatabaseService._onCreate.
  // Misspelling a key here produces a runtime crash, NOT a compile error.

  Map<String, dynamic> toMap() => {
    'id':            id,
    'date':          date.toIso8601String(),
    'operator_name': operatorName,
    'shift':         shift.name,
    'cad_debut':     cadDebut,
    'cad_fin':       cadFin,
    'ct2_debut':     ct2Debut,
    'ct2_fin':       ct2Fin,
    'ct2p_debut':    ct2pDebut,    // ← snake_case, matches column name
    'ct2p_fin':      ct2pFin,
    'sl3_debut':     sl3Debut,
    'sl3_fin':       sl3Fin,
    'energy_debut':  energyDebut,
    'energy_fin':    energyFin,
    'amine':         amine,
    'acide':         acide,
    'ester':         ester,
    'floculant':     floculant,
    'running_hours': runningHours,
    'notes':         notes,
    'created_at':    createdAt.toIso8601String(),
  };

  factory ProductionEntry.fromMap(Map<String, dynamic> m) => ProductionEntry(
    id:           m['id']             as int?,
    date:         DateTime.parse(m['date'] as String),
    operatorName: m['operator_name']  as String,
    shift:        Shift.values.firstWhere(
      (s) => s.name == m['shift'],
      orElse: () => Shift.day,
    ),
    cadDebut:     (m['cad_debut']     as num?)?.toDouble(),
    cadFin:       (m['cad_fin']       as num?)?.toDouble(),
    ct2Debut:     (m['ct2_debut']     as num?)?.toDouble(),
    ct2Fin:       (m['ct2_fin']       as num?)?.toDouble(),
    ct2pDebut:    (m['ct2p_debut']    as num?)?.toDouble(),
    ct2pFin:      (m['ct2p_fin']      as num?)?.toDouble(),
    sl3Debut:     (m['sl3_debut']     as num?)?.toDouble(),
    sl3Fin:       (m['sl3_fin']       as num?)?.toDouble(),
    energyDebut:  (m['energy_debut']  as num?)?.toDouble(),
    energyFin:    (m['energy_fin']    as num?)?.toDouble(),
    amine:        (m['amine']         as num?)?.toDouble(),
    acide:        (m['acide']         as num?)?.toDouble(),
    ester:        (m['ester']         as num?)?.toDouble(),
    floculant:    (m['floculant']     as num?)?.toDouble(),
    runningHours: (m['running_hours'] as num?)?.toDouble(),
    notes:        m['notes']          as String?,
    createdAt:    DateTime.parse(m['created_at'] as String),
  );

  ProductionEntry copyWith({
    int? id,
    DateTime? date,
    String? operatorName,
    Shift? shift,
    double? cadDebut,
    double? cadFin,
    double? ct2Debut,
    double? ct2Fin,
    double? ct2pDebut,
    double? ct2pFin,
    double? sl3Debut,
    double? sl3Fin,
    double? energyDebut,
    double? energyFin,
    double? amine,
    double? acide,
    double? ester,
    double? floculant,
    double? runningHours,
    String? notes,
    DateTime? createdAt,
  }) => ProductionEntry(
    id:           id           ?? this.id,
    date:         date         ?? this.date,
    operatorName: operatorName ?? this.operatorName,
    shift:        shift        ?? this.shift,
    cadDebut:     cadDebut     ?? this.cadDebut,
    cadFin:       cadFin       ?? this.cadFin,
    ct2Debut:     ct2Debut     ?? this.ct2Debut,
    ct2Fin:       ct2Fin       ?? this.ct2Fin,
    ct2pDebut:    ct2pDebut    ?? this.ct2pDebut,
    ct2pFin:      ct2pFin      ?? this.ct2pFin,
    sl3Debut:     sl3Debut     ?? this.sl3Debut,
    sl3Fin:       sl3Fin       ?? this.sl3Fin,
    energyDebut:  energyDebut  ?? this.energyDebut,
    energyFin:    energyFin    ?? this.energyFin,
    amine:        amine        ?? this.amine,
    acide:        acide        ?? this.acide,
    ester:        ester        ?? this.ester,
    floculant:    floculant    ?? this.floculant,
    runningHours: runningHours ?? this.runningHours,
    notes:        notes        ?? this.notes,
    createdAt:    createdAt    ?? this.createdAt,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ProductionStats — dashboard aggregates (pure Dart, never persisted)
// ─────────────────────────────────────────────────────────────────────────────

class ProductionStats {
  final int    totalEntries;
  final int    dayShifts;
  final int    nightShifts;
  final double totalRunningHours;

  const ProductionStats({
    required this.totalEntries,
    required this.dayShifts,
    required this.nightShifts,
    required this.totalRunningHours,
  });

  factory ProductionStats.fromEntries(List<ProductionEntry> entries) {
    if (entries.isEmpty) {
      return const ProductionStats(
        totalEntries: 0,
        dayShifts:    0,
        nightShifts:  0,
        totalRunningHours: 0,
      );
    }

    return ProductionStats(
      totalEntries:      entries.length,
      dayShifts:         entries.where((e) => e.shift == Shift.day).length,
      nightShifts:       entries.where((e) => e.shift == Shift.night).length,
      totalRunningHours: entries.fold(
        0.0, (sum, e) => sum + (e.runningHours ?? 0.0),
      ),
    );
  }
}
