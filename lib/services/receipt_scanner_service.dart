import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';

import '../models/receipt_scan_result.dart';
import 'receipt_classifier.dart';
import 'receipt_parser.dart';

class ReceiptScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();
  final ReceiptParser _parser = ReceiptParser();
  final ReceiptClassifier _classifier = ReceiptClassifier();

  Future<ReceiptScanResult?> scanReceiptFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image == null) return null;
      return await _processImage(File(image.path), source: 'camera');
    } catch (e) {
      _log('camera-scan-error', {'error': e.toString()});
      return ReceiptScanResult(
        merchant: 'Unknown Merchant',
        date: DateTime.now(),
        total: 0.0,
        currency: 'PKR',
        type: 'expense',
        classificationReason: 'scan failed',
        error: 'Failed to scan from camera',
      );
    }
  }

  Future<ReceiptScanResult?> scanReceiptFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return null;
      return await _processImage(File(image.path), source: 'gallery');
    } catch (e) {
      _log('gallery-scan-error', {'error': e.toString()});
      return ReceiptScanResult(
        merchant: 'Unknown Merchant',
        date: DateTime.now(),
        total: 0.0,
        currency: 'PKR',
        type: 'expense',
        classificationReason: 'scan failed',
        error: 'Failed to scan from gallery',
      );
    }
  }

  Future<ReceiptScanResult?> scanReceiptFromPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.single.path == null) {
        return null;
      }
      final pdfFile = File(result.files.single.path!);
      final imageFile = await _renderPdfFirstPage(pdfFile);
      if (imageFile == null) {
        return ReceiptScanResult(
          merchant: 'Unknown Merchant',
          date: DateTime.now(),
          total: 0.0,
          currency: 'PKR',
          type: 'expense',
          classificationReason: 'scan failed',
          error: 'Failed to render PDF',
        );
      }
      final scan = await _processImage(
        imageFile,
        source: 'pdf',
        receiptFilePath: pdfFile.path,
      );
      return scan;
    } catch (e) {
      _log('pdf-scan-error', {'error': e.toString()});
      return ReceiptScanResult(
        merchant: 'Unknown Merchant',
        date: DateTime.now(),
        total: 0.0,
        currency: 'PKR',
        type: 'expense',
        classificationReason: 'scan failed',
        error: 'Failed to scan from PDF',
      );
    }
  }

  Future<ReceiptScanResult> _processImage(
    File imageFile, {
    required String source,
    String? receiptFilePath,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final rawText = _normalizeRecognizedText(recognizedText);

      if (rawText.isEmpty) {
        return ReceiptScanResult(
          merchant: 'Unknown Merchant',
          date: DateTime.now(),
          total: 0.0,
          currency: 'PKR',
          type: 'expense',
          classificationReason: 'no text extracted',
          rawText: rawText,
          receiptImagePath: imageFile.path,
          receiptFilePath: receiptFilePath,
          receiptSource: source,
          error: 'No text detected',
        );
      }

      final parsed = _parser.parse(rawText);
      final classification = _classifier.classify(
        rawText: rawText,
        merchant: parsed.merchant,
      );

      _log('scan-success', {
        'source': source,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'merchant': parsed.merchant,
      });

      return ReceiptScanResult(
        merchant: parsed.merchant,
        date: parsed.date,
        total: parsed.total,
        tax: parsed.tax,
        currency: parsed.currency,
        paymentMethod: parsed.paymentMethod,
        type: classification.type,
        classificationReason: classification.reason,
        rawText: rawText,
        receiptImagePath: imageFile.path,
        receiptFilePath: receiptFilePath,
        receiptSource: source,
      );
    } catch (e) {
      _log('scan-failure', {
        'source': source,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'error': e.toString(),
      });
      return ReceiptScanResult(
        merchant: 'Unknown Merchant',
        date: DateTime.now(),
        total: 0.0,
        currency: 'PKR',
        type: 'expense',
        classificationReason: 'scan failed',
        receiptImagePath: imageFile.path,
        receiptFilePath: receiptFilePath,
        receiptSource: source,
        error: 'Failed to process receipt',
      );
    }
  }

  Future<File?> _renderPdfFirstPage(File pdfFile) async {
    PdfDocument? document;
    PdfPageImage? pageImage;
    try {
      document = await PdfDocument.openFile(pdfFile.path);
      final page = await document.getPage(1);
      pageImage = await page.render(
        width: page.width.toInt(),
        height: page.height.toInt(),
      );

      final ui.Image image = await pageImage.createImageIfNotAvailable();
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'receipt_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(path.join(tempDir.path, fileName));
      await imageFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );

      return imageFile;
    } catch (e) {
      _log('pdf-render-error', {'error': e.toString()});
      return null;
    } finally {
      pageImage?.dispose();
      if (document != null) {
        await document.dispose();
      }
    }
  }

  String _normalizeRecognizedText(RecognizedText recognizedText) {
    final lines = <_OcrLine>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        final rect = line.boundingBox;
        lines.add(_OcrLine(text: text, top: rect.top, left: rect.left));
      }
    }

    if (lines.isEmpty) {
      return recognizedText.text.trim();
    }

    lines.sort((a, b) {
      final topCompare = a.top.compareTo(b.top);
      if (topCompare != 0) return topCompare;
      return a.left.compareTo(b.left);
    });

    return lines.map((line) => line.text).join('\n').trim();
  }

  void dispose() {
    _textRecognizer.close();
  }

  void _log(String event, Map<String, Object?> data) {
    final payload = data.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    // Keep logs lightweight and structured for future metric hooks.
    // ignore: avoid_print
    print('[receipt_scan][$event] $payload');
  }
}

class _OcrLine {
  final String text;
  final double top;
  final double left;

  const _OcrLine({
    required this.text,
    required this.top,
    required this.left,
  });
}


