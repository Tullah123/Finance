import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/layout.dart';
//import 'package:personal_finance_tracker/screens/receipt_scanner_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  final Function(Transaction) onSave;

  const AddTransactionScreen({
    Key? key,
    this.transaction,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _type = 'expense';
  String _category = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.transaction?.title ?? '');
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? '',
    );
    _notesController =
        TextEditingController(text: widget.transaction?.notes ?? '');

    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _category = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.transaction!.date);
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    return _type == 'expense'
        ? AppConstants.expenseCategories
        : AppConstants.incomeCategories;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hPad = AppLayout.horizontalPadding(context);
    final sectionGap = AppLayout.sectionGap(context);
    final itemGap = AppLayout.itemGap(context);
    final cardPad = AppLayout.cardPadding(context);
    final maxWidth = AppLayout.maxContentWidth(context);
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final amountFontSize = isCompact ? 26.0 : 32.0;
    final largeGap = sectionGap + 8;
    final gridColumns = AppLayout.gridCount(
      context,
      minTileWidth: isCompact ? 96 : 112,
      maxCount: 4,
    );
    final gridAspect = gridColumns >= 4 ? 1.2 : 1.1;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          widget.transaction == null ? 'Add Transaction' : 'Edit Transaction',
        ),
      ),
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: sectionGap,
                    ),
                    children: [
              // Transaction Type Selector
              Container(
                padding: EdgeInsets.all(cardPad),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Type',
                      style: textTheme.titleMedium,
                    ),
                    SizedBox(height: itemGap),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton(
                            'Income',
                            'income',
                            Icons.arrow_downward_rounded,
                            Colors.green,
                          ),
                        ),
                        SizedBox(width: itemGap),
                        Expanded(
                          child: _buildTypeButton(
                            'Expense',
                            'expense',
                            Icons.arrow_upward_rounded,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionGap),

              // Amount Input
              Container(
                padding: EdgeInsets.all(cardPad),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: textTheme.titleMedium,
                    ),
                    SizedBox(height: itemGap),
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: amountFontSize,
                        fontWeight: FontWeight.bold,
                        color: _type == 'income' ? Colors.green : Colors.red,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'PKR ',
                        prefixStyle: TextStyle(
                          fontSize: amountFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontSize: amountFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[300],
                        ),
                        border: InputBorder.none,
                        filled: false,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionGap),

              // Title Input
              Container(
                padding: EdgeInsets.all(cardPad),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title',
                      style: textTheme.titleMedium,
                    ),
                    SizedBox(height: itemGap),
                    TextFormField(
                      controller: _titleController,
                      style: textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Enter transaction title',
                        prefixIcon: Icon(
                          Icons.edit_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionGap),
              /*
              // Receipt Scanner Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange,
                      Colors.deepOrange,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReceiptScannerScreen(
                            onSave: (transaction) async {
                              // Handle the scanned transaction
                              widget.transaction.add(transaction);
                              await widget.dataService
                                  .saveTransactions(widget.transaction);
                              widget.onRefresh();
                            },
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner_rounded,
                              color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'Scan Receipt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              */
              SizedBox(height: sectionGap),

              // Category Selector
              Container(
                padding: EdgeInsets.all(cardPad),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: textTheme.titleMedium,
                    ),
                    SizedBox(height: itemGap),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridColumns,
                        crossAxisSpacing: itemGap,
                        mainAxisSpacing: itemGap,
                        childAspectRatio: gridAspect,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _category == category;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _category = category;
                            });
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppConstants.getCategoryColor(category)
                                      .withOpacity(0.1)
                                  : colorScheme.background,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? AppConstants.getCategoryColor(category)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppConstants.getCategoryIcon(category),
                                  color: isSelected
                                      ? AppConstants.getCategoryColor(category)
                                      : Colors.grey[600],
                                  size: 28,
                                ),
                                SizedBox(height: itemGap / 2),
                                Text(
                                  category,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isCompact ? 10 : 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppConstants.getCategoryColor(
                                            category)
                                        : Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionGap),

              // Date and Time Picker
              Container(
                padding: EdgeInsets.all(cardPad),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Time',
                      style: textTheme.titleMedium,
                    ),
                    SizedBox(height: itemGap),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: EdgeInsets.all(cardPad - 4),
                              decoration: BoxDecoration(
                                color: colorScheme.background,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: itemGap),
                                  Expanded(
                                    child: Text(
                                      DateFormat('MMM dd, yyyy')
                                          .format(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: itemGap),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: EdgeInsets.all(cardPad - 4),
                              decoration: BoxDecoration(
                                color: colorScheme.background,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: itemGap),
                                  Expanded(
                                    child: Text(
                                      _selectedTime.format(context),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionGap),

              // Notes Input
              Container(
                padding: EdgeInsets.all(cardPad),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes (Optional)',
                      style: textTheme.titleMedium,
                    ),
                    SizedBox(height: itemGap),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      style: textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Add any notes or description...',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: largeGap),

              // Save Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.25),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 14 : 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 22),
                      SizedBox(width: itemGap),
                      Text(
                        'Save Transaction',
                        style: TextStyle(
                          fontSize: isCompact ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

  Widget _buildTypeButton(
      String label, String value, IconData icon, Color color) {
    final isSelected = _type == value;
    final background = Theme.of(context).colorScheme.background;
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = value;
          _category = _categories.first;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : background,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final baseScheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: baseScheme.copyWith(
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final baseScheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: baseScheme.copyWith(
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final transaction = Transaction(
        id: widget.transaction?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        category: _category,
        type: _type,
        date: dateTime,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      widget.onSave(transaction);
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                widget.transaction == null
                    ? 'Transaction added successfully!'
                    : 'Transaction updated successfully!',
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(20),
        ),
      );
    }
  }
}


