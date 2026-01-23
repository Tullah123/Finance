/*
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ReceiptScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  // Scan receipt from camera
  Future<Map<String, dynamic>?> scanReceiptFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;
      return await _processReceipt(File(image.path));
    } catch (e) {
      print('Error scanning from camera: $e');
      return null;
    }
  }

  // Scan receipt from gallery
  Future<Map<String, dynamic>?> scanReceiptFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;
      return await _processReceipt(File(image.path));
    } catch (e) {
      print('Error scanning from gallery: $e');
      return null;
    }
  }

  // Process receipt image and extract data
  Future<Map<String, dynamic>> _processReceipt(File imageFile) async {
    try {
      // Save image permanently
      final savedImagePath = await _saveReceiptImage(imageFile);

      // Perform OCR
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // Extract data from text
      final extractedData = _extractReceiptData(recognizedText.text);

      return {
        'imagePath': savedImagePath,
        'extractedText': recognizedText.text,
        'amount': extractedData['amount'],
        'date': extractedData['date'],
        'merchant': extractedData['merchant'],
        'items': extractedData['items'],
      };
    } catch (e) {
      print('Error processing receipt: $e');
      return {};
    }
  }

  // Save receipt image to permanent storage
  Future<String> _saveReceiptImage(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${directory.path}/receipts');

      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${receiptsDir.path}/$fileName');

      await imageFile.copy(savedImage.path);
      return savedImage.path;
    } catch (e) {
      print('Error saving receipt image: $e');
      return '';
    }
  }

  // Extract receipt data from OCR text
  Map<String, dynamic> _extractReceiptData(String text) {
    final lines = text.split('\n');
    double? amount;
    DateTime? date;
    String? merchant;
    List<String> items = [];

    // Extract amount (look for currency symbols and numbers)
    final amountRegex = RegExp(
        r'(?:PKR|Rs\.?|₨)\s*(\d+(?:,\d{3})*(?:\.\d{2})?)|(?:Total|Amount|TOTAL|AMOUNT)[\s:]*(\d+(?:,\d{3})*(?:\.\d{2})?)',
        caseSensitive: false);

    for (final line in lines) {
      final match = amountRegex.firstMatch(line);
      if (match != null) {
        String? amountStr = match.group(1) ?? match.group(2);
        if (amountStr != null) {
          amountStr = amountStr.replaceAll(',', '');
          amount = double.tryParse(amountStr);
          if (amount != null) break;
        }
      }
    }

    // Extract date
    final dateRegex = RegExp(
        r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})|(\d{2,4}[-/]\d{1,2}[-/]\d{1,2})');
    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        try {
          final dateStr = match.group(0)!;
          // Try different date formats
          date = _parseDate(dateStr);
          if (date != null) break;
        } catch (e) {
          continue;
        }
      }
    }

    // Extract merchant (usually first line with text)
    if (lines.isNotEmpty) {
      for (final line in lines.take(5)) {
        if (line.trim().length > 3 && !line.contains(RegExp(r'\d{4}'))) {
          merchant = line.trim();
          break;
        }
      }
    }

    // Extract items (lines with products)
    for (final line in lines) {
      if (line.length > 5 &&
          !line.toLowerCase().contains('total') &&
          !line.toLowerCase().contains('subtotal') &&
          !dateRegex.hasMatch(line)) {
        items.add(line.trim());
      }
    }

    return {
      'amount': amount,
      'date': date ?? DateTime.now(),
      'merchant': merchant ?? 'Unknown Merchant',
      'items': items.take(10).toList(), // Limit to 10 items
    };
  }

  // Parse date from various formats
  DateTime? _parseDate(String dateStr) {
    final formats = [
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{4})'), // DD-MM-YYYY or MM-DD-YYYY
      RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})'), // YYYY-MM-DD
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2})'), // DD-MM-YY or MM-DD-YY
    ];

    for (final format in formats) {
      final match = format.firstMatch(dateStr);
      if (match != null) {
        try {
          int day, month, year;

          if (match.group(3)!.length == 4) {
            // DD-MM-YYYY or YYYY-MM-DD
            if (int.parse(match.group(1)!) > 31) {
              // YYYY-MM-DD
              year = int.parse(match.group(1)!);
              month = int.parse(match.group(2)!);
              day = int.parse(match.group(3)!);
            } else {
              // DD-MM-YYYY
              day = int.parse(match.group(1)!);
              month = int.parse(match.group(2)!);
              year = int.parse(match.group(3)!);
            }
          } else {
            // DD-MM-YY
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = 2000 + int.parse(match.group(3)!);
          }

          return DateTime(year, month, day);
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  // Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}
*/
