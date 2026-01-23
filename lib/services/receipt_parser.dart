import 'dart:math';

class ReceiptParseResult {
  final String merchant;
  final DateTime date;
  final double total;
  final double? tax;
  final String currency;
  final String? paymentMethod;

  const ReceiptParseResult({
    required this.merchant,
    required this.date,
    required this.total,
    this.tax,
    required this.currency,
    this.paymentMethod,
  });
}

class ReceiptParser {
  static const List<String> _currencyTokens = [
    'PKR',
    'Rs',
    'USD',
    'EUR',
    'GBP',
    'INR',
  ];

  static const List<String> _paymentTokens = [
    'visa',
    'mastercard',
    'amex',
    'discover',
    'debit',
    'credit',
    'cash',
    'upi',
    'paypal',
    'apple pay',
    'google pay',
    'bank transfer',
  ];

  ReceiptParseResult parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final currency = _extractCurrency(rawText);
    final merchant = _extractMerchant(lines);
    final date = _extractDate(lines) ?? DateTime.now();
    final total = _extractTotal(lines);
    final tax = _extractTax(lines);
    final paymentMethod = _extractPaymentMethod(rawText);

    return ReceiptParseResult(
      merchant: merchant,
      date: date,
      total: total,
      tax: tax,
      currency: currency,
      paymentMethod: paymentMethod,
    );
  }

  String _extractCurrency(String text) {
    for (final token in _currencyTokens) {
      if (text.toUpperCase().contains(token.toUpperCase())) {
        return token == 'Rs' ? 'PKR' : token;
      }
    }
    if (text.contains('\$')) return 'USD';
    if (text.contains('â‚¬')) return 'EUR';
    if (text.contains('Â£')) return 'GBP';
    return 'PKR';
  }

  String _extractMerchant(List<String> lines) {
    for (final line in lines.take(8)) {
      final lower = line.toLowerCase();
      if (lower.contains('total') ||
          lower.contains('subtotal') ||
          lower.contains('tax') ||
          lower.contains('receipt') ||
          lower.contains('invoice')) {
        continue;
      }
      if (RegExp(r'[a-zA-Z]').hasMatch(line) &&
          !RegExp(r'\d{3,}').hasMatch(line)) {
        return line;
      }
    }
    return lines.isNotEmpty ? lines.first : 'Unknown Merchant';
  }

  DateTime? _extractDate(List<String> lines) {
    final dateRegex = RegExp(
        r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})|(\d{2,4}[-/]\d{1,2}[-/]\d{1,2})');
    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        final dateStr = match.group(0)!;
        final parsed = _parseDate(dateStr);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  DateTime? _parseDate(String dateStr) {
    final formats = [
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{4})'),
      RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})'),
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2})'),
    ];

    for (final format in formats) {
      final match = format.firstMatch(dateStr);
      if (match == null) continue;
      try {
        int day;
        int month;
        int year;
        if (match.group(3)!.length == 4) {
          if (int.parse(match.group(1)!) > 31) {
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
          }
        } else {
          day = int.parse(match.group(1)!);
          month = int.parse(match.group(2)!);
          year = 2000 + int.parse(match.group(3)!);
        }
        return DateTime(year, month, day);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  double _extractTotal(List<String> lines) {
    final totalRegex = RegExp(
      r'(total|amount|grand total|balance due|paid)\s*[:\-]?\s*([0-9,]+(\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = totalRegex.firstMatch(line);
      if (match != null) {
        final value = _parseAmount(match.group(2)!);
        if (value != null) return value;
      }
    }

    final amounts = <double>[];
    final amountRegex = RegExp(r'([0-9,]+(\.[0-9]{1,2})?)');
    for (final line in lines) {
      for (final match in amountRegex.allMatches(line)) {
        final value = _parseAmount(match.group(1)!);
        if (value != null) amounts.add(value);
      }
    }
    if (amounts.isEmpty) return 0.0;
    return amounts.reduce(max);
  }

  double? _extractTax(List<String> lines) {
    final taxRegex = RegExp(
      r'(tax|vat|gst)\s*[:\-]?\s*([0-9,]+(\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = taxRegex.firstMatch(line);
      if (match != null) {
        return _parseAmount(match.group(2)!);
      }
    }
    return null;
  }

  String? _extractPaymentMethod(String text) {
    final lower = text.toLowerCase();
    for (final token in _paymentTokens) {
      if (lower.contains(token)) {
        return token
            .split(' ')
            .map((word) =>
                word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
            .join(' ');
      }
    }
    return null;
  }

  double? _parseAmount(String value) {
    final cleaned = value.replaceAll(',', '');
    return double.tryParse(cleaned);
  }
}


