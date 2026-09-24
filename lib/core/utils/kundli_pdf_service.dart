// ignore_for_file: prefer_const_constructors
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/kundli_models.dart';

enum KundliPdfFormat {
  northIndian,
  southIndian,
  both,
}

const Map<String, String> _pdfPlanetAbbrev = {
  'sun': 'Su',
  'moon': 'Mo',
  'mars': 'Ma',
  'mercury': 'Me',
  'jupiter': 'Ju',
  'venus': 'Ve',
  'saturn': 'Sa',
  'rahu': 'Ra',
  'ketu': 'Ke',
  'uranus': 'Ur',
  'neptune': 'Ne',
  'pluto': 'Pl',
};

String _pdfAbbreviate(PlanetInfo p) {
  final key = (p.key.isNotEmpty ? p.key : p.name).toLowerCase();
  final short = _pdfPlanetAbbrev[key] ??
      (p.name.isNotEmpty ? p.name.substring(0, p.name.length.clamp(0, 2)) : '?');
  return p.isRetrograde ? '$short(R)' : short;
}

class KundliPdfService {
  KundliPdfService._();

  static const PdfColor goldPrimary = PdfColor.fromInt(0xFFD4AF37);
  static const PdfColor goldDark = PdfColor.fromInt(0xFF8C6B1C);
  static const PdfColor goldLight = PdfColor.fromInt(0xFFFBF6E9);
  static const PdfColor textDark = PdfColor.fromInt(0xFF1E1E24);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor borderGold = PdfColor.fromInt(0xFFE2C974);
  static const PdfColor bgLight = PdfColor.fromInt(0xFFFAFAF7);
  static const PdfColor tableHeaderBg = PdfColor.fromInt(0xFF2A2215);

  /// Generate Kundli PDF bytes based on selected format (North, South, or Both).
  static Future<Uint8List> generateKundliPdf({
    required KundliData kundli,
    required KundliPdfFormat format,
  }) async {
    final pdf = pw.Document();

    final houseMap = <int, List<String>>{};
    final rashiMap = <String, List<String>>{};
    for (final p in kundli.planets) {
      if (p.houseNumber > 0) {
        houseMap.putIfAbsent(p.houseNumber, () => []).add(_pdfAbbreviate(p));
      }
      if (p.rashiEnglish.isNotEmpty) {
        rashiMap.putIfAbsent(p.rashiEnglish, () => []).add(_pdfAbbreviate(p));
      }
    }

    final String titleStyleName;
    switch (format) {
      case KundliPdfFormat.northIndian:
        titleStyleName = 'North Indian';
      case KundliPdfFormat.southIndian:
        titleStyleName = 'South Indian';
      case KundliPdfFormat.both:
        titleStyleName = 'North & South Indian';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        footer: (pw.Context context) => _buildPdfFooter(context),
        build: (pw.Context context) {
          if (format == KundliPdfFormat.both) {
            return [
              _buildPdfHeader(titleStyleName),
              pw.SizedBox(height: 10),
              _buildPersonalDetailsSection(kundli),
              pw.SizedBox(height: 14),
              if (kundli.lagna != null) ...[
                _buildLagnaBadge(kundli.lagna!),
                pw.SizedBox(height: 14),
              ],
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'NORTH INDIAN KUNDLI CHART',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: goldDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _buildNorthIndianChartPdf(houseMap),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              _buildPlanetsTable(kundli.planets),
              // Page 2: South Indian Chart + Houses table
              pw.NewPage(),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'SOUTH INDIAN KUNDLI CHART',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: goldDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _buildSouthIndianChartPdf(
                      rashiPlanets: rashiMap,
                      ascendantRashi: kundli.lagna?.rashiEnglish,
                    ),
                  ],
                ),
              ),
              if (kundli.houses.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                _buildHousesTable(kundli.houses),
              ],
            ];
          }

