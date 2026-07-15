// lib/providers/production_provider.dart
//
// ═══════════════════════════════════════════════════════════════════════════
// CHANGES FROM PREVIOUS VERSION
// ═══════════════════════════════════════════════════════════════════════════
//
// 1. Added getPreviousShiftFins() — returns a PreviousShiftFins object
//    containing the FIN values of the most recent entry.
//    The EntryFormScreen calls this when the user selects a shift, then
//    pre-populates empty Début fields.  All existing methods unchanged.
//
// 2. Stats calculation uses entry.runningHours (user input), not a
//    calculated shift duration.
//
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import '../models/production_entry.dart';
import '../services/database_service.dart';
import '../services/excel_service.dart';

enum SortOrder { dateDesc, dateAsc, operatorAsc }

// ── Value object returned by getPreviousShiftFins() ───────────────────────────
//
// Using a dedicated class (instead of a raw Map or the full ProductionEntry)
// keeps the form screen clean — it only receives the data it needs.

class PreviousShiftFins {
  final double? cadFin;
  final double? ct2Fin;
  final double? ct2pFin;
  final double? sl3Fin;

  const PreviousShiftFins({
    this.cadFin,
    this.ct2Fin,
    this.ct2pFin,
    this.sl3Fin,
  });

  /// True when at least one fin value is available for auto-fill.
  bool get hasAnyValue =>
      cadFin != null || ct2Fin != null || ct2pFin != null || sl3Fin != null;
}

class ProductionProvider extends ChangeNotifier {
  final _db    = DatabaseService.instance;
  final _excel = ExcelService.instance;

  // ── State ─────────────────────────────────────────────────────────────────
  List<ProductionEntry> _allEntries  = [];
  List<ProductionEntry> _filtered    = [];
  String                _searchQuery = '';
  Shift?                _shiftFilter;
  SortOrder             _sortOrder   = SortOrder.dateDesc;
  bool                  _isLoading   = false;
  String?               _error;

  ProductionStats _stats = const ProductionStats(
    totalEntries:      0,
    dayShifts:         0,
    nightShifts:       0,
    totalRunningHours: 0,
  );

  // ── Getters ───────────────────────────────────────────────────────────────
  List<ProductionEntry> get entries     => _filtered;
  List<ProductionEntry> get allEntries  => _allEntries;
  ProductionStats       get stats       => _stats;
  bool                  get isLoading   => _isLoading;
  String?               get error       => _error;
  String                get searchQuery => _searchQuery;
  Shift?                get shiftFilter => _shiftFilter;
  SortOrder             get sortOrder   => _sortOrder;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _load();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _load() async {
    _allEntries = await _db.getAll();
    _stats      = ProductionStats.fromEntries(_allEntries);
    _applyFilter();
  }

  // ── Filter / Search ───────────────────────────────────────────────────────

  void setSearch(String q) {
    _searchQuery = q;
    _applyFilter();
  }

  void setShiftFilter(Shift? s) {
    _shiftFilter = s;
    _applyFilter();
  }

  void setSortOrder(SortOrder o) {
    _sortOrder = o;
    _applyFilter();
  }

  void clearFilters() {
    _searchQuery = '';
    _shiftFilter = null;
    _sortOrder   = SortOrder.dateDesc;
    _applyFilter();
  }

  void _applyFilter() {
    var result = List<ProductionEntry>.from(_allEntries);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) =>
        e.operatorName.toLowerCase().contains(q) ||
        e.formattedDate.toLowerCase().contains(q),
      ).toList();
    }

    if (_shiftFilter != null) {
      result = result.where((e) => e.shift == _shiftFilter).toList();
    }

    switch (_sortOrder) {
      case SortOrder.dateDesc:
        result.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOrder.dateAsc:
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOrder.operatorAsc:
        result.sort((a, b) => a.operatorName.compareTo(b.operatorName));
        break;
    }

    _filtered = result;
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addEntry(ProductionEntry entry) async {
    _setLoading(true);
    try {
      await _db.insert(entry);
      await _load();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateEntry(ProductionEntry entry) async {
    _setLoading(true);
    try {
      await _db.update(entry);
      await _load();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteEntry(int id) async {
    _setLoading(true);
    try {
      await _db.delete(id);
      await _load();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Auto-fill: shift chaining ─────────────────────────────────────────────
  //
  // INDUSTRIAL LOGIC:
  //   When an operator starts a new shift, the meter readings should continue
  //   from where the previous shift ended.  This method returns the FIN values
  //   of the most recent entry so the form can pre-populate the DÉBUT fields.
  //
  // Guarantees:
  //   • Returns null PreviousShiftFins when no previous entry exists.
  //   • The form only applies values to EMPTY controllers — never overwrites
  //     values the user has already typed.
  //   • Database read is asynchronous; the form shows a brief loading state.
  //   • This method does NOT modify any stored data.

  Future<PreviousShiftFins> getPreviousShiftFins() async {
    try {
      // getLatestEntry() queries the DB ordered by date DESC, created_at DESC
      // so it always returns the most recently saved entry regardless of shift.
      final latest = await _db.getLatestEntry();
      if (latest == null) return const PreviousShiftFins();

      return PreviousShiftFins(
        cadFin:  latest.cadFin,
        ct2Fin:  latest.ct2Fin,
        ct2pFin: latest.ct2pFin,
        sl3Fin:  latest.sl3Fin,
      );
    } catch (_) {
      // If anything goes wrong, return empty — the form still works normally.
      return const PreviousShiftFins();
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<String> exportToExcel() async {
    return _excel.exportEntries(_allEntries);
  }

  Future<String> exportFilteredToExcel() async {
    return _excel.exportEntries(_filtered, sheetTitle: 'Filtered Log');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ProductionEntry? getById(int id) {
    try {
      return _allEntries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
