import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../utils/constants.dart';
import '../utils/layout.dart';
import 'add_budget_screen.dart';

/// Budgets list with monthly summary and progress tracking.
class BudgetsScreen extends StatefulWidget {
  final List<Budget> budgets;
  final List<Transaction> transactions;
  final VoidCallback onRefresh;
  final DataService dataService;

  const BudgetsScreen({
    Key? key,
    required this.budgets,
    required this.transactions,
    required this.onRefresh,
    required this.dataService,
  }) : super(key: key);

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Budgets filtered to selected month.
  List<Budget> get _currentMonthBudgets {
    return widget.budgets.where((budget) {
      return budget.month.year == _selectedMonth.year &&
          budget.month.month == _selectedMonth.month;
    }).toList();
  }

  // Compute spent amount for a category in the month.
  double _getSpentAmount(String category) {
    return widget.transactions
        .where((t) =>
            t.type == 'expense' &&
            t.category == category &&
            t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalBudget {
    return _currentMonthBudgets.fold(0.0, (sum, b) => sum + b.limit);
  }

  double get _totalSpent {
    return _currentMonthBudgets.fold(
        0.0, (sum, b) => sum + _getSpentAmount(b.category));
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

    // Main budgets layout.
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: sectionGap,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Budgets',
                              style: textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: _selectMonth,
                            icon: Icon(Icons.calendar_month_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.background,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: itemGap),

                      // Month Selector
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left_rounded,
                                  color: colorScheme.onPrimary),
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month - 1,
                                  );
                                });
                              },
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  DateFormat('MMMM yyyy')
                                      .format(_selectedMonth),
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right_rounded,
                                  color: colorScheme.onPrimary),
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month + 1,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Total Budget Overview
                      if (_currentMonthBudgets.isNotEmpty) ...[
                        SizedBox(height: sectionGap),
                        Container(
                          padding: EdgeInsets.all(itemGap + 4),
                          decoration: BoxDecoration(
                            color: colorScheme.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Budget',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: mutedText,
                                        ),
                                      ),
                                      Text(
                                        'PKR ${_totalBudget.toStringAsFixed(2)}',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Total Spent',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: mutedText,
                                        ),
                                      ),
                                      Text(
                                        'PKR ${_totalSpent.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _totalSpent > _totalBudget
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _totalBudget > 0
                                      ? (_totalSpent / _totalBudget)
                                          .clamp(0.0, 1.0)
                                      : 0,
                                  minHeight: 10,
                                  backgroundColor:
                                      colorScheme.outline.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _totalSpent > _totalBudget
                                        ? Colors.red
                                        : colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Budget List
                Expanded(
                  child: _currentMonthBudgets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color:
                                      colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.pie_chart_rounded,
                                  size: 80,
                                  color: colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: sectionGap),
                              Text(
                                'No budgets for this month',
                                style: textTheme.titleLarge,
                              ),
                              SizedBox(height: itemGap),
                              Text(
                                'Create a budget to track\nyour spending limits',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: mutedText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: hPad,
                            vertical: sectionGap,
                          ),
                          itemCount: _currentMonthBudgets.length,
                          itemBuilder: (context, index) {
                            final budget = _currentMonthBudgets[index];
                            return _buildBudgetCard(budget, index);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
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
        child: FloatingActionButton.extended(
          onPressed: _addBudget,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(Icons.add_rounded, size: 28),
          label: Text(
            'Add Budget',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Individual budget card with progress.
  Widget _buildBudgetCard(Budget budget, int index) {
    final spent = _getSpentAmount(budget.category);
    final percentage = (spent / budget.limit) * 100;
    final remaining = budget.limit - spent;
    final itemGap = AppLayout.itemGap(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.6);

    Color progressColor;
    Color backgroundColor;
    IconData statusIcon;

    if (percentage >= 100) {
      progressColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
      statusIcon = Icons.warning_rounded;
    } else if (percentage >= 80) {
      progressColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
      statusIcon = Icons.info_rounded;
    } else {
      progressColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
      statusIcon = Icons.check_circle_rounded;
    }

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 500 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: itemGap),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () => _showBudgetDetails(budget),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppConstants.getCategoryColor(budget.category)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          AppConstants.getCategoryIcon(budget.category),
                          color: AppConstants.getCategoryColor(budget.category),
                          size: 28,
                        ),
                      ),
                      SizedBox(width: itemGap + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.category,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Limit: PKR ${budget.limit.toStringAsFixed(2)}',
                              style: textTheme.bodySmall?.copyWith(
                                color: mutedText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          statusIcon,
                          color: progressColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1000),
                      tween: Tween(begin: 0, end: percentage / 100),
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value.clamp(0.0, 1.0),
                          minHeight: 12,
                          backgroundColor:
                              colorScheme.outline.withOpacity(0.2),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(progressColor),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        'Spent',
                        'PKR ${spent.toStringAsFixed(2)}',
                        progressColor,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: colorScheme.outline.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        'Remaining',
                        'PKR ${remaining.toStringAsFixed(2)}',
                        remaining >= 0 ? Colors.green : Colors.red,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: colorScheme.outline.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        'Progress',
                        '${percentage.toStringAsFixed(1)}%',
                        progressColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Bottom sheet with budget details and actions.
  void _showBudgetDetails(Budget budget) {
    final spent = _getSpentAmount(budget.category);
    final percentage = (spent / budget.limit) * 100;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                AppConstants.getCategoryColor(budget.category)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            AppConstants.getCategoryIcon(budget.category),
                            color:
                                AppConstants.getCategoryColor(budget.category),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget.category,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(budget.month),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildDetailItem(
                      'Budget Limit',
                      'PKR ${budget.limit.toStringAsFixed(2)}',
                      Icons.account_balance_wallet_rounded,
                      colorScheme.primary,
                    ),
                    _buildDetailItem(
                      'Amount Spent',
                      'PKR ${spent.toStringAsFixed(2)}',
                      Icons.shopping_cart_rounded,
                      percentage >= 100 ? Colors.red : Colors.orange,
                    ),
                    _buildDetailItem(
                      'Remaining Budget',
                      'PKR ${(budget.limit - spent).toStringAsFixed(2)}',
                      Icons.savings_rounded,
                      spent >= budget.limit ? Colors.red : Colors.green,
                    ),
                    _buildDetailItem(
                      'Progress',
                      '${percentage.toStringAsFixed(1)}%',
                      Icons.pie_chart_rounded,
                      percentage >= 80 ? Colors.red : colorScheme.primary,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteBudget(budget);
                            },
                            icon: Icon(Icons.delete_outline_rounded),
                            label: Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editBudget(budget);
                            },
                            icon: Icon(Icons.edit_rounded),
                            label: Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      String label, String value, IconData icon, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectMonth() async {
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

  // Navigate to add budget screen.
  void _addBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(
          selectedMonth: _selectedMonth,
          onSave: (budget) async {
            widget.budgets.add(budget);
            await widget.dataService.saveBudgets(widget.budgets);
            widget.onRefresh();
          },
        ),
      ),
    );
  }

  void _editBudget(Budget budget) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(
          budget: budget,
          selectedMonth: _selectedMonth,
          onSave: (updatedBudget) async {
            final index = widget.budgets.indexWhere((b) => b.id == budget.id);
            if (index != -1) {
              widget.budgets[index] = updatedBudget;
              await widget.dataService.saveBudgets(widget.budgets);
              widget.onRefresh();
            }
          },
        ),
      ),
    );
  }

  void _deleteBudget(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Delete Budget'),
        content: Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              widget.budgets.removeWhere((b) => b.id == budget.id);
              await widget.dataService.saveBudgets(widget.budgets);
              widget.onRefresh();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Budget deleted successfully'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}

