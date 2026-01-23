class Budget {
  String id;
  String category;
  double limit;
  DateTime month;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.month,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'limit': limit,
        'month': month.toIso8601String(),
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'],
        category: json['category'],
        limit: json['limit'].toDouble(),
        month: DateTime.parse(json['month']),
      );
}
