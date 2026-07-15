// lib/widgets/entry_card.dart
//
// Card that displays one ProductionEntry with swipe-to-delete/edit.
// Updated layout per spec:
//   CAD: début → fin
//   CT2: début → fin
//   CT2': début → fin       ← new
//   SL3: début → fin
//   STATS: Amine | Acide | Ester | Floculant  ← new
//   Running Hours                              ← now user-input field

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/production_entry.dart';
import '../providers/production_provider.dart';
import '../theme/app_theme.dart';

class EntryCard extends StatelessWidget {
  final ProductionEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const EntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDay    = entry.shift == Shift.day;
    final shiftCol = isDay ? AppTheme.dayColor : AppTheme.nightColor;
    final numFmt   = NumberFormat('#,##0.00');

    String fmt(double? v) => v != null ? numFmt.format(v) : '—';

    // Does this entry have any chemical data?
    final hasChemicals = entry.amine    != null || entry.acide   != null ||
                         entry.ester    != null || entry.floculant != null;

    return Slidable(
      key: ValueKey(entry.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit?.call(),
            backgroundColor: AppTheme.primaryLight,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Delete',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [

              // ── Header strip ─────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: shiftCol.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  border: Border(
                    left: BorderSide(color: shiftCol, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    // Shift badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: shiftCol,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDay
                                ? Icons.wb_sunny_rounded
                                : Icons.nightlight_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.shift.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.formattedDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Text(
                      entry.shiftTimeRange,
                      style: TextStyle(
                          fontSize: 12,
                          color: shiftCol,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // ── Operator + Running Hours chip ─────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.operatorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    // Running hours — show only when user entered a value
                    if (entry.runningHours != null)
                      _Chip(
                        label:
                            '${entry.runningHours!.toStringAsFixed(1)} h',
                        icon: Icons.timer_outlined,
                        color: AppTheme.success,
                      ),
                  ],
                ),
              ),

              const Divider(height: 1, indent: 14, endIndent: 14),

              // ── Meter readings: CAD / CT2 / CT2' / SL3 ───
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Column(
                  children: [
                    _MeterRow(
                      label: 'CAD',
                      debut: entry.cadDebut,
                      fin: entry.cadFin,
                      fmt: fmt,
                    ),
                    const SizedBox(height: 5),
                    _MeterRow(
                      label: 'CT2',
                      debut: entry.ct2Debut,
                      fin: entry.ct2Fin,
                      fmt: fmt,
                    ),
                    const SizedBox(height: 5),
                    _MeterRow(
                      label: "CT2'",
                      debut: entry.ct2pDebut,
                      fin: entry.ct2pFin,
                      fmt: fmt,
                      labelColor: const Color(0xFF7B1FA2),
                    ),
                    const SizedBox(height: 5),
                    _MeterRow(
                      label: 'SL3',
                      debut: entry.sl3Debut,
                      fin: entry.sl3Fin,
                      fmt: fmt,
                      labelColor: AppTheme.success,
                    ),
                    // Energy (shown only when present)
                    if (entry.energyConsumption != null) ...[
                      const SizedBox(height: 5),
                      _MeterRow(
                        label: 'Energy',
                        debut: entry.energyDebut,
                        fin: entry.energyFin,
                        fmt: fmt,
                        labelColor: AppTheme.warning,
                        finSuffix: ' kWh',
                      ),
                    ],
                  ],
                ),
              ),

              // ── Chemical stats row ────────────────────────
              if (hasChemicals) ...[
                const Divider(height: 1, indent: 14, endIndent: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROCESS INPUTS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (entry.amine != null)
                            _StatPill('Amine', fmt(entry.amine),
                                AppTheme.danger),
                          if (entry.acide != null)
                            _StatPill('Acide', fmt(entry.acide),
                                const Color(0xFF6D4C41)),
                          if (entry.ester != null)
                            _StatPill('Ester', fmt(entry.ester),
                                const Color(0xFF00838F)),
                          if (entry.floculant != null)
                            _StatPill('Floculant', fmt(entry.floculant),
                                const Color(0xFF558B2F)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // ── Notes ─────────────────────────────────────
              if (entry.notes != null && entry.notes!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Text(
                    '📝 ${entry.notes}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
          'Delete the ${entry.shift.label} shift entry for '
          '${entry.formattedDate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ProductionProvider>().deleteEntry(entry.id!);
    }
  }
}

// ── Meter reading row: LABEL  début → fin ────────────────────────────────────

class _MeterRow extends StatelessWidget {
  final String label;
  final double? debut;
  final double? fin;
  final String Function(double?) fmt;
  final Color labelColor;
  final String finSuffix;

  const _MeterRow({
    required this.label,
    required this.debut,
    required this.fin,
    required this.fmt,
    this.labelColor = AppTheme.primary,
    this.finSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Label
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ),
        // Début value
        Expanded(
          child: _Cell(label: 'Début', value: fmt(debut)),
        ),
        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded,
              size: 14, color: Colors.grey.shade400),
        ),
        // Fin value
        Expanded(
          child: _Cell(
              label: 'Fin',
              value: '${fmt(fin)}$finSuffix'),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  const _Cell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: Color(0xFF9CA3AF))),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Chemical stat pill ────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.3),
            ),
            Text(
              value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Generic chip ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Chip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
