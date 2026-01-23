import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';

class ReportsScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const ReportsScreen({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'month';
  DateTime _selectedDate = DateTime.now();

  List<Transaction> get _filteredTransactions {
    return widget.transactions.where((t) {
      if (_selectedPeriod == 'month') {
        return t.date.year == _selectedDate.year &&
            t.date.month == _selectedDate.month;
      } else if (_selectedPeriod == 'year') {
        return t.date.year == _selectedDate.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final income = _filteredTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final expense = _filteredTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = income - expense;

    // Category breakdown
    final categoryData = <String, double>{};
    for (var transaction
        in _filteredTransactions.where((t) => t.type == 'expense')) {
      categoryData[transaction.category] =
          (categoryData[transaction.category] ?? 0) + transaction.amount;
    }

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
                  Text(
                    'Reports & Analytics',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Period Selector
                  Row(
                    children: [
                      Expanded(
                        child: _buildPeriodButton('Month', 'month'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPeriodButton('Year', 'year'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Date Navigator
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
                              if (_selectedPeriod == 'month') {
                                _selectedDate = DateTime(
                                  _selectedDate.year,
                                  _selectedDate.month - 1,
                                );
                              } else {
                                _selectedDate =
                                    DateTime(_selectedDate.year - 1);
                              }
                            });
                          },
                        ),
                        Text(
                          _selectedPeriod == 'month'
                              ? DateFormat('MMMM yyyy').format(_selectedDate)
                              : DateFormat('yyyy').format(_selectedDate),
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
                              if (_selectedPeriod == 'month') {
                                _selectedDate = DateTime(
                                  _selectedDate.year,
                                  _selectedDate.month + 1,
                                );
                              } else {
                                _selectedDate =
                                    DateTime(_selectedDate.year + 1);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Income',
                          income,
                          Colors.green,
                          Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Expense',
                          expense,
                          Colors.red,
                          Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    'Net Balance',
                    balance,
                    balance >= 0 ? const Color(0xFF6C63FF) : Colors.orange,
                    balance >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                  ),
                  const SizedBox(height: 25),

                  // Pie Chart
                  if (categoryData.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(25),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense by Category',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                sections: _buildPieChartSections(
                                    categoryData, expense),
                                sectionsSpace: 3,
                                centerSpaceRadius: 50,
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          ..._buildLegendItems(categoryData, expense),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],

                  // Statistics
                  Container(
                    padding: const EdgeInsets.all(25),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStatRow(
                          Icons.receipt_long_rounded,
                          'Total Transactions',
                          _filteredTransactions.length.toString(),
                          const Color(0xFF6C63FF),
                        ),
                        _buildStatRow(
                          Icons.shopping_cart_rounded,
                          'Average Expense',
                          _filteredTransactions
                                  .where((t) => t.type == 'expense')
                                  .isEmpty
                              ? 'PKR 0.00'
                              : 'PKR ${(expense / _filteredTransactions.where((t) => t.type == 'expense').length).toStringAsFixed(2)}',
                          Colors.orange,
                        ),
                        _buildStatRow(
                          Icons.trending_up_rounded,
                          'Largest Expense',
                          _filteredTransactions
                                  .where((t) => t.type == 'expense')
                                  .isEmpty
                              ? 'PKR 0.00'
                              : 'PKR ${_filteredTransactions.where((t) => t.type == 'expense').map((t) => t.amount).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}',
                          Colors.red,
                        ),
                        _buildStatRow(
                          Icons.savings_rounded,
                          'Savings Rate',
                          income > 0
                              ? '${((balance / income) * 100).toStringAsFixed(1)}%'
                              : '0%',
                          Colors.green,
                        ),
                        if (categoryData.isNotEmpty)
                          _buildStatRow(
                            Icons.category_rounded,
                            'Top Spending',
                            categoryData.entries
                                .reduce((a, b) => a.value > b.value ? a : b)
                                .key,
                            const Color(0xFF6C63FF),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 15),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'PKR ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> categoryData,
    double totalExpense,
  ) {
    return categoryData.entries.map((entry) {
      final index = categoryData.keys.toList().indexOf(entry.key);
      final percentage = (entry.value / totalExpense) * 100;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: AppConstants.getCategoryColor(entry.key),
        radius: 80,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegendItems(
    Map<String, double> categoryData,
    double totalExpense,
  ) {
    return categoryData.entries.map((entry) {
      final percentage = (entry.value / totalExpense) * 100;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    AppConstants.getCategoryColor(entry.key).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                AppConstants.getCategoryIcon(entry.key),
                color: AppConstants.getCategoryColor(entry.key),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'PKR ${entry.value.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppConstants.getCategoryColor(entry.key),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
