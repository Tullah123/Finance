import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../utils/constants.dart';
import '../utils/layout.dart';
import '../services/data_service.dart';
import '../screens/goals_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/settings_screen.dart';

/// Dashboard overview with balances, quick actions, and recent activity.
class DashboardScreen extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final List<Goal> goals;
  final VoidCallback onRefresh;
  final DataService dataService;

  const DashboardScreen({
    Key? key,
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.onRefresh,
    required this.dataService,
  }) : super(key: key);

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

    // Aggregate totals for overall balance.
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalBalance = totalIncome - totalExpense;

    final now = DateTime.now();
    // Filter to current month for summary cards.
    final monthTransactions = transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();

    final monthIncome = monthTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final monthExpense = monthTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final currency = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);
    final currencyPrecise =
        NumberFormat.currency(symbol: 'PKR ', decimalDigits: 2);

    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentTransactions = sortedTransactions.take(5).toList();

    // Quick navigation tiles.
    final quickItems = [
      _QuickItem(
        label: 'Transactions',
        value: transactions.length.toString(),
        icon: Icons.receipt_long_rounded,
        color: colorScheme.primary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionsScreen(
                transactions: transactions,
                onRefresh: onRefresh,
                dataService: dataService,
              ),
            ),
          );
        },
      ),
      _QuickItem(
        label: 'Budgets',
        value: budgets.length.toString(),
        icon: Icons.pie_chart_rounded,
        color: const Color(0xFFF4B860),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetsScreen(
                budgets: budgets,
                transactions: transactions,
                onRefresh: onRefresh,
                dataService: dataService,
              ),
            ),
          );
        },
      ),
      _QuickItem(
        label: 'Goals',
        value: goals.length.toString(),
        icon: Icons.flag_rounded,
        color: const Color(0xFF3FA7D6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalsScreen(
                goals: goals,
                onRefresh: onRefresh,
                dataService: dataService,
              ),
            ),
          );
        },
      ),
      _QuickItem(
        label: 'Reports',
        value: totalIncome > 0
            ? '${(((totalIncome - totalExpense) / totalIncome) * 100).toStringAsFixed(0)}%'
            : '0%',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF6D8EA0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportsScreen(
                transactions: transactions,
              ),
            ),
          );
        },
      ),
    ];

    final quickGridCount = AppLayout.gridCount(
      context,
      minTileWidth: 150,
      maxCount: 3,
    );
    //
    //
    //
    final quickCardAspect = quickGridCount >= 3 ? 1.0 : 1.25;

    // Main dashboard layout.
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                EdgeInsets.symmetric(horizontal: hPad, vertical: sectionGap),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello',
                                  style: textTheme.bodySmall,
                                ),
                                SizedBox(height: itemGap / 2),
                                Text(
                                  'Welcome back',
                                  style: textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final cleared = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                              if (cleared == true) {
                                onRefresh();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('All data erased.'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sectionGap),
                      _buildBalanceCard(
                        context,
                        totalBalance: currencyPrecise.format(totalBalance),
                        totalIncome: currencyPrecise.format(totalIncome),
                        totalExpense: currencyPrecise.format(totalExpense),
                        isCompact: isCompact,
                      ),
                      SizedBox(height: sectionGap),
                      Text(
                        'This Month (${DateFormat('MMMM').format(now)})',
                        style: textTheme.titleLarge,
                      ),
                      //
                      //
                      //
                      SizedBox(height: itemGap),

                      Row(children: [
                        Expanded(
                          child: SizedBox(
                            height: 100,
                            child: _buildStatCard(
                              context,
                              label: 'Income',
                              value: currency.format(monthIncome),
                              icon: Icons.arrow_downward_rounded,
                              color: const Color(0xFF2E8B57),
                            ),
                          ),
                        ),

                        //
                        //
                      ]),
                      SizedBox(height: itemGap),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 100,
                              child: _buildStatCard(
                                context,
                                label: 'Expense',
                                value: currency.format(monthExpense),
                                icon: Icons.arrow_upward_rounded,
                                color: const Color(0xFFD1495B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      //
                      //
                      //

                      SizedBox(height: sectionGap),
                      Text(
                        'Quick Access',
                        style: textTheme.titleLarge,
                      ),
                      SizedBox(height: itemGap),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: quickGridCount,
                          crossAxisSpacing: itemGap,
                          mainAxisSpacing: itemGap,
                          childAspectRatio: quickCardAspect,
                        ),
                        itemCount: quickItems.length,
                        itemBuilder: (context, index) {
                          final item = quickItems[index];
                          return _buildQuickCard(
                            context,
                            label: item.label,
                            value: item.value,
                            icon: item.icon,
                            color: item.color,
                            onTap: item.onTap,
                          );
                        },
                      ),
                      SizedBox(height: sectionGap),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionsScreen(
                                    transactions: transactions,
                                    onRefresh: onRefresh,
                                    dataService: dataService,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'View all',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: itemGap),
                      if (recentTransactions.isEmpty)
                        _buildEmptyState(context)
                      else
                        Column(
                          children: recentTransactions
                              .map((t) => _buildRecentTransaction(context, t))
                              .toList(),
                        ),
                      SizedBox(height: cardPad),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context, {
    required String totalBalance,
    required String totalIncome,
    required String totalExpense,
    required bool isCompact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final itemGap = AppLayout.itemGap(context);
    final cardPad = AppLayout.cardPadding(context);

    return Container(
      padding: EdgeInsets.all(cardPad + 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: itemGap),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              totalBalance,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 28 : 34,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: itemGap + 8),
          Row(
            children: [
              Expanded(
                child: _buildBalanceMetric(
                  context,
                  label: 'Total Income',
                  value: totalIncome,
                  color: const Color(0xFFB8E6D5),
                ),
              ),
              SizedBox(width: itemGap),
              Expanded(
                child: _buildBalanceMetric(
                  context,
                  label: 'Total Expense',
                  value: totalExpense,
                  color: const Color(0xFFF7B7B7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final itemGap = AppLayout.itemGap(context);
    final cardPad = AppLayout.cardPadding(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(cardPad - 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: itemGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: textTheme.bodySmall,
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

  Widget _buildQuickCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cardPad = AppLayout.cardPadding(context);
    final itemGap = AppLayout.itemGap(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.all(cardPad - 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              SizedBox(height: itemGap),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cardPad = AppLayout.cardPadding(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(cardPad + 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start tracking your finances',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransaction(
    BuildContext context,
    Transaction transaction,
  ) {
    final itemGap = AppLayout.itemGap(context);
    final cardPad = AppLayout.cardPadding(context);
    final dateLabel = DateFormat('MMM dd').format(transaction.date);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: itemGap),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: cardPad - 2,
          vertical: 6,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConstants.getCategoryColor(transaction.category)
                .withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            AppConstants.getCategoryIcon(transaction.category),
            color: AppConstants.getCategoryColor(transaction.category),
            size: 20,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${transaction.category} - $dateLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${transaction.type == 'income' ? '+' : '-'} ${NumberFormat.currency(symbol: 'PKR ', decimalDigits: 2).format(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.type == 'income' ? Colors.green : Colors.red,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _QuickItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

