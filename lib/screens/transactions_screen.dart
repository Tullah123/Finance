import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../utils/constants.dart';
import '../utils/layout.dart';
import 'add_transaction_screen.dart';
import 'receipt_scanner_screen.dart';

/// Transactions list with filters, sorting, and details.
class TransactionsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final VoidCallback onRefresh;
  final DataService dataService;

  const TransactionsScreen({
    Key? key,
    required this.transactions,
    required this.onRefresh,
    required this.dataService,
  }) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  String _filterType = 'all';
  String _sortBy = 'date';
  late TabController _tabController;

  @override
  // Setup tab controller for All/Income/Expense.
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Apply type filter and sorting.
  List<Transaction> get _filteredTransactions {
    var filtered = widget.transactions;

    if (_filterType != 'all') {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    filtered.sort((a, b) {
      if (_sortBy == 'date') {
        return b.date.compareTo(a.date);
      } else if (_sortBy == 'amount') {
        return b.amount.compareTo(a.amount);
      }
      return 0;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hPad = AppLayout.horizontalPadding(context);
    final sectionGap = AppLayout.sectionGap(context);
    final itemGap = AppLayout.itemGap(context);
    final cardPad = AppLayout.cardPadding(context);
    final maxWidth = AppLayout.maxContentWidth(context);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    // Split transactions into date buckets.
    final todayTransactions = _filteredTransactions.where((t) {
      return !t.date.isBefore(todayStart) && t.date.isBefore(tomorrowStart);
    }).toList();

    final yesterdayTransactions = _filteredTransactions.where((t) {
      return !t.date.isBefore(yesterdayStart) && t.date.isBefore(todayStart);
    }).toList();

    final futureTransactions = _filteredTransactions.where((t) {
      return !t.date.isBefore(tomorrowStart);
    }).toList();

    final olderTransactions = _filteredTransactions.where((t) {
      return t.date.isBefore(yesterdayStart);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                // Header + filters
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: sectionGap,
                  ),
                  color: colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _filterType == 'all'
                                  ? 'Transactions (${widget.transactions.length})'
                                  : 'Transactions (${_filteredTransactions.length}/${widget.transactions.length})',
                              style: textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _showSortOptions,
                                icon: Icon(Icons.sort_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.background,
                                ),
                              ),
                              SizedBox(width: itemGap),
                              IconButton(
                                onPressed: _showFilterOptions,
                                icon: Icon(Icons.filter_list_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.background,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: itemGap),
                      // Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.background,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: TextStyle(fontWeight: FontWeight.bold),
                          onTap: (index) {
                            setState(() {
                              if (index == 0) _filterType = 'all';
                              if (index == 1) _filterType = 'income';
                              if (index == 2) _filterType = 'expense';
                            });
                          },
                          tabs: [
                            Tab(text: 'All'),
                            Tab(text: 'Income'),
                            Tab(text: 'Expense'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Transaction list content
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(cardPad + 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  size: 72,
                                  color: colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: sectionGap),
                              Text(
                                'No transactions yet',
                                style: textTheme.titleLarge,
                              ),
                              SizedBox(height: itemGap),
                              Text(
                                'Tap the + button to add\nyour first transaction',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: hPad,
                            vertical: sectionGap,
                          ),
                          children: [
                            if (futureTransactions.isNotEmpty) ...[
                              _buildSectionHeader('Upcoming'),
                              ...futureTransactions
                                  .map((t) => _buildTransactionCard(t)),
                              SizedBox(height: itemGap),
                            ],
                            if (todayTransactions.isNotEmpty) ...[
                              _buildSectionHeader('Today'),
                              ...todayTransactions
                                  .map((t) => _buildTransactionCard(t)),
                              SizedBox(height: itemGap),
                            ],
                            if (yesterdayTransactions.isNotEmpty) ...[
                              _buildSectionHeader('Yesterday'),
                              ...yesterdayTransactions
                                  .map((t) => _buildTransactionCard(t)),
                              SizedBox(height: itemGap),
                            ],
                            if (olderTransactions.isNotEmpty) ...[
                              _buildSectionHeader('Older'),
                              ...olderTransactions
                                  .map((t) => _buildTransactionCard(t)),
                            ],
                          ],
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
              color: colorScheme.primary.withOpacity(0.25),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _addTransaction(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(Icons.add_rounded, size: 28),
          label: Text(
            'Add Transaction',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final textTheme = Theme.of(context).textTheme;
    final itemGap = AppLayout.itemGap(context);
    return Padding(
      padding: EdgeInsets.only(bottom: itemGap, top: itemGap / 2),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final itemGap = AppLayout.itemGap(context);
    final cardPad = AppLayout.cardPadding(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: itemGap),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showTransactionDetails(transaction),
          child: Padding(
            padding: EdgeInsets.all(cardPad - 2),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(cardPad - 4),
                  decoration: BoxDecoration(
                    color: AppConstants.getCategoryColor(transaction.category)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    AppConstants.getCategoryIcon(transaction.category),
                    color: AppConstants.getCategoryColor(transaction.category),
                    size: 26,
                  ),
                ),
                SizedBox(width: itemGap + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${transaction.category}  ${DateFormat('hh:mm a').format(transaction.date)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${transaction.type == 'income' ? '+' : '-'} PKR ${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: transaction.type == 'income'
                            ? Colors.green
                            : Colors.red,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bottom sheet for sort options.
  void _showSortOptions() {
    final cardPad = AppLayout.cardPadding(context);
    final sectionGap = AppLayout.sectionGap(context);
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(cardPad),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sectionGap),
            _buildSortOption('Date', 'date', Icons.calendar_today_rounded),
            _buildSortOption('Amount', 'amount', Icons.attach_money_rounded),
            SizedBox(height: sectionGap / 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value, IconData icon) {
    final isSelected = _sortBy == value;
    final primary = Theme.of(context).colorScheme.primary;
    final itemGap = AppLayout.itemGap(context);
    return Container(
      margin: EdgeInsets.only(bottom: itemGap),
      decoration: BoxDecoration(
        color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? primary : Colors.grey[300]!,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primary : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primary : Colors.black87,
          ),
        ),
        trailing: isSelected ? Icon(Icons.check_circle, color: primary) : null,
        onTap: () {
          setState(() {
            _sortBy = value;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // Bottom sheet for type filters.
  void _showFilterOptions() {
    final cardPad = AppLayout.cardPadding(context);
    final sectionGap = AppLayout.sectionGap(context);
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(cardPad),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter By Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sectionGap),
            _buildFilterOption(
                'All Transactions', 'all', Icons.all_inclusive_rounded),
            _buildFilterOption(
                'Income Only', 'income', Icons.arrow_downward_rounded),
            _buildFilterOption(
                'Expenses Only', 'expense', Icons.arrow_upward_rounded),
            SizedBox(height: sectionGap / 2),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, String value, IconData icon) {
    final isSelected = _filterType == value;
    final primary = Theme.of(context).colorScheme.primary;
    final itemGap = AppLayout.itemGap(context);
    return Container(
      margin: EdgeInsets.only(bottom: itemGap),
      decoration: BoxDecoration(
        color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? primary : Colors.grey[300]!,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primary : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primary : Colors.black87,
          ),
        ),
        trailing: isSelected ? Icon(Icons.check_circle, color: primary) : null,
        onTap: () {
          setState(() {
            _filterType = value;
            // Update tab controller
            if (value == 'all') _tabController.index = 0;
            if (value == 'income') _tabController.index = 1;
            if (value == 'expense') _tabController.index = 2;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // Bottom sheet with transaction details and actions.
  void _showTransactionDetails(Transaction transaction) {
    final cardPad = AppLayout.cardPadding(context);
    final sectionGap = AppLayout.sectionGap(context);
    final itemGap = AppLayout.itemGap(context);
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Handle bar
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
                padding: EdgeInsets.all(cardPad + 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header + filters
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppConstants.getCategoryColor(
                                    transaction.category)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            AppConstants.getCategoryIcon(transaction.category),
                            color: AppConstants.getCategoryColor(
                                transaction.category),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                transaction.category,
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
                    SizedBox(height: sectionGap + 6),

                    // Amount
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: itemGap / 2),
                          Text(
                            '${transaction.type == 'income' ? '+' : '-'} PKR ${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: transaction.type == 'income'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionGap + 6),

                    // Details
                    _buildDetailItem(
                      'Type',
                      transaction.type == 'income' ? 'Income' : 'Expense',
                      Icons.swap_vert_rounded,
                    ),
                    _buildDetailItem(
                      'Date',
                      DateFormat('MMMM dd, yyyy - hh:mm a')
                          .format(transaction.date),
                      Icons.calendar_today_rounded,
                    ),
                    if (transaction.notes != null &&
                        transaction.notes!.isNotEmpty)
                      _buildDetailItem(
                        'Notes',
                        transaction.notes!,
                        Icons.note_rounded,
                      ),
                    SizedBox(height: sectionGap + 6),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteTransaction(transaction);
                            },
                            icon: Icon(Icons.delete_outline_rounded),
                            label: Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: itemGap),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editTransaction(context, transaction);
                            },
                            icon: Icon(Icons.edit_rounded),
                            label: Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildDetailItem(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
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
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Entry point for manual or scan flows.
  void _addTransaction(BuildContext context) {
    final parentContext = context;
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Transaction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.edit_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('Manual Entry'),
              onTap: () {
                Navigator.pop(context);
                Future.microtask(() {
                  Navigator.of(parentContext).push(
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(
                        onSave: (transaction) async {
                          widget.transactions.add(transaction);
                          await widget.dataService
                              .saveTransactions(widget.transactions);
                          widget.onRefresh();
                        },
                      ),
                    ),
                  );
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.receipt_long_rounded,
                  color: Theme.of(context).colorScheme.primary),
              title: Text('Scan Receipt'),
              onTap: () {
                Navigator.pop(context);
                Future.microtask(() {
                  Navigator.of(parentContext).push(
                    MaterialPageRoute(
                      builder: (context) => ReceiptScannerScreen(
                        onSave: (transaction) async {
                          widget.transactions.add(transaction);
                          await widget.dataService
                              .saveTransactions(widget.transactions);
                          widget.onRefresh();
                        },
                      ),
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editTransaction(BuildContext context, Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          transaction: transaction,
          onSave: (updatedTransaction) async {
            final index =
                widget.transactions.indexWhere((t) => t.id == transaction.id);
            if (index != -1) {
              widget.transactions[index] = updatedTransaction;
              await widget.dataService.saveTransactions(widget.transactions);
              widget.onRefresh();
            }
          },
        ),
      ),
    );
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Delete Transaction'),
        content: Text(
            'Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              widget.transactions.removeWhere((t) => t.id == transaction.id);
              await widget.dataService.saveTransactions(widget.transactions);
              widget.onRefresh();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transaction deleted successfully'),
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

