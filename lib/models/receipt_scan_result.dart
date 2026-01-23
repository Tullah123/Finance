class ReceiptScanResult {
  final String merchant;
  final DateTime date;
  final double total;
  final double? tax;
  final String currency;
  final String? paymentMethod;
  final String type;
  final String classificationReason;
  final String? rawText;
  final String? receiptImagePath;
  final String? receiptFilePath;
  final String? receiptSource;
  final String? error;

  const ReceiptScanResult({
    required this.merchant,
    required this.date,
    required this.total,
    this.tax,
    required this.currency,
    this.paymentMethod,
    required this.type,
    required this.classificationReason,
    this.rawText,
    this.receiptImagePath,
    this.receiptFilePath,
    this.receiptSource,
    this.error,
  });

  bool get hasError => error != null && error!.isNotEmpty;
}


