class Goal {
  String id;
  String title;
  double targetAmount;
  double currentAmount;
  DateTime deadline;
  String? description;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    this.description,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline.toIso8601String(),
        'description': description,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        title: json['title'],
        targetAmount: json['targetAmount'].toDouble(),
        currentAmount: json['currentAmount'].toDouble(),
        deadline: DateTime.parse(json['deadline']),
        description: json['description'],
      );
}
