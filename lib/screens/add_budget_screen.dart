import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../utils/constants.dart';
import '../utils/layout.dart';

/// Add/Edit budget form.
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

  // Available expense categories.
  List<String> get _categories => AppConstants.expenseCategories;

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
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final gridColumns = AppLayout.gridCount(
      context,
      minTileWidth: isCompact ? 92 : 104,
      maxCount: 4,
    );
    final gridAspect = gridColumns >= 4 ? 1.2 : 1.05;
    final categoryTilePadding = isCompact ? 6.0 : 8.0;
    final categoryIconSize = isCompact ? 20.0 : 22.0;
    final categoryFontSize = isCompact ? 9.5 : 10.5;
    final categoryLabelGap = isCompact ? 3.0 : 4.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          widget.budget == null ? 'Create Budget' : 'Edit Budget',
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  sectionGap,
                  hPad,
                  sectionGap + bottomInset + 24,
                ),
                children: [
                    // Category Selection
                    Container(
                      padding: const EdgeInsets.all(20),
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
                            'Select Category',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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
                                  padding: EdgeInsets.all(categoryTilePadding),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppConstants.getCategoryColor(category)
                                            .withOpacity(0.1)
                                        : colorScheme.background,
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
                                            : mutedText,
                                        size: categoryIconSize,
                                      ),
                                      SizedBox(height: categoryLabelGap),
                                      Text(
                                        category,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: categoryFontSize,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppConstants.getCategoryColor(
                                                  category)
                                              : mutedText,
                                        ),
                                        maxLines: 1,
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
                            'Budget Limit',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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
                              color: colorScheme.primary,
                            ),
                            decoration: InputDecoration(
                              prefixText: 'PKR ',
                              prefixStyle: TextStyle(
                                fontSize: isCompact ? 26 : 32,
                                fontWeight: FontWeight.bold,
                                color: mutedText,
                              ),
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                fontSize: isCompact ? 26 : 32,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.outline.withOpacity(0.4),
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
                            'Select Month',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          InkWell(
                            onTap: _selectMonth,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.background,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    color: colorScheme.primary,
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
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: colorScheme.onSurface.withOpacity(0.45),
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
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
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
    );
  }

  // Pick budget month.
  Future<void> _selectMonth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedMonth = DateTime(date.year, date.month);
      });
    }
  }

  // Validate and save budget data.
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



