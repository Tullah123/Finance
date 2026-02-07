import 'dart:math';

/// Parsed fields from raw OCR text.
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

/// Heuristic parser for extracting receipt fields from OCR text.
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

  static final RegExp _numericDateRegex = RegExp(
    r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})|(\d{2,4}[-/]\d{1,2}[-/]\d{1,2})',
  );

  static final RegExp _monthNameRegex = RegExp(
    r'\b(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\b',
    caseSensitive: false,
  );

  static final RegExp _amountTokenRegex = RegExp(
    r'(?<!\d)(?:[0-9OolI][0-9OolI\s,\.]*[0-9OolI]|[0-9OolI])(?:[.,]\d{1,2})?(?!\d)',
  );

  static final RegExp _totalStrongRegex = RegExp(
    r'\b(grand\s*tot(?:al|ai|a1)|tot(?:al|ai|a1)|total\s*due|amount\s*due|balance\s*due|amount\s*payable|net\s*tot(?:al|ai|a1)|total\s*amount)\b',
    caseSensitive: false,
  );

  static final RegExp _totalWeakRegex = RegExp(
    r'\b(amount|paid|tendered|balance)\b',
    caseSensitive: false,
  );

  static final RegExp _totalExcludeRegex = RegExp(
    r'\b(subtotal|sub total|tax|vat|gst|discount|change|cash back|cashback|rounding|tip|gratuity|service charge|delivery|shipping|fee|charge)\b',
    caseSensitive: false,
  );

  static final RegExp _metaLineRegex = RegExp(
    r'\b(tel|phone|fax|invoice|order|receipt|ref|reference|auth|approval|transaction|card|terminal|pos|cashier|table|guest|vat no|tax id|gstin|tin|ntn|www|http|email)\b',
    caseSensitive: false,
  );

  static final RegExp _merchantLabelRegex = RegExp(
    r'\b(sent\s*to|paid\s*to|pay\s*to|receiver|recipient|beneficiary|account\s*details|account\s*name|received\s*from|from)\b',
    caseSensitive: false,
  );

  static final RegExp _merchantExcludeRegex = RegExp(
    r'\b(transaction successful|funding source|sent by|fee|charge|total amount|amount|id#|transaction id|reference|receipt)\b',
    caseSensitive: false,
  );

  static final RegExp _taxRegex = RegExp(
    r'\b(tax|vat|gst|cgst|sgst|igst|sales tax)\b',
    caseSensitive: false,
  );

  static final RegExp _currencyLineRegex = RegExp(
    r'\b(r\s*s\.?|rs\.?|pkr|rupees)\b',
    caseSensitive: false,
  );

  static final RegExp _amountLabelRegex = RegExp(
    r'\b(total\s*amount|amount\s*paid|amount\s*due|amount|sent|received|debited|credited)\b',
    caseSensitive: false,
  );

  static final RegExp _time24Regex = RegExp(
    r'\b([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b',
  );

  static final RegExp _time12Regex = RegExp(
    r'\b(1[0-2]|0?[1-9]):([0-5]\d)(?::([0-5]\d))?\s*([ap]m)\b',
    caseSensitive: false,
  );

  static final RegExp _time12ShortRegex = RegExp(
    r'\b(1[0-2]|0?[1-9])\s*([ap]m)\b',
    caseSensitive: false,
  );

  // Main entry: parse merchant, date/time, totals, tax, currency, and payment.
  ReceiptParseResult parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final currency = _extractCurrency(rawText);
    final merchant = _extractMerchant(lines);
    final date = _extractDate(lines);
    final time = _extractTime(lines);
    final resolvedDate = _combineDateTime(date, time);
    final tax = _extractTax(lines);
    final total = _extractTotal(lines, tax: tax);
    final paymentMethod = _extractPaymentMethod(rawText);

    return ReceiptParseResult(
      merchant: merchant,
      date: resolvedDate,
      total: total,
      tax: tax,
      currency: currency,
      paymentMethod: paymentMethod,
    );
  }

  // Detect currency token or symbol.
  String _extractCurrency(String text) {
    final upper = text.toUpperCase();
    if (RegExp(r'\bR\s*S\.?\b', caseSensitive: false).hasMatch(text)) {
      return 'PKR';
    }
    for (final token in _currencyTokens) {
      if (token == 'Rs') continue;
      if (upper.contains(token.toUpperCase())) {
        return token;
      }
    }
    if (text.contains(r'$')) return 'USD';
    if (text.contains('\u20AC')) return 'EUR';
    if (text.contains('\u00A3')) return 'GBP';
    if (text.contains('\u20B9')) return 'INR';
    return 'PKR';
  }

  // Guess merchant name from header lines and labels.
  String _extractMerchant(List<String> lines) {
    if (lines.isEmpty) return 'Unknown Merchant';
    final labeled = _extractMerchantFromLabels(lines);
    if (labeled != null && labeled.isNotEmpty) {
      return labeled;
    }

    final maxLines = min(lines.length, 12);
    String bestLine = lines.first;
    int bestScore = -9999;

    for (var i = 0; i < maxLines; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('total') ||
          lower.contains('subtotal') ||
          lower.contains('tax') ||
          lower.contains('receipt') ||
          lower.contains('invoice')) {
        // Still consider, but with penalty.
      }
      final letterCount = RegExp(r'[A-Za-z]').allMatches(line).length;
      final digitCount = RegExp(r'\d').allMatches(line).length;
      final hasUrl = lower.contains('www') || lower.contains('http');
      final hasContact = lower.contains('tel') || lower.contains('phone');
      int score = (letterCount * 2) - (digitCount * 2);
      if (i == 0) score += 5;
      if (line.length > 40) score -= 4;
      if (_metaLineRegex.hasMatch(lower)) score -= 12;
      if (_totalExcludeRegex.hasMatch(lower)) score -= 8;
      if (_merchantExcludeRegex.hasMatch(lower)) score -= 20;
      if (hasUrl) score -= 10;
      if (hasContact) score -= 10;

      if (score > bestScore) {
        bestScore = score;
        bestLine = line;
      }
    }

    return bestLine.isNotEmpty ? bestLine : 'Unknown Merchant';
  }

  String? _extractMerchantFromLabels(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      final keywordLine = _normalizeForKeywords(lower);
      if (!_merchantLabelRegex.hasMatch(keywordLine)) continue;

      final inline = _extractInlineLabelValue(line, lower);
      if (inline != null && _isCandidateNameLine(inline)) {
        return inline;
      }

      for (var j = i + 1; j < min(lines.length, i + 4); j++) {
        final candidate = lines[j].trim();
        if (_isCandidateNameLine(candidate)) {
          return candidate;
        }
      }
    }
    return null;
  }

  String? _extractInlineLabelValue(String line, String lower) {
    final match = _merchantLabelRegex.firstMatch(lower);
    if (match == null) return null;
    final label = match.group(0)!;
    final start = lower.indexOf(label);
    if (start < 0) return null;
    var remainder = line.substring(start + label.length).trim();
    if (remainder.startsWith(':') || remainder.startsWith('-')) {
      remainder = remainder.substring(1).trim();
    }
    return remainder.isEmpty ? null : remainder;
  }

  bool _isCandidateNameLine(String line) {
    if (line.isEmpty) return false;
    final lower = line.toLowerCase();
    if (!RegExp(r'[A-Za-z]').hasMatch(line)) return false;
    if (_metaLineRegex.hasMatch(lower)) return false;
    if (_merchantExcludeRegex.hasMatch(lower)) return false;
    if (_totalExcludeRegex.hasMatch(lower)) return false;
    if (RegExp(r'\d{7,}').hasMatch(line) &&
        RegExp(r'[A-Za-z]').allMatches(line).length < 3) {
      return false;
    }
    return true;
  }

  // Find a plausible date in OCR lines.
  DateTime? _extractDate(List<String> lines) {
    for (final line in lines) {
      final numericMatch = _numericDateRegex.firstMatch(line);
      if (numericMatch != null) {
        final dateStr = numericMatch.group(0)!;
        final parsed = _parseDate(dateStr);
        if (parsed != null) return parsed;
      }

      if (_monthNameRegex.hasMatch(line)) {
        final parsed = _parseMonthNameDate(line);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  // Find a plausible time in OCR lines.
  _ParsedTime? _extractTime(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      final hasDate =
          _numericDateRegex.hasMatch(line) || _monthNameRegex.hasMatch(line);
      if (!hasDate) continue;

      final match12 = _time12Regex.firstMatch(lower);
      if (match12 != null) {
        final hour = int.tryParse(match12.group(1) ?? '');
        final minute = int.tryParse(match12.group(2) ?? '');
        final second = int.tryParse(match12.group(3) ?? '0') ?? 0;
        final meridiem = match12.group(4) ?? '';
        if (hour == null || minute == null) continue;
        final isPm = meridiem.startsWith('p');
        final normalizedHour = (hour % 12) + (isPm ? 12 : 0);
        return _ParsedTime(
          hour: normalizedHour,
          minute: minute,
          second: second,
        );
      }

      final match24 = _time24Regex.firstMatch(line);
      if (match24 != null) {
        final hour = int.tryParse(match24.group(1) ?? '');
        final minute = int.tryParse(match24.group(2) ?? '');
        final second = int.tryParse(match24.group(3) ?? '0') ?? 0;
        if (hour == null || minute == null) continue;
        return _ParsedTime(hour: hour, minute: minute, second: second);
      }
    }

    for (final line in lines) {
      final lower = line.toLowerCase();
      final match12 = _time12Regex.firstMatch(lower);
      if (match12 != null) {
        final hour = int.tryParse(match12.group(1) ?? '');
        final minute = int.tryParse(match12.group(2) ?? '');
        final second = int.tryParse(match12.group(3) ?? '0') ?? 0;
        final meridiem = match12.group(4) ?? '';
        if (hour == null || minute == null) continue;
        final isPm = meridiem.startsWith('p');
        final normalizedHour =
            (hour % 12) + (isPm ? 12 : 0);
        return _ParsedTime(
          hour: normalizedHour,
          minute: minute,
          second: second,
        );
      }
    }

    for (final line in lines) {
      final match24 = _time24Regex.firstMatch(line);
      if (match24 != null) {
        final hour = int.tryParse(match24.group(1) ?? '');
        final minute = int.tryParse(match24.group(2) ?? '');
        final second = int.tryParse(match24.group(3) ?? '0') ?? 0;
        if (hour == null || minute == null) continue;
        return _ParsedTime(hour: hour, minute: minute, second: second);
      }
    }

    for (final line in lines) {
      final lower = line.toLowerCase();
      final matchShort = _time12ShortRegex.firstMatch(lower);
      if (matchShort != null) {
        final hour = int.tryParse(matchShort.group(1) ?? '');
        final meridiem = matchShort.group(2) ?? '';
        if (hour == null) continue;
        final isPm = meridiem.startsWith('p');
        final normalizedHour =
            (hour % 12) + (isPm ? 12 : 0);
        return _ParsedTime(hour: normalizedHour, minute: 0, second: 0);
      }
    }

    return null;
  }

  // Combine date and time when both are available.
  DateTime _combineDateTime(DateTime? date, _ParsedTime? time) {
    final base = date ?? DateTime.now();
    if (time == null) return date ?? base;
    return DateTime(
      base.year,
      base.month,
      base.day,
      time.hour,
      time.minute,
      time.second,
    );
  }

  DateTime? _parseMonthNameDate(String line) {
    final normalized = line.replaceAll(RegExp(r'[\-/,]'), ' ');
    final pattern1 = RegExp(
      r'\b(\d{1,2})\s*(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\s*(\d{2,4})\b',
      caseSensitive: false,
    );
    final pattern2 = RegExp(
      r'\b(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\s*(\d{1,2})[,]?\s*(\d{2,4})\b',
      caseSensitive: false,
    );

    RegExpMatch? match = pattern1.firstMatch(normalized);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final month = _monthNumber(match.group(2));
      final year = _normalizeYear(match.group(3));
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    match = pattern2.firstMatch(normalized);
    if (match != null) {
      final month = _monthNumber(match.group(1));
      final day = int.tryParse(match.group(2) ?? '');
      final year = _normalizeYear(match.group(3));
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  int? _monthNumber(String? token) {
    if (token == null) return null;
    switch (token.toLowerCase()) {
      case 'jan':
      case 'january':
        return 1;
      case 'feb':
      case 'february':
        return 2;
      case 'mar':
      case 'march':
        return 3;
      case 'apr':
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'jun':
      case 'june':
        return 6;
      case 'jul':
      case 'july':
        return 7;
      case 'aug':
      case 'august':
        return 8;
      case 'sep':
      case 'sept':
      case 'september':
        return 9;
      case 'oct':
      case 'october':
        return 10;
      case 'nov':
      case 'november':
        return 11;
      case 'dec':
      case 'december':
        return 12;
    }
    return null;
  }

  int? _normalizeYear(String? yearToken) {
    if (yearToken == null) return null;
    final year = int.tryParse(yearToken);
    if (year == null) return null;
    if (yearToken.length == 2) {
      return 2000 + year;
    }
    return year;
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

  // Pick the most likely total amount.
  double _extractTotal(List<String> lines, {double? tax}) {
    final candidates = _collectAmountCandidates(lines);
    if (candidates.isEmpty) return 0.0;

    final filtered = tax == null
        ? candidates
        : candidates.where((c) => c.value > tax).toList();
    final pool = filtered.isEmpty ? candidates : filtered;

    final strong = pool.where((c) => c.isStrongTotal).toList();
    if (strong.isNotEmpty) {
      _sortCandidates(strong);
      return strong.first.value;
    }

    final weak = pool.where((c) => c.isWeakTotal || c.hasAmountLabel).toList();
    if (weak.isNotEmpty) {
      _sortCandidates(weak);
      return weak.first.value;
    }

    _sortCandidates(pool);
    return pool.first.value;
  }

  void _sortCandidates(List<_AmountCandidate> candidates) {
    candidates.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      final valueCompare = b.value.compareTo(a.value);
      if (valueCompare != 0) return valueCompare;
      return b.lineIndex.compareTo(a.lineIndex);
    });
  }

  // Extract tax/VAT/GST line if present.
  double? _extractTax(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (!_taxRegex.hasMatch(lower)) continue;
      if (_metaLineRegex.hasMatch(lower)) continue;

      final amounts = _extractAmountsFromLine(line);
      if (amounts.isNotEmpty) return amounts.last;

      if (i + 1 < lines.length) {
        final nextAmounts = _extractAmountsFromLine(lines[i + 1]);
        if (nextAmounts.isNotEmpty) return nextAmounts.first;
      }
    }
    return null;
  }

  // Extract payment method keywords.
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

  // Collect candidate amounts with heuristic scoring.
  List<_AmountCandidate> _collectAmountCandidates(List<String> lines) {
    final candidates = <_AmountCandidate>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      final keywordLine = _normalizeForKeywords(lower);
      if (_lineLooksLikeDateOnly(line, lower) &&
          !_totalStrongRegex.hasMatch(keywordLine)) {
        continue;
      }
      if (_metaLineRegex.hasMatch(lower) &&
          !_totalStrongRegex.hasMatch(keywordLine)) {
        continue;
      }

      final lineScore =
          _scoreAmountLine(line, lower, keywordLine, i, lines.length);
      var amounts = _extractAmountsFromLine(line);

      final isStrongTotal = _totalStrongRegex.hasMatch(keywordLine) &&
          !_totalExcludeRegex.hasMatch(keywordLine);
      final isWeakTotal = _totalWeakRegex.hasMatch(keywordLine);
      final hasAmountLabel = _amountLabelRegex.hasMatch(keywordLine);
      final hasCurrency =
          _currencyLineRegex.hasMatch(keywordLine) || _containsCurrencySymbol(line);
      final looksLikePhone = _lineLooksLikePhoneNumber(line);

      if (looksLikePhone && !isStrongTotal && !hasAmountLabel && !hasCurrency) {
        continue;
      }

      if (amounts.isEmpty &&
          (isStrongTotal || hasAmountLabel || hasCurrency) &&
          i + 1 < lines.length) {
        final nextLine = lines[i + 1];
        final nextAmounts = _extractAmountsFromLine(nextLine);
        final boost = isStrongTotal
            ? 40
            : hasAmountLabel
                ? 25
                : 15;
        for (final value in nextAmounts) {
          if (value <= 0) continue;
          candidates.add(_AmountCandidate(
            value: value,
            lineIndex: i + 1,
            score: lineScore + boost,
            isStrongTotal: isStrongTotal,
            isWeakTotal: isWeakTotal,
            hasAmountLabel: hasAmountLabel,
            hasCurrency: hasCurrency,
          ));
        }
        continue;
      }

      if (amounts.isNotEmpty && isStrongTotal) {
        amounts = [amounts.last];
      }

      for (final value in amounts) {
        if (value <= 0) continue;
        candidates.add(_AmountCandidate(
          value: value,
          lineIndex: i,
          score: lineScore +
              (isStrongTotal ? 30 : 0) +
              (isWeakTotal ? 12 : 0) +
              (hasAmountLabel ? 8 : 0) +
              (hasCurrency ? 8 : 0),
          isStrongTotal: isStrongTotal,
          isWeakTotal: isWeakTotal,
          hasAmountLabel: hasAmountLabel,
          hasCurrency: hasCurrency,
        ));
      }
    }

    return candidates;
  }

  // Score a line based on total/tax keywords and position.
  int _scoreAmountLine(
    String line,
    String lower,
    String keywordLine,
    int index,
    int totalLines,
  ) {
    var score = 0;
    if (_totalStrongRegex.hasMatch(keywordLine) &&
        !_totalExcludeRegex.hasMatch(keywordLine)) {
      score += 60;
    }
    if (_totalWeakRegex.hasMatch(keywordLine)) score += 15;
    if (_totalExcludeRegex.hasMatch(keywordLine)) score -= 25;
    if (_metaLineRegex.hasMatch(lower)) score -= 25;
    if (_lineLooksLikeDateOnly(line, lower)) score -= 20;
    if (_lineLooksLikePhoneNumber(line)) score -= 25;

    if (totalLines > 1) {
      final position = index / (totalLines - 1);
      score += (position * 16).round();
    }

    return score;
  }

  bool _containsCurrencySymbol(String line) {
    return line.contains(r'$') ||
        line.contains('\u20AC') ||
        line.contains('\u00A3') ||
        line.contains('\u20B9') ||
        line.contains('\u20A8');
  }

  bool _lineLooksLikeDateOnly(String line, String lower) {
    if (lower.contains('date') || lower.contains('time')) return true;
    if (_numericDateRegex.hasMatch(line)) return true;
    if (_monthNameRegex.hasMatch(line)) return true;
    return false;
  }

  bool _lineLooksLikePhoneNumber(String line) {
    final digits = line.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10 && digits.length <= 13) {
      return true;
    }
    return false;
  }

  // Extract numeric amounts from a single OCR line.
  List<double> _extractAmountsFromLine(String line) {
    final sanitized = line.replaceAll('\u00A0', ' ');
    final matches = _amountTokenRegex.allMatches(sanitized);
    final values = <double>[];
    for (final match in matches) {
      final token = match.group(0) ?? '';
      if (_looksLikeLongId(token)) continue;
      final parsed = _parseAmount(token);
      if (parsed != null) values.add(parsed);
    }
    return values;
  }

  bool _looksLikeLongId(String token) {
    final cleaned = token.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length >= 10 && !token.contains('.') && !token.contains(',')) {
      return true;
    }
    return false;
  }

  // Parse a numeric token with comma/dot normalization.
  double? _parseAmount(String value) {
    var cleaned = value.trim();
    if (cleaned.isEmpty) return null;

    var isNegative = false;
    if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
      isNegative = true;
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    cleaned = _normalizeNumericToken(cleaned);
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9,\.\-]'), '');
    if (cleaned.isEmpty) return null;

    cleaned = _normalizeSeparators(cleaned);
    if (cleaned.isEmpty) return null;

    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    return isNegative ? -parsed : parsed;
  }

  String _normalizeNumericToken(String token) {
    final hasDigit = RegExp(r'\d').hasMatch(token);
    if (!hasDigit) return token;
    var normalized = token
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('L', '1');
    normalized = normalized.replaceAll(' ', '');
    return normalized;
  }

  // Normalize OCR text for keyword matching (O/0, I/1, etc.).
  String _normalizeForKeywords(String text) {
    return text
        .replaceAll('0', 'o')
        .replaceAll('1', 'l')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't')
        .replaceAll('8', 'b');
  }

  String _normalizeSeparators(String token) {
    var value = token;
    final hasComma = value.contains(',');
    final hasDot = value.contains('.');

    if (hasComma && hasDot) {
      if (value.lastIndexOf(',') > value.lastIndexOf('.')) {
        value = value.replaceAll('.', '');
        value = value.replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }
    } else if (hasComma) {
      final last = value.lastIndexOf(',');
      final digitsAfter = value.length - last - 1;
      if (digitsAfter == 2) {
        value = value.replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }
    } else if (hasDot) {
      final last = value.lastIndexOf('.');
      final digitsAfter = value.length - last - 1;
      if (digitsAfter == 0) {
        value = value.substring(0, value.length - 1);
      } else if (value.indexOf('.') != last) {
        final parts = value.split('.');
        final decimal = parts.removeLast();
        value = parts.join('') + '.' + decimal;
      }
    }

    value = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (value.indexOf('-') > 0) {
      value = value.replaceAll('-', '');
    }
    return value;
  }
}

class _AmountCandidate {
  final double value;
  final int lineIndex;
  final int score;
  final bool isStrongTotal;
  final bool isWeakTotal;
  final bool hasAmountLabel;
  final bool hasCurrency;

  const _AmountCandidate({
    required this.value,
    required this.lineIndex,
    required this.score,
    required this.isStrongTotal,
    required this.isWeakTotal,
    required this.hasAmountLabel,
    required this.hasCurrency,
  });
}

class _ParsedTime {
  final int hour;
  final int minute;
  final int second;

  const _ParsedTime({
    required this.hour,
    required this.minute,
    required this.second,
  });
}



