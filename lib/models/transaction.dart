class Transaction {
  String id;
  String title;
  double amount;
  String category;
  String type;
  DateTime date;
  String? notes;
  //
  //
  //String? receiptImagePath;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.notes,
    //
    //
    // this.receiptImagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'type': type,
        'date': date.toIso8601String(),
        'notes': notes,
        //'receiptImagePath': receiptImagePath,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      category: json['category'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      notes: json['notes']);
  //receiptImagePath: json['receiptImagePath']);
}
