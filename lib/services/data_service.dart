import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';

class DataService {
  static const String _transactionsKey = 'transactions';
  static const String _budgetsKey = 'budgets';
  static const String _goalsKey = 'goals';

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_transactionsKey, json.encode(jsonList));
  }

  Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_transactionsKey);
    if (jsonString == null) return [];
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => Transaction.fromJson(j)).toList();
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = budgets.map((b) => b.toJson()).toList();
    await prefs.setString(_budgetsKey, json.encode(jsonList));
  }

  Future<List<Budget>> loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_budgetsKey);
    if (jsonString == null) return [];
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => Budget.fromJson(j)).toList();
  }

  Future<void> saveGoals(List<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = goals.map((g) => g.toJson()).toList();
    await prefs.setString(_goalsKey, json.encode(jsonList));
  }

  Future<List<Goal>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_goalsKey);
    if (jsonString == null) return [];
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => Goal.fromJson(j)).toList();
  }
}
