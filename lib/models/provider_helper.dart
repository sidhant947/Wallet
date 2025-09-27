import 'package:flutter/material.dart';
import 'package:wallet/models/db_helper.dart'; // Import your Database Helper and Wallet model

class WalletProvider with ChangeNotifier {
  Map<int, bool> walletMasks = {};
  List<Wallet> wallets = [];

  Future<void> fetchWallets() async {
    wallets = await DatabaseHelper.instance.getWallets();
    notifyListeners();
  }

  // NEW: Method to delete a wallet
  Future<void> deleteWallet(int id) async {
    await DatabaseHelper.instance.deleteWallet(id);
    await fetchWallets(); // Refresh the list
  }

  bool isMasked(int walletId) {
    return walletMasks[walletId] ?? true;
  }

  void toggleMask(int walletId) {
    walletMasks[walletId] = !(walletMasks[walletId] ?? true);
    notifyListeners();
  }

  void addWallet(Wallet wallet) {
    wallets.add(wallet);
    notifyListeners();
  }
}

class LoyaltyProvider with ChangeNotifier {
  List<Loyalty> loyalties = [];

  Future<void> fetchLoyalties() async {
    loyalties = await LoyaltyDatabaseHelper.instance.getAllLoyalties();
    notifyListeners();
  }

  Future<void> deleteLoyalty(int id) async {
    await LoyaltyDatabaseHelper.instance.deleteLoyalty(id);
    await fetchLoyalties();
  }
}

class IdentityProvider with ChangeNotifier {
  List<Identity> identities = [];

  Future<void> fetchIdentities() async {
    identities = await IdentityDatabaseHelper.instance.getAllIdentities();
    notifyListeners();
  }

  Future<void> deleteIdentity(int id) async {
    await IdentityDatabaseHelper.instance.deleteIdentity(id);
    await fetchIdentities();
  }
}
