import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'finance_service.dart';

class WalletService extends ChangeNotifier {
  List<Map<String, dynamic>> _cards = [];
  double _cashAmount = 0.0; // Start with zero cash
  String _walletPassword = '1234'; // Default password
  bool _isAuthenticated = false;
  FinanceService? _financeService;

  List<Map<String, dynamic>> get cards => _cards;
  double get cashAmount => _cashAmount;
  double get cardsTotalAmount => _calculateCardsTotalAmount();
  double get totalBalance => _cashAmount + _calculateCardsTotalAmount();
  bool get isAuthenticated => _isAuthenticated;
  
  WalletService() {
    _loadWalletData();
  }
  
  // Set the finance service reference
  void setFinanceService(FinanceService financeService) {
    _financeService = financeService;
    // Don't immediately sync to avoid circular updates during build
    // Instead, schedule a microtask to run after the build is complete
    Future.microtask(() {
      _syncBalancesWithFinanceService();
    });
  }
  
  // Sync wallet balances with finance service
  void _syncBalancesWithFinanceService() {
    if (_financeService != null) {
      _financeService!.updateWalletBalances(_cashAmount, _calculateCardsTotalAmount());
    }
  }



  Future<void> _loadWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load password
      final savedPassword = prefs.getString('wallet_password');
      if (savedPassword != null) {
        _walletPassword = savedPassword;
      }
      
      // Load cash amount
      final savedCashAmount = prefs.getDouble('wallet_cash_amount');
      if (savedCashAmount != null) {
        _cashAmount = savedCashAmount;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
    }
  }

  Future<void> _saveWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save password
      await prefs.setString('wallet_password', _walletPassword);
      
      // Save cash amount
      await prefs.setDouble('wallet_cash_amount', _cashAmount);
    } catch (e) {
      debugPrint('Error saving wallet data: $e');
    }
  }

  double _calculateCardsTotalAmount() {
    double total = 0;
    for (var card in _cards) {
      if (card.containsKey('balanceValue')) {
        total += card['balanceValue'] as double;
      }
    }
    return total;
  }

  void addCard(Map<String, dynamic> cardData) {
    // Extract numeric value from the balance string
    final balanceStr = cardData['balance'] as String;
    final numericString = balanceStr.replaceAll('₹', '').replaceAll(',', '');
    try {
      final balanceValue = double.parse(numericString);
      cardData['balanceValue'] = balanceValue;
    } catch (e) {
      debugPrint('Error parsing balance: $e');
    }
    
    _cards.add(cardData);
    _syncBalancesWithFinanceService();
    notifyListeners();
  }

  void removeCard(int index) {
    if (index >= 0 && index < _cards.length) {
      _cards.removeAt(index);
      _syncBalancesWithFinanceService();
      notifyListeners();
    }
  }

  void updateCashAmount(double amount) {
    _cashAmount = amount;
    _saveWalletData();
    
    // Sync with finance service
    _syncBalancesWithFinanceService();
    
    notifyListeners();
  }

  void addCashAmount(double amount) {
    _cashAmount += amount;
    _saveWalletData();
    
    // Sync with finance service
    _syncBalancesWithFinanceService();
    
    notifyListeners();
  }

  bool verifyPassword(String password) {
    if (password == _walletPassword) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void updatePassword(String newPassword) {
    _walletPassword = newPassword;
    _saveWalletData();
    notifyListeners();
  }
  
  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
