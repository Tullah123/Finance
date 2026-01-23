import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../utils/constants.dart';
import '../utils/layout.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? budget;
  final DateTime selectedMonth;
  final Function(Budget) onSave;

  const AddBudgetScreen({
    Key? key,
    this.budget,
    required this.selectedMonth,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _limitController;

  String _category = 'Food & Dining';
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.budget?.limit.toString() ?? '',
    );
    _selectedMonth = widget.budget?.month ?? widget.selectedMonth;

    if (widget.budget != null) {
      _category = widget.budget!.category;
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPadding(context);
    final sectionGap = AppLayout.sectionGap(context);
    final itemGap = AppLayout.itemGap(context);
    final maxWidth = AppLayout.maxContentWidth(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final gridColumns = AppLayout.gridCount(
      context,
      minTileWidth: 110,
      maxCount: 4,
    );
    final gridAspect = gridColumns >= 4 ? 1.2 : 1.1;
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          widget.budget == null ? 'Create Budget' : 'Edit Budget',
        ),
      ),
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
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
                    // Category Selection
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                            'Select Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: sectionGap),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridColumns,
                              crossAxisSpacing: itemGap,
                              mainAxisSpacing: itemGap,
                              childAspectRatio: gridAspect,
                            ),
                            itemCount: AppConstants.expenseCategories.length,
                            itemBuilder: (context, index) {
                              final category =
                                  AppConstants.expenseCategories[index];
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
                                        : const Color(0xFFF4F7F8),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppConstants.getCategoryColor(
                                              category)
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
                                            ? AppConstants.getCategoryColor(
                                                category)
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

                    // Budget Limit
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                            'Budget Limit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _limitController,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              fontSize: isCompact ? 26 : 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B998B),
                            ),
                            decoration: InputDecoration(
                              prefixText: 'PKR ',
                              prefixStyle: TextStyle(
                                fontSize: isCompact ? 26 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                fontSize: isCompact ? 26 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[300],
                              ),
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a budget limit';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              if (double.parse(value) <= 0) {
                                return 'Budget must be greater than 0';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionGap),

                    // Month Selection
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                            'Select Month',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          InkWell(
                            onTap: _selectMonth,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7F8),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    color: const Color(0xFF1B998B),
                                    size: 24,
                                  ),
                                  SizedBox(width: itemGap),
                                  Expanded(
                                    child: Text(
                                      DateFormat('MMMM yyyy')
                                          .format(_selectedMonth),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.grey[400],
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionGap + 10),

                    // Save Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B998B),
                            const Color(0xFF14786C),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B998B).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveBudget,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Save Budget',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectMonth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF1B998B),
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
        _selectedMonth = DateTime(date.year, date.month);
      });
    }
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      final budget = Budget(
        id: widget.budget?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        category: _category,
        limit: double.parse(_limitController.text),
        month: _selectedMonth,
      );

      widget.onSave(budget);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                widget.budget == null
                    ? 'Budget created successfully!'
                    : 'Budget updated successfully!',
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


