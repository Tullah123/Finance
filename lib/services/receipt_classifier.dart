class ReceiptClassificationResult {
  final String type;
  final String reason;

  const ReceiptClassificationResult({
    required this.type,
    required this.reason,
  });
}

class ReceiptClassifier {
  static const List<String> _incomeKeywords = [
    'salary',
    'payroll',
    'wage',
    'refund',
    'cashback',
    'interest',
    'dividend',
    'rebate',
    'payout',
    'credit',
    'cr',
    'deposit',
    'received',
    'transfer in',
    'reversal',
  ];

  static const List<String> _expenseKeywords = [
    'purchase',
    'debit',
    'withdrawal',
    'payment',
    'paid',
    'pos',
    'invoice',
    'tax',
    'fee',
    'bill',
    'charge',
    'cash withdrawal',
  ];

  ReceiptClassificationResult classify({
    required String rawText,
    required String merchant,
  }) {
    final lower = rawText.toLowerCase();
    final merchantLower = merchant.toLowerCase();

    final incomeMatches = _incomeKeywords.where((k) {
      return lower.contains(k) || merchantLower.contains(k);
    }).toList();

    final expenseMatches = _expenseKeywords.where((k) {
      return lower.contains(k) || merchantLower.contains(k);
    }).toList();

    if (incomeMatches.isNotEmpty && expenseMatches.isEmpty) {
      return ReceiptClassificationResult(
        type: 'income',
        reason: 'keyword: ${incomeMatches.join(', ')}',
      );
    }

    if (expenseMatches.isNotEmpty && incomeMatches.isEmpty) {
      return ReceiptClassificationResult(
        type: 'expense',
        reason: 'keyword: ${expenseMatches.join(', ')}',
      );
    }

    if (incomeMatches.isNotEmpty && expenseMatches.isNotEmpty) {
      if (incomeMatches.any((k) => k == 'refund' || k == 'cashback')) {
        return ReceiptClassificationResult(
          type: 'income',
          reason: 'refund/cashback signal',
        );
      }
      return ReceiptClassificationResult(
        type: 'expense',
        reason: 'expense-preferred when mixed signals',
      );
    }

    return const ReceiptClassificationResult(
      type: 'expense',
      reason: 'default: receipt-like document',
    );
  }
}


