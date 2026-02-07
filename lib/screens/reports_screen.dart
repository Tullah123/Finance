import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../services/statement_pdf_service.dart';
import '../utils/constants.dart';
import '../utils/layout.dart';
import 'statement_pdf_viewer_screen.dart';

/// Reports and analytics for a selected period.
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
  final StatementPdfService _statementPdfService = StatementPdfService();
  bool _isGenerating = false;

  // Transactions filtered by selected period.
  List<Transaction> get _filteredTransactions {
    return widget.transactions.where((t) {
      if (_selectedPeriod == 'month') {
        return t.date.year == _selectedDate.year &&
            t.date.month == _selectedDate.month;
      } else if (_selectedPeriod == 'year') {
        return t.date.year == _selectedDate.year;
      } else if (_selectedPeriod == 'week') {
        final start = _weekStart(_selectedDate);
        final end = _weekEnd(_selectedDate);
        final date = DateTime(t.date.year, t.date.month, t.date.day);
        return !date.isBefore(start) && !date.isAfter(end);
      }
      return true;
    }).toList();
  }

  DateTime _weekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  DateTime _weekEnd(DateTime date) {
    return _weekStart(date).add(const Duration(days: 6));
  }

  DateTime _periodStart() {
    if (_selectedPeriod == 'year') {
      return DateTime(_selectedDate.year, 1, 1);
    }
    if (_selectedPeriod == 'week') {
      return _weekStart(_selectedDate);
    }
    return DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  DateTime _periodEnd() {
    if (_selectedPeriod == 'year') {
      return DateTime(_selectedDate.year, 12, 31);
    }
    if (_selectedPeriod == 'week') {
      return _weekEnd(_selectedDate);
    }
    return DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
  }

  String _periodLabel() {
    if (_selectedPeriod == 'year') {
      return DateFormat('yyyy').format(_selectedDate);
    }
    if (_selectedPeriod == 'week') {
      final start = _weekStart(_selectedDate);
      final end = _weekEnd(_selectedDate);
      return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}';
    }
    return DateFormat('MMMM yyyy').format(_selectedDate);
  }

  String _periodKey() {
    switch (_selectedPeriod) {
      case 'week':
        return 'week';
      case 'year':
        return 'year';
      case 'month':
      default:
        return 'month';
    }
  }

  // Generate and open a PDF statement.
  Future<void> _generateStatement() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final file = await _statementPdfService.generateStatement(
        transactions: _filteredTransactions,
        periodLabel: _periodLabel(),
        periodKey: _periodKey(),
        periodStart: _periodStart(),
        periodEnd: _periodEnd(),
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StatementPdfViewerScreen(
            filePath: file.path,
            title: 'Statement ${_periodLabel()}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
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
                      Text(
                        'Reports & Analytics',
                        style: textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: sectionGap),

                      // Period Selector
                      Row(
                        children: [
                          Expanded(
                            child: _buildPeriodButton('Week', 'week'),
                          ),
                          SizedBox(width: itemGap),
                          Expanded(
                            child: _buildPeriodButton('Month', 'month'),
                          ),
                          SizedBox(width: itemGap),
                          Expanded(
                            child: _buildPeriodButton('Year', 'year'),
                          ),
                        ],
                      ),
                      SizedBox(height: itemGap),

                      // Date Navigator
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
                                  if (_selectedPeriod == 'month') {
                                    _selectedDate = DateTime(
                                      _selectedDate.year,
                                      _selectedDate.month - 1,
                                    );
                                  } else if (_selectedPeriod == 'year') {
                                    _selectedDate =
                                        DateTime(_selectedDate.year - 1);
                                  } else {
                                    _selectedDate = _selectedDate
                                        .subtract(Duration(days: 7));
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  _periodLabel(),
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
                                  if (_selectedPeriod == 'month') {
                                    _selectedDate = DateTime(
                                      _selectedDate.year,
                                      _selectedDate.month + 1,
                                    );
                                  } else if (_selectedPeriod == 'year') {
                                    _selectedDate =
                                        DateTime(_selectedDate.year + 1);
                                  } else {
                                    _selectedDate =
                                        _selectedDate.add(Duration(days: 7));
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
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: sectionGap,
                    ),
                    children: [
                      // Summary cards
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
                          SizedBox(width: itemGap),
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
                      SizedBox(height: itemGap),
                      _buildSummaryCard(
                        'Net Balance',
                        balance,
                        balance >= 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.orange,
                        balance >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                      ),
                      SizedBox(height: sectionGap + 5),

                      // Statement actions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
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
                            Text(
                              'Statements',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate a PDF statement for the selected period.',
                              style: textTheme.bodySmall?.copyWith(
                                color: mutedText,
                              ),
                            ),
                            SizedBox(height: itemGap + 4),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isGenerating ? null : _generateStatement,
                                icon: const Icon(Icons.picture_as_pdf_rounded),
                                label: Text(
                                  _isGenerating
                                      ? 'Creating...'
                                      : 'Generate PDF',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sectionGap + 5),

                      // Expense breakdown chart
                      if (categoryData.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(25),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expense by Category',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
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
                        SizedBox(height: sectionGap + 5),
                      ],

                      // Statistics list
                      Container(
                        padding: const EdgeInsets.all(25),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Statistics',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 20),
                            _buildStatRow(
                              Icons.receipt_long_rounded,
                              'Total Transactions',
                              _filteredTransactions.length.toString(),
                              Theme.of(context).colorScheme.primary,
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
                                Theme.of(context).colorScheme.primary,
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
        ),
      ),
    );
  }

  // Period toggle buttons (week/month/year).
  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.6);
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
          color: isSelected ? colorScheme.primary : colorScheme.background,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? colorScheme.onPrimary : mutedText,
            ),
          ),
        ),
      ),
    );
  }

  // Summary card for income/expense/balance.
  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.6);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              color: mutedText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'PKR ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.6);
    return categoryData.entries.map((entry) {
      final percentage = (entry.value / totalExpense) * 100;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.background,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.6);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.background,
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
                color: mutedText,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

