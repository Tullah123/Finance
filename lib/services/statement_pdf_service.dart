import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/transaction.dart';

/// Generates PDF statements and manages saved statement files.
class StatementPdfService {
  // Generate a PDF statement for a selected period.
  Future<File> generateStatement({
    required List<Transaction> transactions,
    required String periodLabel,
    required String periodKey,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 2);
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Compute summary totals for the statement header.
    final income = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = income - expense;

    // Sort transactions by date for the table.
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Build the PDF document with summary and transaction table.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Text(
              'Finance Statement',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              periodLabel,
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summaryCell('Income', currency.format(income)),
                _summaryCell('Expense', currency.format(expense)),
                _summaryCell('Net', currency.format(balance)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Transactions',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (sorted.isEmpty)
              pw.Text(
                'No transactions recorded for this period.',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                ),
              )
            else
              pw.Table.fromTextArray(
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headers: const [
                  'Date',
                  'Title',
                  'Category',
                  'Type',
                  'Amount',
                ],
                data: sorted
                    .map(
                      (t) => [
                        dateFormat.format(t.date),
                        t.title,
                        t.category,
                        t.type == 'income' ? 'Income' : 'Expense',
                        currency.format(t.amount),
                      ],
                    )
                    .toList(),
              ),
          ];
        },
      ),
    );

    // Write the PDF file to the app documents/ statements folder.
    final directory = await getApplicationDocumentsDirectory();
    final statementsDir =
        Directory(path.join(directory.path, 'statements'));
    if (!await statementsDir.exists()) {
      await statementsDir.create(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'statement_${periodKey}_$timestamp.pdf';
    final file = File(path.join(statementsDir.path, fileName));
    await file.writeAsBytes(await doc.save());
    return file;
  }

  // Summary widget for header totals.
  pw.Widget _summaryCell(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Delete all saved statement PDFs.
  Future<void> deleteAllStatements() async {
    final directory = await getApplicationDocumentsDirectory();
    final statementsDir =
        Directory(path.join(directory.path, 'statements'));
    if (await statementsDir.exists()) {
      await statementsDir.delete(recursive: true);
    }
  }
}

