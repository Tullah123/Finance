/// UI-friendly status bucket for reminders.
enum ReminderStatus {
  upcoming,
  nearExpiry,
  expired,
  completed,
  disabled,
}

/// Reminder model used for scheduling local notifications.
class Reminder {
  String id;
  String title;
  String? notes;
  DateTime expiryAt;
  int nearExpiryOffsetMinutes;
  int postExpiryDelayMinutes;
  List<DateTime> extraAlerts;
  bool isEnabled;
  bool isCompleted;
  DateTime createdAt;
  DateTime updatedAt;
  String timeZone;

  Reminder({
    required this.id,
    required this.title,
    this.notes,
    required this.expiryAt,
    required this.nearExpiryOffsetMinutes,
    required this.postExpiryDelayMinutes,
    required this.extraAlerts,
    required this.isEnabled,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.timeZone,
  });

  // Compute status based on current UTC time.
  ReminderStatus status(DateTime nowUtc) {
    if (isCompleted) return ReminderStatus.completed;
    if (!isEnabled) return ReminderStatus.disabled;
    if (nowUtc.isAfter(expiryAt) || nowUtc.isAtSameMomentAs(expiryAt)) {
      return ReminderStatus.expired;
    }
    final nearAt =
        expiryAt.subtract(Duration(minutes: nearExpiryOffsetMinutes));
    if (nowUtc.isAfter(nearAt) || nowUtc.isAtSameMomentAs(nearAt)) {
      return ReminderStatus.nearExpiry;
    }
    return ReminderStatus.upcoming;
  }

  // Serialize for local storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'expiryAt': expiryAt.toIso8601String(),
        'nearExpiryOffsetMinutes': nearExpiryOffsetMinutes,
        'postExpiryDelayMinutes': postExpiryDelayMinutes,
        'extraAlerts': extraAlerts.map((dt) => dt.toIso8601String()).toList(),
        'isEnabled': isEnabled,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'timeZone': timeZone,
      };

  // Deserialize from local storage.
  factory Reminder.fromJson(Map<String, dynamic> json) {
    final extra = (json['extraAlerts'] as List<dynamic>?)
            ?.map((value) => DateTime.parse(value).toUtc())
            .toList() ??
        <DateTime>[];
    return Reminder(
      id: json['id'],
      title: json['title'],
      notes: json['notes'],
      expiryAt: DateTime.parse(json['expiryAt']).toUtc(),
      nearExpiryOffsetMinutes: json['nearExpiryOffsetMinutes'],
      postExpiryDelayMinutes: json['postExpiryDelayMinutes'],
      extraAlerts: extra,
      isEnabled: json['isEnabled'],
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt']).toUtc(),
      timeZone: json['timeZone'] ?? 'UTC',
    );
  }
}

