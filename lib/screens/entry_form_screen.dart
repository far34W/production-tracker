// lib/screens/entry_form_screen.dart
//
// ═══════════════════════════════════════════════════════════════════════════
// CHANGES FROM PREVIOUS VERSION
// ═══════════════════════════════════════════════════════════════════════════
//
// Added: _tryAutoFill() — called when the form first loads (add mode only).
//   • Reads PreviousShiftFins from ProductionProvider.getPreviousShiftFins()
//   • Fills ONLY empty Début controllers (never overwrites user input)
//   • Shows a subtle info banner when auto-fill was applied
//   • Has NO effect on Edit mode (widget.entry != null)
//
// Everything else — validation, submit, shift buttons, machine groups —
// is completely unchanged.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/production_entry.dart';
import '../providers/production_provider.dart';
import '../theme/app_theme.dart';

class EntryFormScreen extends StatefulWidget {
  final ProductionEntry? entry;
  const EntryFormScreen({super.key, this.entry});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _operatorCtrl  = TextEditingController();
  final _notesCtrl     = TextEditingController();

  // ── Meter pairs ───────────────────────────────────────────────────────────
  final _cadDebutCtrl   = TextEditingController();
  final _cadFinCtrl     = TextEditingController();
  final _ct2DebutCtrl   = TextEditingController();
  final _ct2FinCtrl     = TextEditingController();
  final _ct2pDebutCtrl  = TextEditingController();
  final _ct2pFinCtrl    = TextEditingController();
  final _sl3DebutCtrl   = TextEditingController();
  final _sl3FinCtrl     = TextEditingController();
  final _energyDebutCtrl = TextEditingController();
  final _energyFinCtrl   = TextEditingController();

  // ── Process inputs ────────────────────────────────────────────────────────
  final _amineCtrl      = TextEditingController();
  final _acideCtrl      = TextEditingController();
  final _esterCtrl      = TextEditingController();
  final _floculantCtrl  = TextEditingController();

  // ── Running hours (user input) ────────────────────────────────────────────
  final _runningHoursCtrl = TextEditingController();

  DateTime _date       = DateTime.now();
  Shift    _shift      = Shift.day;
  bool     _isLoading  = false;

