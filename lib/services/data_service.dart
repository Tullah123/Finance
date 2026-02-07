import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/reminder.dart';

/// Persists app data locally using SharedPreferences.
class DataService {
  static const String _transactionsKey = 'transactions';
  static const String _budgetsKey = 'budgets';
  static const String _goalsKey = 'goals';
  static const String _remindersKey = 'reminders';

  // Save transactions list to local storage.
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_transactionsKey, json.encode(jsonList));
  }

  // Load transactions list from local storage.
  Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_transactionsKey);
    if (jsonString == null) return [];
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => Transaction.fromJson(j)).toList();
  }

  // Save budgets list to local storage.
  Future<void> saveBudgets(List<Budget> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = budgets.map((b) => b.toJson()).toList();
    await prefs.setString(_budgetsKey, json.encode(jsonList));
  }

  // Load budgets list from local storage.
  Future<List<Budget>> loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_budgetsKey);
    if (jsonString == null) return [];
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => Budget.fromJson(j)).toList();
  }

  // Save goals list to local storage.
  Future<void> saveGoals(List<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = goals.map((g) => g.toJson()).toList();
    await prefs.setString(_goalsKey, json.encode(jsonList));
  }

  // Load goals list from local storage.
  Future<List<Goal>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_goalsKey);
    if (jsonString == null) return [];
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => Goal.fromJson(j)).toList();
  }

  // Save reminders list to local storage.
  Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = reminders.map((r) => r.toJson()).toList();
    await prefs.setString(_remindersKey, json.encode(jsonList));
  }

  // Load reminders list from local storage.
  Future<List<Reminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_remindersKey);
    if (jsonString == null) return [];
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => Reminder.fromJson(j)).toList();
  }

  // Remove all stored user data (transactions/budgets/goals/reminders).
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsKey);
    await prefs.remove(_budgetsKey);
    await prefs.remove(_goalsKey);
    await prefs.remove(_remindersKey);
  }
}




