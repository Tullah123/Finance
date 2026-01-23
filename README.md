# finance_app

Personal finance tracker built with Flutter.

## Features

- Splash screen with animated branding.
- Bottom navigation for Dashboard, Transactions, Budgets, Goals, and Reports.
- Dashboard overview with all-time balance, monthly income/expense, and recent activity.
- Transactions: add, edit, delete, and view details with notes, categories, and date/time.
- Transaction sorting (date/amount) and filtering (all/income/expense).
- Budgets by category with monthly selection, progress tracking, and remaining/spent stats.
- Budget management: create, edit, and delete.
- Goals tracking with progress, deadlines, add-money flow, and delete.
- Reports with month/year views, summary cards, savings rate, and category pie chart.
- Reminders with near-expiry, on-expiry, and follow-up notifications.
- Local data persistence using SharedPreferences.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Reminder Notifications (Testing)

1) Run the app on a physical device or emulator.
2) Open the Reminders tab and create a reminder a few minutes in the future.
3) Allow notification permissions when prompted.
4) Confirm three notifications: near expiry, on expiry, and follow-up.
5) Edit/disable/complete a reminder to verify notifications are rescheduled or canceled.
