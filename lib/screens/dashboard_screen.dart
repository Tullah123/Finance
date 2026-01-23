import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../utils/constants.dart';
import '../services/data_service.dart';
import '../screens/goals_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/budgets_screen.dart';

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
    // FIXED: Calculate ALL transactions, not just current month
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    // FIXED: Total balance (all time)
    final totalBalance = totalIncome - totalExpense;

    // Current month transactions for stats
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();

    final monthIncome = monthTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final monthExpense = monthTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello! 👋',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.notifications_rounded,
                              color: const Color(0xFF6C63FF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // FIXED: Total Balance Card (All Time)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6C63FF),
                          const Color(0xFF5A52D5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Balance (All Time)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'PKR ${totalBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBalanceItem(
                                '↓ Total Income',
                                totalIncome,
                                Colors.green[300]!,
                              ),
                            ),
                            Container(
                              height: 50,
                              width: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            Expanded(
                              child: _buildBalanceItem(
                                '↑ Total Expense',
                                totalExpense,
                                Colors.red[300]!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Current Month Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Month (${DateFormat('MMMM').format(now)})',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Income',
                              'PKR ${monthIncome.toStringAsFixed(0)}',
                              Icons.arrow_downward_rounded,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Expense',
                              'PKR ${monthExpense.toStringAsFixed(0)}',
                              Icons.arrow_upward_rounded,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TransactionsScreen(
                                      transactions:
                                          transactions, // send all transactions
                                      onRefresh:
                                          onRefresh, // refresh dashboard when returning
                                      dataService:
                                          dataService, // VERY IMPORTANT
                                    ),
                                  ),
                                );
                              },
                              child: _buildStatCard(
                                context,
                                'Transactions',
                                monthTransactions.length.toString(),
                                Icons.receipt_long_rounded,
                                const Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            //
                            //
                            child: InkWell(
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
                              //
                              //
                              child: _buildStatCard(
                                context,
                                'Budgets',
                                budgets.length.toString(),
                                Icons.pie_chart_rounded,
                                const Color(0xFFFF6B6B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
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
                              child: _buildStatCard(
                                context,
                                'Goals',
                                goals.length.toString(),
                                Icons.flag_rounded,
                                const Color(0xFF4ECDC4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: InkWell(
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
                              child: _buildStatCard(
                                context,
                                'Reports',
                                totalIncome > 0
                                    ? '${(((totalIncome - totalExpense) / totalIncome) * 100).toStringAsFixed(0)}%'
                                    : '0%',
                                Icons.trending_up_rounded,
                                const Color(0xFF95E1D3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Transactions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: const Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: transactions.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start tracking your finances',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // FIXED: Sort by date descending (newest first)
                            final sortedTransactions = List<Transaction>.from(
                              transactions,
                            )..sort((a, b) => b.date.compareTo(a.date));

                            final transaction = sortedTransactions[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppConstants.getCategoryColor(
                                      transaction.category,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    AppConstants.getCategoryIcon(
                                      transaction.category,
                                    ),
                                    color: AppConstants.getCategoryColor(
                                      transaction.category,
                                    ),
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  transaction.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  '${transaction.category} • ${DateFormat('MMM dd, yyyy').format(transaction.date)}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Text(
                                  '${transaction.type == 'income' ? '+' : '-'} PKR ${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: transaction.type == 'income'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: transactions.length > 10
                              ? 10
                              : transactions.length,
                        ),
                      ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          'PKR ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }
}



/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../utils/constants.dart';
import '../screens/transactions_screen.dart';
import '../services/data_service.dart';
import '../screens/reports_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/budgets_screen.dart';

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
    final now = DateTime.now();

    final monthTransactions = transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();

    final totalIncome = monthTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = monthTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello! 👋',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.notifications_rounded,
                              color: const Color.fromARGB(255, 15, 255, 59),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Balance Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color.fromARGB(255, 54, 65, 218),
                          const Color.fromARGB(255, 40, 65, 203),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Balance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'PKR ${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBalanceItem(
                                '↓ Income',
                                totalIncome,
                                Colors.green[300]!,
                              ),
                            ),
                            Container(
                              height: 50,
                              width: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            Expanded(
                              child: _buildBalanceItem(
                                '↑ Expense',
                                totalExpense,
                                Colors.red[300]!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            //
                            //
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TransactionsScreen(
                                      transactions:
                                          transactions, // send all transactions
                                      onRefresh:
                                          onRefresh, // refresh dashboard when returning
                                      dataService:
                                          dataService, // VERY IMPORTANT
                                    ),
                                  ),
                                );
                              },
                              //
                              //
                              child: _buildStatCard(
                                context,
                                'Transactions',
                                monthTransactions.length.toString(),
                                Icons.receipt_long_rounded,
                                const Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            //
                            //
                            child: InkWell(
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
                              //
                              //
                              child: _buildStatCard(
                                context,
                                'Budgets',
                                budgets.length.toString(),
                                Icons.pie_chart_rounded,
                                const Color(0xFFFF6B6B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            //
                            //
                            child: InkWell(
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
                              //
                              //
                              child: _buildStatCard(
                                context,
                                'Goals',
                                goals.length.toString(),
                                Icons.flag_rounded,
                                const Color(0xFF4ECDC4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            //
                            //
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportsScreen(
                                        transactions: transactions),
                                  ),
                                );
                              },
                              //
                              //
                              child: _buildStatCard(
                                context,
                                'Savings',
                                totalIncome > 0
                                    ? '${((balance / totalIncome) * 100).toStringAsFixed(0)}%'
                                    : '0%',
                                Icons.trending_up_rounded,
                                const Color(0xFF95E1D3),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Transactions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: const Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: transactions.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start tracking your finances',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final transaction = transactions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppConstants.getCategoryColor(
                                      transaction.category,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    AppConstants.getCategoryIcon(
                                      transaction.category,
                                    ),
                                    color: AppConstants.getCategoryColor(
                                      transaction.category,
                                    ),
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  transaction.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  '${transaction.category} • ${DateFormat('MMM dd').format(transaction.date)}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Text(
                                  '${transaction.type == 'income' ? '+' : '-'} PKR ${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: transaction.type == 'income'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: transactions.take(5).length,
                        ),
                      ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'PKR ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
*/