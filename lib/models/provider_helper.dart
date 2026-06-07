import 'package:flutter/material.dart';
import 'package:wallet/models/db_helper.dart'; // Import your Database Helper and Wallet model

class WalletProvider with ChangeNotifier {
  Map<int, bool> walletMasks = {};
  List<Wallet> wallets = [];

  Future<void> fetchWallets() async {
    wallets = await DatabaseHelper.instance.getWallets();
    notifyListeners();
  }

  Future<void> deleteWallet(int id) async {
    await DatabaseHelper.instance.deleteWallet(id);
    wallets.removeWhere((w) => w.id == id);
    notifyListeners();
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

  Future<void> reorderWallets(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final wallet = wallets.removeAt(oldIndex);
    wallets.insert(newIndex, wallet);

    // Update order indices internally
    for (int i = 0; i < wallets.length; i++) {
      wallets[i].orderIndex = i;
    }

    await DatabaseHelper.instance.updateWalletsOrder(wallets);
    notifyListeners();
  }
}

class PassProvider with ChangeNotifier {
  List<Pass> passes = [];

  Future<void> fetchPasses() async {
    passes = await PassDatabaseHelper.instance.getAllPasses();
    notifyListeners();
  }

  Future<void> deletePass(int id) async {
    await PassDatabaseHelper.instance.deletePass(id);
    passes.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> updatePass(Pass updatedPass) async {
    await PassDatabaseHelper.instance.updatePass(updatedPass);
    final index = passes.indexWhere((p) => p.id == updatedPass.id);
    if (index != -1) {
      passes[index] = updatedPass;
      notifyListeners();
    }
  }

  Future<void> reorderPasses(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final pass = passes.removeAt(oldIndex);
    passes.insert(newIndex, pass);

    // Update order indices internally
    for (int i = 0; i < passes.length; i++) {
      passes[i].orderIndex = i;
    }

    await PassDatabaseHelper.instance.updatePassesOrder(passes);
    notifyListeners();
  }

  /// Deep search through all pass fields
  List<Pass> searchPasses(String query) {
    if (query.isEmpty) return passes;
    final lowercaseQuery = query.toLowerCase();

    return passes.where((pass) {
      // Basic fields
      if (pass.organizationName.toLowerCase().contains(lowercaseQuery)) return true;
      if (pass.description?.toLowerCase().contains(lowercaseQuery) ?? false) return true;
      if (pass.logoText?.toLowerCase().contains(lowercaseQuery) ?? false) return true;
      if (pass.barcodeValue.toLowerCase().contains(lowercaseQuery)) return true;
      if (pass.barcodeAltText?.toLowerCase().contains(lowercaseQuery) ?? false) return true;

      // Search through dynamic fields
      if (pass.fields != null) {
        for (final section in pass.fields!.values) {
          if (section is List) {
            for (final field in section) {
              if (field is Map) {
                final label = field['label']?.toString().toLowerCase() ?? '';
                final value = field['value']?.toString().toLowerCase() ?? '';
                if (label.contains(lowercaseQuery) || value.contains(lowercaseQuery)) {
                  return true;
                }
              }
            }
          }
        }
      }
      return false;
    }).toList();
  }
}

class IdentityProvider with ChangeNotifier {
  List<IdentityCard> identities = [];

  Future<void> fetchIdentities() async {
    identities = await IdentityDatabaseHelper.instance.getAllIdentities();
    notifyListeners();
  }

  Future<void> deleteIdentity(int id) async {
    await IdentityDatabaseHelper.instance.deleteIdentity(id);
    identities.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  Future<void> addIdentity(IdentityCard card) async {
    identities.add(card);
    notifyListeners();
  }

  Future<void> updateIdentity(IdentityCard updatedCard) async {
    await IdentityDatabaseHelper.instance.updateIdentity(updatedCard);
    final index = identities.indexWhere((i) => i.id == updatedCard.id);
    if (index != -1) {
      identities[index] = updatedCard;
      notifyListeners();
    }
  }

  Future<void> reorderIdentities(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final card = identities.removeAt(oldIndex);
    identities.insert(newIndex, card);

    for (int i = 0; i < identities.length; i++) {
      identities[i].orderIndex = i;
    }

    await IdentityDatabaseHelper.instance.updateIdentitiesOrder(identities);
    notifyListeners();
  }

  List<IdentityCard> searchIdentities(String query) {
    if (query.isEmpty) return identities;
    final lowercaseQuery = query.toLowerCase();

    return identities.where((card) {
      return card.name.toLowerCase().contains(lowercaseQuery) ||
          card.value.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}

