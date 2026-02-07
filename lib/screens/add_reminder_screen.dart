import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';
import '../utils/layout.dart';

/// Add/Edit reminder form with schedule options.
class AddReminderScreen extends StatefulWidget {
  final Reminder? reminder;
  final void Function(Reminder) onSave;
  final Future<void> Function()? onDelete;

  const AddReminderScreen({
    Key? key,
    this.reminder,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _expiryDate;
  late TimeOfDay _expiryTime;
  late int _nearOffsetMinutes;
  late int _postOffsetMinutes;
  late List<DateTime> _extraAlerts;
  bool _isEnabled = true;
  String _timeZoneName = 'UTC';
  String _localTimeZoneName = 'UTC';
  bool _useUtc = false;

  static const List<_OffsetOption> _nearOptions = [
    _OffsetOption(10, '10 min'),
    _OffsetOption(30, '30 min'),
    _OffsetOption(60, '1 hour'),
    _OffsetOption(1440, '1 day'),
  ];

  static const List<_OffsetOption> _postOptions = [
    _OffsetOption(10, '10 min'),
    _OffsetOption(30, '30 min'),
    _OffsetOption(60, '1 hour'),
    _OffsetOption(1440, '1 day'),
  ];

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _titleController = TextEditingController(text: reminder?.title ?? '');
    _notesController = TextEditingController(text: reminder?.notes ?? '');

    final expiryLocal = reminder?.expiryAt.toLocal() ??
        DateTime.now().add(const Duration(hours: 1));
    _expiryDate =
        DateTime(expiryLocal.year, expiryLocal.month, expiryLocal.day);
    _expiryTime = TimeOfDay.fromDateTime(expiryLocal);

    _nearOffsetMinutes = reminder?.nearExpiryOffsetMinutes ?? 60;
    _postOffsetMinutes = reminder?.postExpiryDelayMinutes ?? 30;
    _isEnabled = reminder?.isEnabled ?? true;
    _extraAlerts =
        List<DateTime>.from(reminder?.extraAlerts ?? const <DateTime>[])
          ..sort((a, b) => a.toUtc().compareTo(b.toUtc()));
    _localTimeZoneName = NotificationService.instance.timeZoneName;
    _timeZoneName = reminder?.timeZone ?? _localTimeZoneName;
    _useUtc = _timeZoneName == 'UTC';

    if (!_nearOptions.any((option) => option.minutes == _nearOffsetMinutes)) {
      _nearOffsetMinutes = _nearOptions.first.minutes;
    }
    if (!_postOptions.any((option) => option.minutes == _postOffsetMinutes)) {
      _postOffsetMinutes = _postOptions.first.minutes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Pick expiry date.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  // Pick expiry time.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _expiryTime,
    );
    if (picked != null) {
      setState(() {
        _expiryTime = picked;
      });
    }
  }

  // Add extra alert time entries.
  Future<void> _addExtraAlert() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _expiryTime,
    );
    if (pickedTime == null) return;

    final selectedLocal = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final selectedUtc = _useUtc
        ? DateTime.utc(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          )
        : selectedLocal.toUtc();

    final exists = _extraAlerts.any(
      (alert) => alert.toUtc().isAtSameMomentAs(selectedUtc),
    );
    if (exists) return;