  // ── Auto-fill state ───────────────────────────────────────────────────────
  bool _autoFillApplied   = false; // shows the info banner
  bool _autoFillLoading   = false; // brief spinner while reading DB

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _populateFromEntry(widget.entry!);
    } else {
      // Add mode: try to auto-fill début fields from the previous shift.
      // Schedule after first frame so the Provider is available.
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoFill());
    }
  }

  // ── Populate fields when editing an existing entry ────────────────────────

  void _populateFromEntry(ProductionEntry e) {
    _date  = e.date;
    _shift = e.shift;
    _operatorCtrl.text      = e.operatorName;
    _cadDebutCtrl.text      = _f(e.cadDebut);
    _cadFinCtrl.text        = _f(e.cadFin);
    _ct2DebutCtrl.text      = _f(e.ct2Debut);
    _ct2FinCtrl.text        = _f(e.ct2Fin);
    _ct2pDebutCtrl.text     = _f(e.ct2pDebut);
    _ct2pFinCtrl.text       = _f(e.ct2pFin);
    _sl3DebutCtrl.text      = _f(e.sl3Debut);
    _sl3FinCtrl.text        = _f(e.sl3Fin);
    _energyDebutCtrl.text   = _f(e.energyDebut);
    _energyFinCtrl.text     = _f(e.energyFin);
    _amineCtrl.text         = _f(e.amine);
    _acideCtrl.text         = _f(e.acide);
    _esterCtrl.text         = _f(e.ester);
    _floculantCtrl.text     = _f(e.floculant);
    _runningHoursCtrl.text  = _f(e.runningHours);
    _notesCtrl.text         = e.notes ?? '';
  }

  // ── AUTO-FILL LOGIC ───────────────────────────────────────────────────────
  //
  // Reads the FIN values of the most recent saved entry and copies them into
  // the DÉBUT controllers — but ONLY if those controllers are currently empty.
  //
  // This implements the industrial "shift chaining" rule:
  //   Previous shift's FIN = Current shift's DÉBUT
  //
  // Safe guarantees:
  //   1. Only runs in Add mode (never when editing an existing entry).
  //   2. Only fills EMPTY fields — if the user already typed something,
  //      that value is preserved.
  //   3. If the DB call fails, the form works normally (no crash).
  //   4. The banner informs the user that values were pre-filled.

  Future<void> _tryAutoFill() async {
    if (!mounted) return;

    setState(() => _autoFillLoading = true);

    try {
      final provider = context.read<ProductionProvider>();
      final prev     = await provider.getPreviousShiftFins();

      if (!mounted) return;

      if (!prev.hasAnyValue) {
        // No previous entry — nothing to auto-fill
        setState(() => _autoFillLoading = false);
        return;
      }

      // Fill only empty controllers
      bool applied = false;

      void fill(TextEditingController ctrl, double? value) {
        if (ctrl.text.trim().isEmpty && value != null) {
          ctrl.text = value.toStringAsFixed(2);
          applied = true;
        }
      }

      fill(_cadDebutCtrl,  prev.cadFin);
      fill(_ct2DebutCtrl,  prev.ct2Fin);
      fill(_ct2pDebutCtrl, prev.ct2pFin);
      fill(_sl3DebutCtrl,  prev.sl3Fin);

      setState(() {
        _autoFillLoading = false;
        _autoFillApplied = applied;
      });
    } catch (_) {
      if (mounted) setState(() => _autoFillLoading = false);
    }
  }

  // ── Formatters / parsers ──────────────────────────────────────────────────

  String  _f(double? v) => v != null ? v.toStringAsFixed(2) : '';
  double? _p(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  @override
  void dispose() {
    for (final c in [
      _operatorCtrl, _notesCtrl,
      _cadDebutCtrl, _cadFinCtrl,
      _ct2DebutCtrl, _ct2FinCtrl,
      _ct2pDebutCtrl, _ct2pFinCtrl,
      _sl3DebutCtrl, _sl3FinCtrl,
      _energyDebutCtrl, _energyFinCtrl,
      _amineCtrl, _acideCtrl, _esterCtrl, _floculantCtrl,
      _runningHoursCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'New Production Entry'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── Auto-fill banner ──────────────────────────────────────────
            if (_autoFillLoading)
              const _InfoBanner(
                icon: Icons.sync_rounded,
                message: 'Loading previous shift values…',
                color: Color(0xFF1565C0),
              ),

            if (_autoFillApplied && !_autoFillLoading)
              _InfoBanner(
                icon: Icons.auto_fix_high_rounded,
                message: 'Début values pre-filled from the previous shift. '
                         'You can edit them freely.',
                color: AppTheme.success,
                onDismiss: () => setState(() => _autoFillApplied = false),
              ),

            if (_autoFillApplied || _autoFillLoading)
              const SizedBox(height: 16),

            // ════════════════════════════════════════════════════════════
            // SHIFT INFORMATION
            // ════════════════════════════════════════════════════════════
            _sectionLabel('Shift Information'),
            const SizedBox(height: 12),

            // Date picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  DateFormat('EEEE, dd MMM yyyy').format(_date),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Shift toggle
            Row(
              children: [
                Expanded(
                  child: _ShiftButton(
                    label: 'Day Shift',
                    subtitle: '06:00 – 18:00',
                    icon: Icons.wb_sunny_rounded,
                    color: AppTheme.dayColor,
                    selected: _shift == Shift.day,
                    onTap: () => setState(() => _shift = Shift.day),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShiftButton(
                    label: 'Night Shift',
                    subtitle: '18:00 – 06:00',
                    icon: Icons.nightlight_rounded,
                    color: AppTheme.nightColor,
                    selected: _shift == Shift.night,
                    onTap: () => setState(() => _shift = Shift.night),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Operator
            TextFormField(
              controller: _operatorCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Operator Name *',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            const SizedBox(height: 24),

            // ════════════════════════════════════════════════════════════
            // METER READINGS
            // ════════════════════════════════════════════════════════════
            _sectionLabel('Meter Readings'),
            const SizedBox(height: 12),

            _MachineGroup(
              label: 'CAD',
              color: AppTheme.primary,
              debutCtrl: _cadDebutCtrl,
              finCtrl:   _cadFinCtrl,
            ),
            const SizedBox(height: 10),
            _MachineGroup(
              label: 'CT2',
              color: AppTheme.accent,
              debutCtrl: _ct2DebutCtrl,
              finCtrl:   _ct2FinCtrl,
            ),
            const SizedBox(height: 10),
            _MachineGroup(
              label: "CT2'",
              color: const Color(0xFF7B1FA2),
              debutCtrl: _ct2pDebutCtrl,
              finCtrl:   _ct2pFinCtrl,
            ),
            const SizedBox(height: 10),
            _MachineGroup(
              label: 'SL3',
              color: AppTheme.success,
              debutCtrl: _sl3DebutCtrl,
              finCtrl:   _sl3FinCtrl,
            ),

            const SizedBox(height: 24),

            // ════════════════════════════════════════════════════════════
            // ENERGY
            // ════════════════════════════════════════════════════════════
            _sectionLabel('Energy (optional)'),
            const SizedBox(height: 12),
            _MachineGroup(
              label: 'Energy',
              color: AppTheme.warning,
              debutCtrl: _energyDebutCtrl,
              finCtrl:   _energyFinCtrl,
            ),

            const SizedBox(height: 24),

            // ════════════════════════════════════════════════════════════
            // PROCESS INPUTS
            // ════════════════════════════════════════════════════════════
            _sectionLabel('Process Inputs'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _numField(_amineCtrl,     'Amine',    AppTheme.danger)),
                const SizedBox(width: 12),
                Expanded(child: _numField(_acideCtrl,     'Acide',    const Color(0xFF6D4C41))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _numField(_esterCtrl,     'Ester',    const Color(0xFF00838F))),
                const SizedBox(width: 12),
                Expanded(child: _numField(_floculantCtrl, 'Floculant',const Color(0xFF558B2F))),
              ],
            ),

            const SizedBox(height: 24),

            // ════════════════════════════════════════════════════════════
            // RUNNING HOURS
            // ════════════════════════════════════════════════════════════
            _sectionLabel('Running Hours'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _runningHoursCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Running Hours',
                hintText: 'e.g. 11.5',
                prefixIcon: const Icon(
                  Icons.timer_outlined,
                  color: AppTheme.success,
                ),
                suffixText: 'h',
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppTheme.success, width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: Icon(Icons.notes_rounded),
                ),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2,
                        ),
                      )
                    : Icon(_isEditing
                        ? Icons.save_rounded
                        : Icons.add_rounded),
                label: Text(_isEditing ? 'Save Changes' : 'Add Entry'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppTheme.primary,
      letterSpacing: 0.6,
    ),
  );

  Widget _numField(TextEditingController ctrl, String label, Color color) =>
      TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color, fontSize: 13),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final entry = ProductionEntry(
      id:           widget.entry?.id,
      date:         _date,
      operatorName: _operatorCtrl.text.trim(),
      shift:        _shift,
      cadDebut:     _p(_cadDebutCtrl),
      cadFin:       _p(_cadFinCtrl),
      ct2Debut:     _p(_ct2DebutCtrl),
      ct2Fin:       _p(_ct2FinCtrl),
      ct2pDebut:    _p(_ct2pDebutCtrl),
      ct2pFin:      _p(_ct2pFinCtrl),
      sl3Debut:     _p(_sl3DebutCtrl),
      sl3Fin:       _p(_sl3FinCtrl),
      energyDebut:  _p(_energyDebutCtrl),
      energyFin:    _p(_energyFinCtrl),
      amine:        _p(_amineCtrl),
      acide:        _p(_acideCtrl),
      ester:        _p(_esterCtrl),
      floculant:    _p(_floculantCtrl),
      runningHours: _p(_runningHoursCtrl),
      notes:        _notesCtrl.text.trim().isEmpty
                      ? null
                      : _notesCtrl.text.trim(),
      createdAt:    widget.entry?.createdAt ?? DateTime.now(),
    );

    try {
      final provider = context.read<ProductionProvider>();
      if (_isEditing) {
        await provider.updateEntry(entry);
      } else {
        await provider.addEntry(entry);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? '✓ Entry updated'
                  : '✓ Entry added for ${entry.formattedDate}',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Auto-fill info banner ─────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String   message;
  final Color    color;
  final VoidCallback? onDismiss;

  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.color,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, size: 16, color: color),
            ),
        ],
      ),
    );
  }
}

// ── Shift toggle button ───────────────────────────────────────────────────────

class _ShiftButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ShiftButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : const Color(0xFFDDE1E7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? Colors.white : color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? Colors.white70
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Machine meter group ───────────────────────────────────────────────────────

class _MachineGroup extends StatelessWidget {
  final String label;
  final Color  color;
  final TextEditingController debutCtrl;
  final TextEditingController finCtrl;

  const _MachineGroup({
    required this.label,
    required this.color,
    required this.debutCtrl,
    required this.finCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _numInput(debutCtrl, 'Début', color)),
              const SizedBox(width: 10),
              Expanded(child: _numInput(finCtrl,   'Fin',   color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numInput(TextEditingController ctrl, String lbl, Color col) =>
      TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: lbl,
          labelStyle: TextStyle(color: col, fontSize: 13),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: col, width: 2),
          ),
        ),
      );
}
