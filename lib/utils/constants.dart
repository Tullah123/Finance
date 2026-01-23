import 'package:flutter/material.dart';

class AppConstants {
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Shopping',
    'Transport',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Groceries',
    'Other',
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Business',
    'Gift',
    'Other',
  ];

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bills & utilities':
      case 'bills':
        return Icons.receipt_long;
      case 'healthcare':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'groceries':
        return Icons.shopping_cart;
      case 'salary':
        return Icons.account_balance_wallet;
      case 'freelance':
        return Icons.laptop;
      case 'investment':
        return Icons.trending_up;
      case 'business':
        return Icons.business_center;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.category;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return const Color(0xFFFF6B6B);
      case 'shopping':
        return const Color(0xFFFF8C42);
      case 'transport':
        return const Color(0xFF4ECDC4);
      case 'entertainment':
        return const Color(0xFFFF6B9D);
      case 'bills & utilities':
      case 'bills':
        return const Color(0xFF95E1D3);
      case 'healthcare':
        return const Color(0xFFF38181);
      case 'education':
        return const Color(0xFF6C5CE7);
      case 'groceries':
        return const Color(0xFFFECA57);
      case 'salary':
        return const Color(0xFF00B894);
      case 'freelance':
        return const Color(0xFF0984E3);
      case 'investment':
        return const Color(0xFF6C5CE7);
      case 'business':
        return const Color(0xFFFD79A8);
      case 'gift':
        return const Color(0xFFFFBE76);
      default:
        return const Color(0xFF95A5A6);
    }
  }
}