    setState(() {
      _extraAlerts.add(selectedUtc);
      _extraAlerts.sort((a, b) => a.toUtc().compareTo(b.toUtc()));
    });
  }

  // Confirm and delete a reminder.
  Future<void> _confirmDelete() async {
    if (widget.onDelete == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Delete Reminder'),
        content: const Text('Delete this reminder permanently?'),
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
    if (shouldDelete != true) return;
    await widget.onDelete!.call();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // Validate and save reminder data.
  void _saveReminder() {
    if (!_formKey.currentState!.validate()) return;

    final expiryLocal = DateTime(
      _expiryDate.year,
      _expiryDate.month,
      _expiryDate.day,
      _expiryTime.hour,
      _expiryTime.minute,
    );
    final expiryUtc = _useUtc
        ? DateTime.utc(
            _expiryDate.year,
            _expiryDate.month,
            _expiryDate.day,
            _expiryTime.hour,
            _expiryTime.minute,
          )
        : expiryLocal.toUtc();

    final extraAlerts = <DateTime>[];
    for (final alert in _extraAlerts) {
      final utc = alert.toUtc();
      final exists =
          extraAlerts.any((existing) => existing.isAtSameMomentAs(utc));
      if (!exists) {
        extraAlerts.add(utc);
      }
    }
    extraAlerts.sort((a, b) => a.toUtc().compareTo(b.toUtc()));

    final nowUtc = DateTime.now().toUtc();
    final reminder = Reminder(
      id: widget.reminder?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      expiryAt: expiryUtc,
      nearExpiryOffsetMinutes: _nearOffsetMinutes,
      postExpiryDelayMinutes: _postOffsetMinutes,
      extraAlerts: extraAlerts,
      isEnabled: _isEnabled,
      isCompleted: widget.reminder?.isCompleted ?? false,
      createdAt: widget.reminder?.createdAt ?? nowUtc,
      updatedAt: nowUtc,
      timeZone: _useUtc ? 'UTC' : _localTimeZoneName,
    );

    widget.onSave(reminder);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.6);
    final hPad = AppLayout.horizontalPadding(context);
    final sectionGap = AppLayout.sectionGap(context);
    final itemGap = AppLayout.itemGap(context);
    final maxWidth = AppLayout.maxContentWidth(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final themed = Theme.of(context);
    final focusColor = colorScheme.primary;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.reminder == null ? 'Add Reminder' : 'Edit Reminder'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Theme(
                data: themed.copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: colorScheme.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: focusColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      sectionGap,
                      hPad,
                      sectionGap + bottomInset + 24, // Prevents overflow on small screens.
                    ),
                    children: [
                      _buildSection(
                        title: 'Title',
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: 'Reminder title',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      _buildSection(
                        title: 'Notes (Optional)',
                        child: TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Add details or context',
                          ),
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      _buildSection(
                        title: 'Expiry Date & Time',
                        child: Column(
                          children: [
                            _buildPickerRow(
                              icon: Icons.calendar_today_rounded,
                              label: DateFormat('MMM dd, yyyy')
                                  .format(_expiryDate),
                              onTap: _pickDate,
                            ),
                            SizedBox(height: itemGap),
                            _buildPickerRow(
                              icon: Icons.access_time_rounded,
                              label: _expiryTime.format(context),
                              onTap: _pickTime,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      _buildSection(
                        title: 'Near Expiry',
                        child: DropdownButtonFormField<int>(
                          isExpanded: true, // Avoids horizontal overflow.
                          value: _nearOffsetMinutes,
                          items: _nearOptions
                              .map((option) => DropdownMenuItem<int>(
                                    value: option.minutes,
                                    child: Text(option.label),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _nearOffsetMinutes = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      _buildSection(
                        title: 'Post-expiry Follow-up',
                        child: DropdownButtonFormField<int>(
                          isExpanded: true, // Avoids horizontal overflow.
                          value: _postOffsetMinutes,
                          items: _postOptions
                              .map((option) => DropdownMenuItem<int>(
                                    value: option.minutes,
                                    child: Text(option.label),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _postOffsetMinutes = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: sectionGap),
                    _buildSection(
                      title: 'Additional Alerts',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_extraAlerts.isEmpty)
                              Text(
                                'No extra alerts added yet.',
                                style: TextStyle(color: mutedText),
                              )
                            else
                              Column(
                                children: _extraAlerts
                                    .asMap()
                                    .entries
                                    .map((entry) => Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.background,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.notifications_active,
                                                size: 18,
                                                color: colorScheme.primary,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  _formatAlertLabel(
                                                    _extraAlerts[entry.key],
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _extraAlerts
                                                        .removeAt(entry.key);
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            SizedBox(height: itemGap),
                            OutlinedButton.icon(
                              onPressed: _addExtraAlert,
                              icon: const Icon(Icons.add_alarm_rounded),
                              label: const Text('Add alert time'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable reminder'),
                        value: _isEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isEnabled = value;
                          });
                        },
                      ),
                      SizedBox(height: itemGap),
                      DropdownButtonFormField<String>(
                        isExpanded: true, // Avoids overflow.
                        value: _useUtc ? 'UTC' : 'local',
                        items: [
                          DropdownMenuItem(
                            value: 'local',
                            child: Text('Local ($_localTimeZoneName)'),
                          ),
                          const DropdownMenuItem(
                            value: 'UTC',
                            child: Text('UTC'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _useUtc = value == 'UTC';
                            _timeZoneName =
                                _useUtc ? 'UTC' : _localTimeZoneName;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Timezone',
                        ),
                      ),
                      SizedBox(height: sectionGap + 6),
                      ElevatedButton.icon(
                        onPressed: _saveReminder,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(
                          widget.reminder == null
                              ? 'Save Reminder'
                              : 'Update Reminder',
                        ),
                      ),
                      if (widget.reminder != null && widget.onDelete != null)
                        Padding(
                          padding: EdgeInsets.only(top: itemGap),
                          child: OutlinedButton.icon(
                            onPressed: _confirmDelete,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Delete Reminder',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      SizedBox(height: sectionGap),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPickerRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurface.withOpacity(0.45),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAlertLabel(DateTime utc) {
    final display = _useUtc ? utc.toUtc() : utc.toLocal();
    return DateFormat('MMM dd, yyyy - hh:mm a').format(display);
  }
}

class _OffsetOption {
  final int minutes;
  final String label;

  const _OffsetOption(this.minutes, this.label);
}


