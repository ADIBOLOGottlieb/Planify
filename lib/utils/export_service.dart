import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import 'app_constants.dart';

class ExportService {
  Future<File> _writeFile(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
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
    final file = await _writeFile(
      'transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
      csv.codeUnits,
    );

    await Share.shareXFiles([XFile(file.path)],
        text: 'Export CSV des transactions ($devise)');
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

    final file = await _writeFile(
      'transactions_${DateTime.now().millisecondsSinceEpoch}.pdf',
      await doc.save(),
    );

    await Share.shareXFiles([XFile(file.path)],
        text: 'Export PDF des transactions ($devise)');
  }
}
