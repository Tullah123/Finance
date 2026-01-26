import 'package:flutter/material.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:pdf_render/pdf_render_widgets.dart';

class StatementPdfViewerScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const StatementPdfViewerScreen({
    Key? key,
    required this.filePath,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfViewer(
        doc: PdfDocument.openFile(filePath),
      ),
    );
  }
}
