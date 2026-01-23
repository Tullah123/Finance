import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../utils/layout.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  final List<Reminder> reminders;
  final VoidCallback onRefresh;
  final DataService dataService;

  const RemindersScreen({
    Key? key,
    required this.reminders,
    required this.onRefresh,
    required this.dataService,
  }) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.requestPermissions();
      await _syncNotifications();
    });
  }

  List<Reminder> get _sortedReminders {
    final nowUtc = DateTime.now().toUtc();
    final items = List<Reminder>.from(widget.reminders);
    items.sort((a, b) {
      final aStatus = a.status(nowUtc);
      final bStatus = b.status(nowUtc);
      if (aStatus != bStatus) {
        return _statusRank(aStatus).compareTo(_statusRank(bStatus));
      }
      return a.expiryAt.compareTo(b.expiryAt);
    });
    return items;
  }

  int _statusRank(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.nearExpiry:
        return 0;
      case ReminderStatus.upcoming:
        return 1;
      case ReminderStatus.expired:
        return 2;
      case ReminderStatus.completed:
        return 3;
      case ReminderStatus.disabled:
        return 4;
    }
  }

  Future<void> _syncNotifications() async {
    for (final reminder in widget.reminders) {
      await NotificationService.instance.cancelReminderFor(reminder);
      if (reminder.isEnabled && !reminder.isCompleted) {
        await NotificationService.instance.scheduleReminder(reminder);
      }
    }
  }

  Future<void> _saveReminders() async {
    await widget.dataService.saveReminders(widget.reminders);
    widget.onRefresh();
  }

  void _addReminder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(
          onSave: (reminder) async {
            widget.reminders.add(reminder);
            await _saveReminders();
            await NotificationService.instance.cancelReminderFor(reminder);
            await NotificationService.instance.scheduleReminder(reminder);
          },
        ),
      ),
    );
  }

  void _editReminder(Reminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(
          reminder: reminder,
          onSave: (updated) async {
            final index =
                widget.reminders.indexWhere((r) => r.id == updated.id);
            if (index != -1) {
              widget.reminders[index] = updated;
              await _saveReminders();
              await NotificationService.instance.cancelReminderFor(reminder);
              if (updated.isEnabled && !updated.isCompleted) {
                await NotificationService.instance.scheduleReminder(updated);
              }
            }
          },
          onDelete: () async {
            await _deleteReminder(reminder);
          },
        ),
      ),
    );
  }

  Future<void> _toggleEnabled(Reminder reminder, bool value) async {
    setState(() {
      reminder.isEnabled = value;
      reminder.updatedAt = DateTime.now().toUtc();
    });
    await _saveReminders();
    await NotificationService.instance.cancelReminderFor(reminder);
    if (reminder.isEnabled && !reminder.isCompleted) {
      await NotificationService.instance.scheduleReminder(reminder);
    }
  }

  Future<void> _toggleCompleted(Reminder reminder) async {
    setState(() {
      if (reminder.isCompleted) {
        reminder.isCompleted = false;
        reminder.isEnabled = true;
      } else {
        reminder.isCompleted = true;
        reminder.isEnabled = false;
      }
      reminder.updatedAt = DateTime.now().toUtc();
    });
    await _saveReminders();
    await NotificationService.instance.cancelReminderFor(reminder);
    if (reminder.isEnabled && !reminder.isCompleted) {
      await NotificationService.instance.scheduleReminder(reminder);
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    widget.reminders.removeWhere((r) => r.id == reminder.id);
    await _saveReminders();
    await NotificationService.instance.cancelReminderFor(reminder);
  }

  void _showActions(Reminder reminder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editReminder(reminder);
              },
            ),
            ListTile(
              leading: Icon(
                reminder.isCompleted
                    ? Icons.refresh_rounded
                    : Icons.check_circle_rounded,
              ),
              title:
                  Text(reminder.isCompleted ? 'Mark active' : 'Mark completed'),
              onTap: () async {
                Navigator.pop(context);
                await _toggleCompleted(reminder);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text('Delete Reminder'),
                    content: const Text(
                      'Are you sure you want to delete this reminder?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (shouldDelete == true) {
                  await _deleteReminder(reminder);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPadding(context);
    final sectionGap = AppLayout.sectionGap(context);
    final itemGap = AppLayout.itemGap(context);
    final maxWidth = AppLayout.maxContentWidth(context);
    final nowUtc = DateTime.now().toUtc();

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: sectionGap,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Reminders',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_sortedReminders.length}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _sortedReminders.isEmpty
                      ? _buildEmptyState(sectionGap)
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: hPad,
                            vertical: sectionGap,
                          ),
                          itemCount: _sortedReminders.length,
                          itemBuilder: (context, index) {
                            final reminder = _sortedReminders[index];
                            return _buildReminderCard(
                              reminder,
                              nowUtc,
                              itemGap,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reminder'),
      ),
    );
  }

  Widget _buildEmptyState(double sectionGap) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1B998B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.alarm_rounded,
              size: 72,
              color: Color(0xFF1B998B),
            ),
          ),
          SizedBox(height: sectionGap),
          const Text(
            'No reminders yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a reminder to stay on track',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(
    Reminder reminder,
    DateTime nowUtc,
    double itemGap,
  ) {
    final status = reminder.status(nowUtc);
    final statusLabel = _statusLabel(status);
    final statusColor = _statusColor(status);
    final expiryLabel = DateFormat('MMM dd, yyyy - hh:mm a')
        .format(reminder.expiryAt.toLocal());

    return Container(
      margin: EdgeInsets.only(bottom: itemGap),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _editReminder(reminder),
        onLongPress: () => _showActions(reminder),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.alarm_rounded,
            color: statusColor,
          ),
        ),
        title: Text(
          reminder.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(
              expiryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (reminder.notes != null && reminder.notes!.isNotEmpty)
              Text(
                reminder.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: SizedBox(
          width: 86,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusChip(statusLabel, statusColor),
              const SizedBox(height: 6),
              Switch(
                value: reminder.isEnabled,
                onChanged: reminder.isCompleted
                    ? null
                    : (value) => _toggleEnabled(reminder, value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _statusLabel(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.nearExpiry:
        return 'Near expiry';
      case ReminderStatus.expired:
        return 'Expired';
      case ReminderStatus.completed:
        return 'Completed';
      case ReminderStatus.disabled:
        return 'Disabled';
      case ReminderStatus.upcoming:
      default:
        return 'Upcoming';
    }
  }

  Color _statusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.nearExpiry:
        return Colors.orange;
      case ReminderStatus.expired:
        return Colors.red;
      case ReminderStatus.completed:
        return Colors.green;
      case ReminderStatus.disabled:
        return Colors.grey;
      case ReminderStatus.upcoming:
      default:
        return const Color(0xFF1B998B);
    }
  }
}
