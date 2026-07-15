// lib/screens/dashboard_screen.dart
//
// Overview screen: total entries, shift breakdown, machine totals,
// recent activity, and the global Excel export button.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/production_entry.dart';
import '../providers/production_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;

        return RefreshIndicator(
          onRefresh: provider.initialize,
          child: CustomScrollView(
            slivers: [
              // ── Hero app bar ─────────────────────
              SliverAppBar(
                expandedHeight: 130,
                floating: true,
                snap: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryDark, AppTheme.primaryLight],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Production Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${stats.totalEntries} entries · '
                          '${stats.totalRunningHours.toStringAsFixed(0)} h total',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  // Export button in app bar
                  _ExportButton(provider: provider),
                  const SizedBox(width: 8),
                ],
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),

                  // ── KPI grid ─────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.05,
                      children: [
                        StatCard(
                          value: '${stats.totalEntries}',
                          label: 'Total Entries',
                          icon: Icons.assignment_rounded,
                          color: AppTheme.primary,
                        ),
                        StatCard(
                          value: '${stats.totalRunningHours.toStringAsFixed(0)} h',
                          label: 'Running Hours',
                          subtitle: 'Cumulative',
                          icon: Icons.timer_rounded,
                          color: AppTheme.success,
                        ),
                        StatCard(
                          value: '${stats.dayShifts}',
                          label: 'Day Shifts',
                          subtitle: '06:00 – 18:00',
                          icon: Icons.wb_sunny_rounded,
                          color: AppTheme.dayColor,
                        ),
                        StatCard(
                          value: '${stats.nightShifts}',
                          label: 'Night Shifts',
                          subtitle: '18:00 – 06:00',
                          icon: Icons.nightlight_rounded,
                          color: AppTheme.nightColor,
                        ),
                      ],
                    ),
                  ),

                  // Machine totals section removed — diffs are no longer tracked.

                  // ── Recent entries ────────────────
                  _sectionHeader('Recent Entries'),
                  ...provider.allEntries.take(5).map((e) => _RecentTile(entry: e)),

                  const SizedBox(height: 80),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.primary,
        letterSpacing: 0.3,
      ),
    ),
  );
}

// ── Compact recent entry tile ────────────────────────────────────────────────

class _RecentTile extends StatelessWidget {
  final ProductionEntry entry;
  const _RecentTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDay = entry.shift == Shift.day;
    final col   = isDay ? AppTheme.dayColor : AppTheme.nightColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: col.withOpacity(0.12),
        child: Icon(
          isDay ? Icons.wb_sunny_rounded : Icons.nightlight_rounded,
          color: col, size: 18,
        ),
      ),
      title: Text(
        entry.operatorName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${entry.formattedDate} · ${entry.shiftTimeRange}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: entry.runningHours != null
          ? Text(
              '${entry.runningHours!.toStringAsFixed(1)} h',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: col,
                fontSize: 14,
              ),
            )
          : null,
    );
  }
}

// ── Export button with loading state ────────────────────────────────────────

class _ExportButton extends StatefulWidget {
  final ProductionProvider provider;
  const _ExportButton({required this.provider});

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Export to Excel',
      icon: _busy
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2,
              ),
            )
          : const Icon(Icons.upload_file_rounded),
      onPressed: _busy || widget.provider.allEntries.isEmpty
          ? null
          : _export,
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await widget.provider.exportToExcel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Excel file ready to share'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
