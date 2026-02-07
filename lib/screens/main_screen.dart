import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/reminder.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budgets_screen.dart';
import 'goals_screen.dart';
import 'reports_screen.dart';
import 'reminders_screen.dart';

/// Main shell with bottom navigation and swipeable pages.
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final DataService _dataService = DataService();
  late final PageController _pageController;
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<Goal> _goals = [];
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Load all persisted data for tabs.
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final transactions = await _dataService.loadTransactions();
    final budgets = await _dataService.loadBudgets();
    final goals = await _dataService.loadGoals();
    final reminders = await _dataService.loadReminders();
    setState(() {
      _transactions = transactions;
      _budgets = budgets;
      _goals = goals;
      _reminders = reminders;
      _isLoading = false;
    });
  }

  // Sync bottom nav taps with PageView.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Tab pages for the bottom navigation.
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
      RemindersScreen(
        reminders: _reminders,
        onRefresh: _loadData,
        dataService: _dataService,
      ),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        // Swipe left/right to change tab pages.
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Home', 0),
                  _buildNavItem(Icons.receipt_long_rounded, 'Transactions', 1),
                  _buildNavItem(Icons.pie_chart_rounded, 'Budgets', 2),
                  _buildNavItem(Icons.flag_rounded, 'Goals', 3),
                  _buildNavItem(Icons.bar_chart_rounded, 'Reports', 4),
                  _buildNavItem(Icons.alarm_rounded, 'Reminders', 5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 10,
          //
          //

          // horizontal: isSelected ? (isCompact ? 10 : 16) : (isCompact ? 8 : 12),
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.5),
              size: isSelected ? (isCompact ? 24 : 28) : (isCompact ? 22 : 24),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: isCompact ? 9 : 10,
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

