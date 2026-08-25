import 'package:flutter/material.dart';
import 'wallet/wallet_password_screen.dart';
import 'add_savings_goal_screen.dart';
import 'add_budget_screen.dart';
import 'savings_goal_screen.dart';

class HomeActions {
  static void onProfileTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile tapped! (Navigate to Profile page)')),
    );
    // Navigator.pushNamed(context, '/profile');
  }

  static void onNotificationTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications tapped!')),
    );
  }

  static void onBalanceEyeTap(BuildContext context, VoidCallback toggle) {
    toggle();
  }

  static void onWalletTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletPasswordScreen()),
    );
  }

  static void onBudgetMoreTap(BuildContext context) {
    // Navigate to add budget screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
    );
  }

  static void onSavingsMoreTap(BuildContext context) {
    // Navigate to savings goal screen with detailed view and add new goal functionality
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavingsGoalScreen(),
      ),
    );
  }

  static void onAddSavingsTap(BuildContext context) {
    // Navigate to add savings goal screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSavingsGoalScreen()),
    );
  }

  static void onSavingsTap(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Savings tapped: $title')),
    );
  }

  static void onTransactionTap(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction tapped: $title')),
    );
  }

  static void onTransactionsMoreTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transactions: More tapped!')),
    );
  }

  static void onIncomeTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Income tapped!')),
    );
  }

  static void onOutcomeTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outcome tapped!')),
    );
  }
}
