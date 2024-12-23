import 'package:flutter/material.dart';
import 'package:wallet/models/db_helper.dart'; // Import your Database Helper and Wallet model

class WalletMaskProvider with ChangeNotifier {
  Map<int, bool> walletMasks = {}; // key: wallet id, value: mask status
  List<Wallet> wallets = []; // List of wallets

  // Fetch wallets from database
  Future<void> fetchWallets() async {
    wallets = await DatabaseHelper.instance
        .getWallets(); // Update the wallet list from database
    notifyListeners();
  }

  // Get the wallet mask state for a specific wallet
  bool isMasked(int walletId) {
    return walletMasks[walletId] ?? true; // Default to masked if not found
  }

  // Toggle the mask state for a specific wallet
  void toggleMask(int walletId) {
    walletMasks[walletId] = !(walletMasks[walletId] ?? true);
    notifyListeners();
  }

  // Add a new wallet and update the list
  void addWallet(Wallet wallet) {
    wallets.add(wallet);
    notifyListeners();
  }
}