          // Single chart (North or South)
          final isNorth = format == KundliPdfFormat.northIndian;
          return [
            _buildPdfHeader(titleStyleName),
            pw.SizedBox(height: 10),
            _buildPersonalDetailsSection(kundli),
            pw.SizedBox(height: 14),
            if (kundli.lagna != null) ...[
              _buildLagnaBadge(kundli.lagna!),
              pw.SizedBox(height: 14),
            ],
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    isNorth ? 'NORTH INDIAN KUNDLI CHART' : 'SOUTH INDIAN KUNDLI CHART',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: goldDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  isNorth
                      ? _buildNorthIndianChartPdf(houseMap)
                      : _buildSouthIndianChartPdf(
                          rashiPlanets: rashiMap,
                          ascendantRashi: kundli.lagna?.rashiEnglish,
                        ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            _buildPlanetsTable(kundli.planets),
            if (kundli.houses.isNotEmpty) ...[
              pw.NewPage(),
              pw.SizedBox(height: 10),
              _buildHousesTable(kundli.houses),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfHeader(String styleTitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: goldPrimary, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ASTROMITRA',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: goldDark,
                  letterSpacing: 1.5,
                ),
              ),
              pw.Text(
                'Vedic Astrology Kundli Report - $styleTitle',
                style: pw.TextStyle(fontSize: 9.5, color: textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: borderGold, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by AstroMitra - Vedic Horoscope & Astrology',
            style: pw.TextStyle(fontSize: 8.5, color: textMuted),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8.5, color: textMuted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPersonalDetailsSection(KundliData kundli) {
    final details = kundli.birthDetails;
    final locationStr = kundli.location?.displayString ?? details.birthPlace;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderGold, width: 0.8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Name', details.name.isEmpty ? '-' : details.name),
                pw.SizedBox(height: 4),
                _buildInfoRow('Date of Birth', details.dateOfBirth.isEmpty ? '-' : details.dateOfBirth),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Time of Birth', details.timeOfBirth ?? 'Not provided'),
                pw.SizedBox(height: 4),
                _buildInfoRow('Place of Birth', locationStr.isEmpty ? '-' : locationStr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 75,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: textMuted),
          ),
        ),
        pw.Text(': ', style: pw.TextStyle(fontSize: 9, color: textMuted)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLagnaBadge(LagnaInfo lagna) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: goldLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: goldPrimary, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text('ASCENDANT / LAGNA', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
              pw.SizedBox(height: 2),
              pw.Text(
                lagna.rashi.isNotEmpty ? lagna.rashi : lagna.rashiEnglish,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: goldDark),
              ),
            ],
          ),
          pw.Container(width: 1, height: 22, color: borderGold),
          pw.Column(
            children: [
              pw.Text('DEGREE', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
              pw.SizedBox(height: 2),
              pw.Text(
                '${lagna.degreeInRashi.toStringAsFixed(2)} deg',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
              ),
            ],
          ),
          pw.Container(width: 1, height: 22, color: borderGold),
          pw.Column(
            children: [
              pw.Text('NAKSHATRA', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
              pw.SizedBox(height: 2),
              pw.Text(
                '${lagna.nakshatra} (Pada ${lagna.pada})',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
              ),
            ],
          ),
          if (lagna.rashiLord.isNotEmpty) ...[
            pw.Container(width: 1, height: 22, color: borderGold),
            pw.Column(
              children: [
                pw.Text('RASHI LORD', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                pw.SizedBox(height: 2),
                pw.Text(
                  lagna.rashiLord,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// North Indian Diamond Chart for PDF
  static pw.Widget _buildNorthIndianChartPdf(Map<int, List<String>> housePlanets) {
    const double side = 240.0;

    const Map<int, List<double>> centroids = {
      1: [0.50, 0.25],
      2: [0.75, 0.12],
      3: [0.88, 0.25],
      4: [0.75, 0.50],
      5: [0.88, 0.75],
      6: [0.75, 0.88],
      7: [0.50, 0.75],
      8: [0.25, 0.88],
      9: [0.12, 0.75],
      10: [0.25, 0.50],
      11: [0.12, 0.25],
      12: [0.25, 0.12],
    };

    return pw.Container(
      width: side,
      height: side,
      decoration: const pw.BoxDecoration(
        color: bgLight,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.CustomPaint(
              size: const PdfPoint(side, side),
              painter: (PdfGraphics canvas, PdfPoint size) {
                canvas.setColor(goldPrimary);
                canvas.setLineWidth(1.2);

                // Outer rect
                canvas.drawRect(0, 0, size.x, size.y);
                canvas.strokePath();

                // Diagonals
                canvas.drawLine(0, 0, size.x, size.y);
                canvas.strokePath();
                canvas.drawLine(size.x, 0, 0, size.y);
                canvas.strokePath();

                // Midpoint diamond
                canvas.drawLine(size.x / 2, 0, size.x, size.y / 2);
                canvas.strokePath();
                canvas.drawLine(size.x, size.y / 2, size.x / 2, size.y);
                canvas.strokePath();
                canvas.drawLine(size.x / 2, size.y, 0, size.y / 2);
                canvas.strokePath();
                canvas.drawLine(0, size.y / 2, size.x / 2, 0);
                canvas.strokePath();
              },
            ),
          ),
          for (final entry in centroids.entries) ...[
            pw.Positioned(
              left: entry.value[0] * side - 24,
              top: entry.value[1] * side - 16,
              child: pw.SizedBox(
                width: 48,
                height: 32,
                child: pw.Center(
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      if (entry.key == 1)
                        pw.Text(
                          'Asc',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: goldDark,
                          ),
                        ),
                      pw.Wrap(
                        alignment: pw.WrapAlignment.center,
                        spacing: 2,
                        runSpacing: 1,
                        children: [
                          for (final p in (housePlanets[entry.key] ?? const <String>[]))
                            pw.Text(
                              p,
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// South Indian 4x4 Grid Chart for PDF
  static pw.Widget _buildSouthIndianChartPdf({
    required Map<String, List<String>> rashiPlanets,
    String? ascendantRashi,
  }) {
    const double side = 240.0;
    const double cell = side / 4;

    const Map<String, List<int>> pos = {
      'Pisces': [0, 0],
      'Aries': [0, 1],
      'Taurus': [0, 2],
      'Gemini': [0, 3],
      'Cancer': [1, 3],
      'Leo': [2, 3],
      'Virgo': [3, 3],
      'Libra': [3, 2],
      'Scorpio': [3, 1],
      'Sagittarius': [3, 0],
      'Capricorn': [2, 0],
      'Aquarius': [1, 0],
    };

    const List<String> signs = [
      'Pisces', 'Aries', 'Taurus', 'Gemini',
      'Cancer', 'Leo', 'Virgo', 'Libra',
      'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius'
    ];

    return pw.Container(
      width: side,
      height: side,
      decoration: pw.BoxDecoration(
        color: bgLight,
        border: pw.Border.all(color: goldPrimary, width: 1.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Stack(
        children: [
          // Cell borders
          for (var row = 0; row < 4; row++)
            for (var col = 0; col < 4; col++)
              if (!(row > 0 && row < 3 && col > 0 && col < 3))
                pw.Positioned(
                  left: col * cell,
                  top: row * cell,
                  child: pw.Container(
                    width: cell,
                    height: cell,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderGold, width: 0.6),
                    ),
                  ),
                ),
          // Sign content
          for (final sign in signs) ...[
            _buildSouthIndianCell(
              sign: sign,
              row: pos[sign]![0],
              col: pos[sign]![1],
              cell: cell,
              planets: rashiPlanets[sign] ?? const [],
              isAscendant: sign.toLowerCase() == (ascendantRashi ?? '').toLowerCase(),
            ),
          ],
          // Center box
          pw.Positioned(
            left: cell,
            top: cell,
            child: pw.SizedBox(
              width: cell * 2,
              height: cell * 2,
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'ASTROMITRA',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: goldDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'South Indian Kundli',
                      style: pw.TextStyle(fontSize: 7.5, color: textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSouthIndianCell({
    required String sign,
    required int row,
    required int col,
    required double cell,
    required List<String> planets,
    required bool isAscendant,
  }) {
    return pw.Positioned(
      left: col * cell,
      top: row * cell,
      child: pw.Container(
        width: cell,
        height: cell,
        padding: const pw.EdgeInsets.all(3),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              sign,
              style: pw.TextStyle(fontSize: 6.5, color: textMuted),
            ),
            pw.Spacer(),
            if (isAscendant)
              pw.Text(
                'Asc',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: goldDark,
                ),
              ),
            pw.Wrap(
              alignment: pw.WrapAlignment.center,
              spacing: 2,
              runSpacing: 1,
              children: [
                for (final p in planets)
                  pw.Text(
                    p,
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: textDark,
                    ),
                  ),
              ],
            ),
            pw.Spacer(),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPlanetsTable(List<PlanetInfo> planets) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PLANETARY POSITIONS',
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: goldDark,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: borderGold, width: 0.6),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: tableHeaderBg),
              children: [
                _tableHeaderCell('Planet'),
                _tableHeaderCell('Sign (Rashi)'),
                _tableHeaderCell('Degree'),
                _tableHeaderCell('House'),
                _tableHeaderCell('Nakshatra'),
                _tableHeaderCell('Status'),
              ],
            ),
            for (final p in planets)
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: planets.indexOf(p).isEven ? bgLight : PdfColors.white,
                ),
                children: [
                  _tableDataCell(p.name.isNotEmpty ? p.name : p.key, isBold: true),
                  _tableDataCell('${p.rashiEnglish}${p.rashi.isNotEmpty && p.rashi != p.rashiEnglish ? ' (${p.rashi})' : ''}'),
                  _tableDataCell('${p.degreeInRashi.toStringAsFixed(2)} deg'),
                  _tableDataCell(p.houseNumber > 0 ? '${p.houseNumber}' : '-'),
                  _tableDataCell('${p.nakshatra}${p.pada > 0 ? ' (P${p.pada})' : ''}'),
                  _tableDataCell(p.isRetrograde ? 'Retrograde (R)' : 'Direct'),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildHousesTable(List<HouseInfo> houses) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'HOUSES & BHAVAS',
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: goldDark,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: borderGold, width: 0.6),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: tableHeaderBg),
              children: [
                _tableHeaderCell('House'),
                _tableHeaderCell('Sign (Rashi)'),
                _tableHeaderCell('Sign Lord'),
              ],
            ),
            for (final h in houses)
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: houses.indexOf(h).isEven ? bgLight : PdfColors.white,
                ),
                children: [
                  _tableDataCell('House ${h.houseNumber}', isBold: true),
                  _tableDataCell('${h.rashiEnglish}${h.rashi.isNotEmpty && h.rashi != h.rashiEnglish ? ' (${h.rashi})' : ''}'),
                  _tableDataCell(h.rashiLord.isNotEmpty ? h.rashiLord : '-'),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: goldLight,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableDataCell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: textDark,
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Download Kundli PDF directly to the user's phone for specified format.
  static Future<void> handleKundliDownload(
    BuildContext context, {
    required KundliData kundli,
    required KundliPdfFormat format,
  }) async {
    final String formatSuffix;
    switch (format) {
      case KundliPdfFormat.northIndian:
        formatSuffix = 'North_Indian';
      case KundliPdfFormat.southIndian:
        formatSuffix = 'South_Indian';
      case KundliPdfFormat.both:
        formatSuffix = 'Both_North_South';
    }

    final personName = kundli.birthDetails.name.trim().isNotEmpty
        ? kundli.birthDetails.name.trim().replaceAll(RegExp(r'\s+'), '_')
        : 'Kundli';
    final fileName = 'AstroMitra_${personName}_$formatSuffix.pdf';

    try {
      final pdfBytes = await generateKundliPdf(
        kundli: kundli,
        format: format,
      );

      // Save file locally to device Downloads or Documents directory
      try {
        Directory? targetDir;
        if (Platform.isAndroid) {
          targetDir = Directory('/storage/emulated/0/Download');
          if (!targetDir.existsSync()) {
            targetDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
          }
        } else {
          targetDir = await getApplicationDocumentsDirectory();
        }

        final file = File('${targetDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes, flush: true);
      } catch (_) {
        final targetDir = await getApplicationDocumentsDirectory();
        final file = File('${targetDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes, flush: true);
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1A12),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PDF Downloaded Successfully',
                      style: TextStyle(
                        color: Color(0xFFF3D47A),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Saved to: $fileName',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Show the bottom sheet dialog allowing the user to pick North Indian, South Indian, or Both.
  static void showDownloadFormatPicker(
    BuildContext context, {
    required KundliData kundli,
    required int currentActiveTab, // 0 for North, 1 for South
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16141F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD4AF37), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Download Kundli PDF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Select chart format to download',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _FormatOptionTile(
                  title: 'North Indian Chart',
                  subtitle: 'Traditional diamond chart format',
                  icon: Icons.auto_awesome_rounded,
                  isRecommended: currentActiveTab == 0,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    handleKundliDownload(
                      context,
                      kundli: kundli,
                      format: KundliPdfFormat.northIndian,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _FormatOptionTile(
                  title: 'South Indian Chart',
                  subtitle: 'Traditional 12-house grid format',
                  icon: Icons.grid_view_rounded,
                  isRecommended: currentActiveTab == 1,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    handleKundliDownload(
                      context,
                      kundli: kundli,
                      format: KundliPdfFormat.southIndian,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _FormatOptionTile(
                  title: 'Both (North & South Indian)',
                  subtitle: 'Complete report with both charts in one PDF',
                  icon: Icons.file_copy_rounded,
                  badgeText: 'COMPLETE',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    handleKundliDownload(
                      context,
                      kundli: kundli,
                      format: KundliPdfFormat.both,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FormatOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isRecommended;
  final String? badgeText;

  const _FormatOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isRecommended = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF221F2C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRecommended
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.6)
                  : const Color(0xFF353043),
              width: isRecommended ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isRecommended
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                      : const Color(0xFF2C273A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isRecommended ? const Color(0xFFF3D47A) : Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText!,
                              style: const TextStyle(
                                color: Color(0xFFF3D47A),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
