import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../utils/constants.dart';
import 'add_budget_screen.dart';

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

  List<Budget> get _currentMonthBudgets {
    return widget.budgets.where((budget) {
      return budget.month.year == _selectedMonth.year &&
          budget.month.month == _selectedMonth.month;
    }).toList();
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budgets',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: _selectMonth,
                        icon: Icon(Icons.calendar_month_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF5F7FA),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Month Selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C63FF),
                          const Color(0xFF5A52D5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left_rounded,
                              color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month - 1,
                              );
                            });
                          },
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedMonth),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right_rounded,
                              color: Colors.white),
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Budget',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'PKR ${_totalBudget.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Spent',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'PKR ${_totalSpent.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
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
                                  ? (_totalSpent / _totalBudget).clamp(0.0, 1.0)
                                  : 0,
                              minHeight: 10,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _totalSpent > _totalBudget
                                    ? Colors.red
                                    : const Color(0xFF6C63FF),
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
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.pie_chart_rounded,
                              size: 80,
                              color: const Color(0xFF6C63FF),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No budgets for this month',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Create a budget to track\nyour spending limits',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C63FF),
              const Color(0xFF5A52D5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
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

  Widget _buildBudgetCard(Budget budget, int index) {
    final spent = _getSpentAmount(budget.category);
    final percentage = (spent / budget.limit) * 100;
    final remaining = budget.limit - spent;

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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.category,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Limit: PKR ${budget.limit.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
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
                          backgroundColor: Colors.grey[200],
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
                        color: Colors.grey[300],
                      ),
                      _buildStatItem(
                        'Remaining',
                        'PKR ${remaining.toStringAsFixed(2)}',
                        remaining >= 0 ? Colors.green : Colors.red,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
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
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showBudgetDetails(Budget budget) {
    final spent = _getSpentAmount(budget.category);
    final percentage = (spent / budget.limit) * 100;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
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
                                  color: Colors.grey[600],
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
                      const Color(0xFF6C63FF),
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
                      percentage >= 80 ? Colors.red : const Color(0xFF6C63FF),
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
                              backgroundColor: const Color(0xFF6C63FF),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF6C63FF),
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
