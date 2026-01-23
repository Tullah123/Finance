class Transaction {
  String id;
  String title;
  double amount;
  String category;
  String type;
  DateTime date;
  String? notes;
  String? merchant;
  String? currency;
  double? tax;
  String? paymentMethod;
  String? receiptImagePath;
  String? receiptFilePath;
  String? receiptSource;
  String? rawText;
  String? classificationReason;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.notes,
    this.merchant,
    this.currency,
    this.tax,
    this.paymentMethod,
    this.receiptImagePath,
    this.receiptFilePath,
    this.receiptSource,
    this.rawText,
    this.classificationReason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'type': type,
        'date': date.toIso8601String(),
        'notes': notes,
        'merchant': merchant,
        'currency': currency,
        'tax': tax,
        'paymentMethod': paymentMethod,
        'receiptImagePath': receiptImagePath,
        'receiptFilePath': receiptFilePath,
        'receiptSource': receiptSource,
        'rawText': rawText,
        'classificationReason': classificationReason,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      category: json['category'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      merchant: json['merchant'],
      currency: json['currency'],
      tax: json['tax'] == null ? null : (json['tax'] as num).toDouble(),
      paymentMethod: json['paymentMethod'],
      receiptImagePath: json['receiptImagePath'],
      receiptFilePath: json['receiptFilePath'],
      receiptSource: json['receiptSource'],
      rawText: json['rawText'],
      classificationReason: json['classificationReason']);
}


