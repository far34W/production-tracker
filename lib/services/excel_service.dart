// lib/services/excel_service.dart
//
// Generates a formatted .xlsx from a list of ProductionEntry records.
// Updated for new fields: CT2', Amine, Acide, Ester, Floculant, Running Hours.
// cadDiff / ct2Diff / sl3Diff columns removed.

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/production_entry.dart';

class ExcelService {
  ExcelService._();
  static final ExcelService instance = ExcelService._();

  Future<String> exportEntries(
    List<ProductionEntry> entries, {
    String? sheetTitle,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    final title = sheetTitle ?? 'Production Log';
    final sheet = excel[title];

    // Palette
    const headerBg   = '1565C0';
    const subBg      = '1E88E5';
    const dayBg      = 'E3F2FD';
    const nightBg    = 'FFF8E1';
    const totalBg    = 'E8F5E9';
    const white      = 'FFFFFF';

    void writeCell(
      Sheet s, int col, int row, dynamic value, {
      bool bold = false,
      String? bgHex,
      String? fgHex,
      HorizontalAlign align = HorizontalAlign.Center,
    }) {
      final cell = s.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      if (value is double) {
        cell.value = DoubleCellValue(value);
      } else if (value is int) {
        cell.value = IntCellValue(value);
      } else {
        cell.value = TextCellValue(value?.toString() ?? '');
      }
      cell.cellStyle = CellStyle(
        bold: bold,
        backgroundColorHex:
            bgHex != null
    ? ExcelColor.fromHexString('#$bgHex')
    : ExcelColor.fromHexString('#FFFFFF'),  
        fontColorHex:
            fgHex != null
    ? ExcelColor.fromHexString('#$fgHex')
    : ExcelColor.fromHexString('#000000'),
        horizontalAlign: align,
      );
    }

    // ── Row 0: Title banner ────────────────────
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    const totalCols = 21;
    for (var c = 0; c < totalCols; c++) {
      writeCell(sheet, c, 0, '', bgHex: headerBg);
    }
    writeCell(sheet, 0, 0,
      'PRODUCTION TRACKING LOG — Generated: $now',
      bold: true, bgHex: headerBg, fgHex: white,
    );

    // ── Row 1: Column headers ──────────────────
    const headers = [
      '#', 'Date', 'Operator', 'Shift', 'Period',
      'CAD Début', 'CAD Fin',
      'CT2 Début', 'CT2 Fin',
      "CT2' Début", "CT2' Fin",
      'SL3 Début', 'SL3 Fin',
      'Energy Début', 'Energy Fin', 'Energy (kWh)',
      'Amine', 'Acide', 'Ester', 'Floculant',
      'Running Hours',
      'Notes',
    ];
    for (var c = 0; c < headers.length; c++) {
      writeCell(sheet, c, 1, headers[c],
          bold: true, bgHex: subBg, fgHex: white);
    }

    // ── Data rows ──────────────────────────────
    final dateFmt = DateFormat('dd/MM/yyyy');
    final nf      = NumberFormat('#,##0.00');
    String f(double? v) => v != null ? nf.format(v) : '—';

    for (var i = 0; i < entries.length; i++) {
      final e   = entries[i];
      final row = i + 2;
      final bg  = e.shift == Shift.day ? dayBg : nightBg;

      writeCell(sheet, 0,  row, i + 1,                    bgHex: bg);
      writeCell(sheet, 1,  row, dateFmt.format(e.date),   bgHex: bg);
      writeCell(sheet, 2,  row, e.operatorName,            bgHex: bg, align: HorizontalAlign.Left);
      writeCell(sheet, 3,  row, e.shift.label,             bgHex: bg, bold: true);
      writeCell(sheet, 4,  row, e.shiftTimeRange,          bgHex: bg);
      writeCell(sheet, 5,  row, f(e.cadDebut),             bgHex: bg);
      writeCell(sheet, 6,  row, f(e.cadFin),               bgHex: bg);
      writeCell(sheet, 7,  row, f(e.ct2Debut),             bgHex: bg);
      writeCell(sheet, 8,  row, f(e.ct2Fin),               bgHex: bg);
      writeCell(sheet, 9,  row, f(e.ct2pDebut),            bgHex: bg);
      writeCell(sheet, 10, row, f(e.ct2pFin),              bgHex: bg);
      writeCell(sheet, 11, row, f(e.sl3Debut),             bgHex: bg);
      writeCell(sheet, 12, row, f(e.sl3Fin),               bgHex: bg);
      writeCell(sheet, 13, row, f(e.energyDebut),          bgHex: bg);
      writeCell(sheet, 14, row, f(e.energyFin),            bgHex: bg);
      writeCell(sheet, 15, row, f(e.energyConsumption),    bgHex: bg);
      writeCell(sheet, 16, row, f(e.amine),                bgHex: bg);
      writeCell(sheet, 17, row, f(e.acide),                bgHex: bg);
      writeCell(sheet, 18, row, f(e.ester),                bgHex: bg);
      writeCell(sheet, 19, row, f(e.floculant),            bgHex: bg);
      writeCell(sheet, 20, row, f(e.runningHours),         bgHex: bg, bold: true);
      writeCell(sheet, 21, row, e.notes ?? '',             bgHex: bg, align: HorizontalAlign.Left);
    }

    // ── Totals row ─────────────────────────────
    if (entries.isNotEmpty) {
      final stats  = ProductionStats.fromEntries(entries);
      final totRow = entries.length + 2;

      writeCell(sheet, 0, totRow, 'TOTALS',
          bold: true, bgHex: totalBg);
      writeCell(sheet, 1, totRow, '${entries.length} entries',
          bold: true, bgHex: totalBg);
      writeCell(sheet, 3, totRow,
          'Day: ${stats.dayShifts}  Night: ${stats.nightShifts}',
          bold: true, bgHex: totalBg);
      for (var c = 2; c <= 19; c++) {
        if (c == 3) continue;
        writeCell(sheet, c, totRow, '', bgHex: totalBg);
      }
      writeCell(sheet, 20, totRow, stats.totalRunningHours,
          bold: true, bgHex: totalBg);
      writeCell(sheet, 21, totRow, '', bgHex: totalBg);
    }

    // ── Column widths ──────────────────────────
    const widths = [
      5.0, 14.0, 20.0, 9.0, 18.0,  // # Date Op Shift Period
      13.0, 13.0,                    // CAD
      13.0, 13.0,                    // CT2
      13.0, 13.0,                    // CT2'
      13.0, 13.0,                    // SL3
      14.0, 14.0, 14.0,              // Energy
      12.0, 12.0, 12.0, 12.0,       // Amine Acide Ester Floculant
      13.0,                          // Running Hours
      28.0,                          // Notes
    ];
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }

    // ── Save & share ───────────────────────────
    final bytes = excel.save();
    if (bytes == null) throw Exception('Excel save returned null');

    final dir   = await getApplicationDocumentsDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final path  = '${dir.path}/production_log_$stamp.xlsx';

    await File(path).writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(path,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      )],
      subject: 'Production Log — $stamp',
    );

    return path;
  }
}
