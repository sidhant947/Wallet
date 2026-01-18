import 'package:flutter/material.dart';
import 'package:wallet/models/db_helper.dart'; // Import your Database Helper and Wallet model

class WalletSummary {
  final double totalLimit;
  final double totalSpends;
  final double totalCashback;
  final double utilization;
  final List<Wallet> incompleteCards;
  final Map<String, int> networkCounts;
  final Map<String, int> issuerCounts;
  final Map<String, int> cardTypeCounts;
  final List<Map<String, dynamic>> upcomingBills;
  final Wallet? topCashbackCard;
  final Wallet? highestLimitCard;
  final List<Wallet> feeWaiverCards;

  WalletSummary({
    required this.totalLimit,
    required this.totalSpends,
    required this.totalCashback,
    required this.utilization,
    required this.incompleteCards,
    required this.networkCounts,
    required this.issuerCounts,
    required this.cardTypeCounts,
    required this.upcomingBills,
    this.topCashbackCard,
    this.highestLimitCard,
    required this.feeWaiverCards,
  });

  factory WalletSummary.empty() => WalletSummary(
    totalLimit: 0,
    totalSpends: 0,
    totalCashback: 0,
    utilization: 0,
    incompleteCards: [],
    networkCounts: {},
    issuerCounts: {},
    cardTypeCounts: {},
    upcomingBills: [],
    feeWaiverCards: [],
  );
}

class WalletProvider with ChangeNotifier {
  Map<int, bool> walletMasks = {};
  List<Wallet> wallets = [];
  WalletSummary? _cachedSummary;

  WalletSummary get summary => _cachedSummary ?? _calculateSummary();

  WalletSummary _calculateSummary() {
    double limitTotal = 0;
    double spendsTotal = 0;
    double cashbackTotal = 0;
    List<Wallet> incomplete = [];
    Map<String, int> networks = {};
    Map<String, int> issuers = {};
    Map<String, int> types = {};
    List<Map<String, dynamic>> bills = [];
    List<Wallet> waivers = [];
    Wallet? topCashback;
    Wallet? topLimit;

    for (var wallet in wallets) {
      final l = double.tryParse(wallet.maxlimit ?? '0') ?? 0;
      final s = double.tryParse(wallet.spends ?? '0') ?? 0;
      final r = double.tryParse(wallet.rewards ?? '0') ?? 0;
      final w = double.tryParse(wallet.annualFeeWaiver ?? '0') ?? 0;
      final b = int.tryParse(wallet.billdate ?? '');

      limitTotal += l;
      spendsTotal += s;
      cashbackTotal += (s * r) / 100;

      if ((wallet.maxlimit ?? '').isEmpty ||
          (wallet.spends ?? '').isEmpty ||
          (wallet.rewards ?? '').isEmpty ||
          (wallet.billdate ?? '').isEmpty) {
        incomplete.add(wallet);
      }

      if ((wallet.network ?? '').isNotEmpty) {
        networks.update(
          wallet.network!.toUpperCase(),
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
      if ((wallet.issuer ?? '').isNotEmpty) {
        issuers.update(wallet.issuer!, (v) => v + 1, ifAbsent: () => 1);
      }
      if ((wallet.cardtype ?? '').isNotEmpty) {
        types.update(wallet.cardtype!, (v) => v + 1, ifAbsent: () => 1);
      }

      if (topCashback == null ||
          r > (double.tryParse(topCashback.rewards ?? '0') ?? 0)) {
        topCashback = wallet;
      }
      if (topLimit == null ||
          l > (double.tryParse(topLimit.maxlimit ?? '0') ?? 0)) {
        topLimit = wallet;
      }
      if (w > 0) waivers.add(wallet);
      if (b != null) bills.add({'wallet': wallet, 'date': b});
    }

    final today = DateTime.now().day;
    bills.sort((a, b) {
      int dA = a['date'];
      int dB = b['date'];
      int diffA = dA >= today ? dA - today : dA + 30 - today;
      int diffB = dB >= today ? dB - today : dB + 30 - today;
      return diffA.compareTo(diffB);
    });

    _cachedSummary = WalletSummary(
      totalLimit: limitTotal,
      totalSpends: spendsTotal,
      totalCashback: cashbackTotal,
      utilization: limitTotal > 0 ? (spendsTotal / limitTotal) : 0,
      incompleteCards: incomplete,
      networkCounts: networks,
      issuerCounts: issuers,
      cardTypeCounts: types,
      upcomingBills: bills,
      topCashbackCard: topCashback,
      highestLimitCard: topLimit,
      feeWaiverCards: waivers,
    );
    return _cachedSummary!;
  }

  Future<void> fetchWallets() async {
    wallets = await DatabaseHelper.instance.getWallets();
    _cachedSummary = null; // Invalidate cache
    notifyListeners();
  }

  Future<void> deleteWallet(int id) async {
    await DatabaseHelper.instance.deleteWallet(id);
    await fetchWallets();
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
    _cachedSummary = null; // Invalidate cache
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
