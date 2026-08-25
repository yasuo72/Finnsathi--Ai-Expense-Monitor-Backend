import 'package:flutter/material.dart';
import 'wallet/wallet_screen.dart';

/// Wallet Screen
/// 
/// This file acts as a wrapper to maintain compatibility with existing routes
/// The actual implementation is in the wallet/wallet_screen.dart file
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Return the modern wallet screen implementation
    return const ModernWalletScreen();
  }
}
