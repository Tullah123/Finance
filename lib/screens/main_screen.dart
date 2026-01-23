import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budgets_screen.dart';
import 'goals_screen.dart';
import 'reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final DataService _dataService = DataService();
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final transactions = await _dataService.loadTransactions();
    final budgets = await _dataService.loadBudgets();
    final goals = await _dataService.loadGoals();
    setState(() {
      _transactions = transactions;
      _budgets = budgets;
      _goals = goals;
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screens = [
      DashboardScreen(
        transactions: _transactions,
        budgets: _budgets,
        goals: _goals,
        onRefresh: _loadData,
        dataService: _dataService,
      ),
      TransactionsScreen(
        transactions: _transactions,
        onRefresh: _loadData,
        dataService: _dataService,
      ),
      BudgetsScreen(
        budgets: _budgets,
        transactions: _transactions,
        onRefresh: _loadData,
        dataService: _dataService,
      ),
      GoalsScreen(
        goals: _goals,
        onRefresh: _loadData,
        dataService: _dataService,
      ),
      ReportsScreen(transactions: _transactions),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                _buildNavItem(Icons.receipt_long_rounded, 'Transactions', 1),
                _buildNavItem(Icons.pie_chart_rounded, 'Budgets', 2),
                _buildNavItem(Icons.flag_rounded, 'Goals', 3),
                _buildNavItem(Icons.bar_chart_rounded, 'Reports', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6C63FF) : Colors.grey,
              size: isSelected ? 28 : 24,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF6C63FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
