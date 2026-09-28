import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../utils/app_constants.dart';

class ExportService {
  /// Partage le fichier généré (Android / iOS) ou le télécharge (navigateur).
  Future<void> _partager(String name, List<int> bytes, String mimeType, String texte) async {
    if (kIsWeb) {
      await XFile.fromData(Uint8List.fromList(bytes), name: name, mimeType: mimeType)
          .saveTo(name);
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)], text: texte);
  }

  Future<void> exportTransactionsCsv({
    required List<Transaction> transactions,
    required String devise,
  }) async {
    final rows = <List<dynamic>>[
      [
        'Date',
        'Type',
        'Categorie',
        'Montant',
        'Mode de paiement',
        'Description'
      ]
    ];

    for (final t in transactions) {
      rows.add([
        AppHelpers.formatDateFull(t.dateTransaction),
        t.type,
        t.categorie?.nom ?? 'Autre',
        t.montant,
        AppHelpers.getModeLabel(t.modePaiement),
        t.description ?? ''
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';');
    await _partager(
      'transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
      [0xEF, 0xBB, 0xBF, ...utf8.encode(csv)], // UTF-8 avec BOM (accents lisibles dans Excel)
      'text/csv',
      'Export CSV des transactions ($devise)',
    );
  }

  /// Rapport financier d'une période : synthèse, comparaison, répartition
  /// par catégorie et liste des transactions.
  Future<void> exportRapportPdf({
    required String titre,
    required String utilisateur,
    required double revenus,
    required double depenses,
    required double depensesPeriodePrecedente,
    required Map<String, double> depensesParCategorie,
    required List<Transaction> transactions,
    required List<String> recommandations,
    required String devise,
  }) async {
    String m(double v) => '${v < 0 ? '-' : ''}${AppHelpers.formatMontant(v, devise)}';
    final variation = depensesPeriodePrecedente > 0
        ? '${((depenses - depensesPeriodePrecedente) / depensesPeriodePrecedente * 100).round()} %'
        : 'n/d';
    final categories = depensesParCategorie.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (_) => pw.Text('Planify — Rapport financier',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        build: (context) => [
          pw.Text(titre, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text('$utilisateur · généré le ${AppHelpers.formatDateFull(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Revenus', 'Dépenses', 'Solde', 'Évolution des dépenses'],
            data: [
              [m(revenus), m(depenses), m(revenus - depenses), variation]
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Dépenses par catégorie',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Catégorie', 'Montant', 'Part'],
            data: categories
                .map((e) => [
                      e.key,
                      m(e.value),
                      depenses > 0 ? '${(e.value / depenses * 100).round()} %' : '-',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
          if (recommandations.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Recommandations',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ...recommandations.map((r) => pw.Bullet(text: r)),
          ],
          pw.SizedBox(height: 16),
          pw.Text('Transactions (${transactions.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Type', 'Catégorie', 'Montant', 'Mode'],
            data: transactions
                .map((t) => [
                      AppHelpers.formatDate(t.dateTransaction),
                      t.type == 'depense' ? 'Dépense' : 'Revenu',
                      t.categorie?.nom ?? 'Autre',
                      m(t.montant),
                      AppHelpers.getModeLabel(t.modePaiement),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    await _partager(
      'rapport_${DateTime.now().millisecondsSinceEpoch}.pdf',
      await doc.save(),
      'application/pdf',
      titre,
    );
  }

  Future<void> exportTransactionsPdf({
    required List<Transaction> transactions,
    required String devise,
  }) async {
    final doc = pw.Document();
    final headers = [
      'Date',
      'Type',
      'Categorie',
      'Montant',
      'Mode',
      'Description'
    ];

    final data = transactions
        .map((t) => [
              AppHelpers.formatDateFull(t.dateTransaction),
              t.type,
              t.categorie?.nom ?? 'Autre',
              '${t.montant} $devise',
              AppHelpers.getModeLabel(t.modePaiement),
              t.description ?? ''
            ])
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Export des transactions',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    await _partager(
      'transactions_${DateTime.now().millisecondsSinceEpoch}.pdf',
      await doc.save(),
      'application/pdf',
      'Export PDF des transactions ($devise)',
    );
  }
}
