import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:wallet/pages/add_card_screen.dart';
import 'package:wallet/pages/settings_page.dart';
import 'package:wallet/screens/barcode_card_details_screen.dart';
import 'package:wallet/screens/summary.dart';
import 'package:wallet/widgets/barcode_card.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import '../models/dataentry.dart';
import '../models/db_helper.dart';
import '../models/provider_helper.dart';
import '../models/theme_provider.dart';
import '../pages/walletdetails.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
      context.read<LoyaltyProvider>().fetchLoyalties();
      context.read<IdentityProvider>().fetchIdentities();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showWalletDeleteConfirmationDialog(
    BuildContext context,
    Wallet wallet,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Card?'),
          content: Text(
            'Are you sure you want to delete "${wallet.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                context.read<WalletProvider>().deleteWallet(wallet.id!);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Card Deleted!')));
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showBarcodeDeleteConfirmationDialog({
    required int id,
    required String name,
    required BarcodeCardType type,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Card?'),
          content: Text(
            'Are you sure you want to delete "$name"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                if (type == BarcodeCardType.loyalty) {
                  context.read<LoyaltyProvider>().deleteLoyalty(id);
                } else {
                  context.read<IdentityProvider>().deleteIdentity(id);
                }
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Card Deleted!')));
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Card number copied!')));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildPaymentsTab(context),
      _buildLoyaltyTab(context),
      _buildIdentityTab(context),
    ];

    return Scaffold(
      appBar: AppBar(
        // FIXED: Added an actions property to place the settings button on the right.
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      // FIXED: Removed the drawer property entirely.
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCardScreen()),
          );
          if (result == true && mounted) {
            context.read<WalletProvider>().fetchWallets();
            context.read<LoyaltyProvider>().fetchLoyalties();
            context.read<IdentityProvider>().fetchIdentities();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.loyalty_outlined),
            label: 'Loyalty',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            label: 'Identity',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset("assets/loading.json", width: 200),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: themeProvider.getTextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);

    if (walletProvider.wallets.isEmpty) {
      return _buildEmptyState(
        context,
        "No credit or debit cards yet.\nTap the '+' to add one.",
      );
    }

    final List<Wallet> filteredWallets = walletProvider.wallets.where((wallet) {
      if (_selectedFilter == 'all') return true;
      return wallet.network?.toLowerCase() == _selectedFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(value: 'all', label: Text('ALL')),
                ButtonSegment<String>(value: 'visa', label: Text('VISA')),
                ButtonSegment<String>(
                  value: 'mastercard',
                  label: Text('MASTERCARD'),
                ),
                ButtonSegment<String>(value: 'rupay', label: Text('RUPAY')),
                ButtonSegment<String>(value: 'amex', label: Text('AMEX')),
                ButtonSegment<String>(
                  value: 'discover',
                  label: Text('DISCOVER'),
                ),
              ],
              showSelectedIcon: false,
              selected: <String>{_selectedFilter},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedFilter = newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                textStyle: const TextStyle(fontFamily: 'Bebas', fontSize: 14),
                backgroundColor: Theme.of(context).cardColor,
                side: BorderSide(color: Colors.grey.withAlpha(51)),
                foregroundColor: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withAlpha(179),
                selectedForegroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimary,
                selectedBackgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        if (filteredWallets.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('No cards match this filter.')),
          )
        else
          Column(
            children: filteredWallets.map((wallet) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: GestureDetector(
                  onLongPress: () =>
                      _showWalletDeleteConfirmationDialog(context, wallet),
                  child: GlassCreditCard(
                    wallet: wallet,
                    isMasked: true,
                    onCardTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WalletDetailScreen(wallet: wallet),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        // FIXED: Added the Summary button here, which will only build if cards exist.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.summarize_outlined),
            label: const Text('View Financial Summary'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Summary()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyTab(BuildContext context) {
    final loyaltyProvider = Provider.of<LoyaltyProvider>(context);
    if (loyaltyProvider.loyalties.isEmpty) {
      return _buildEmptyState(
        context,
        "No loyalty cards added yet.\nTap the '+' to add one.",
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: loyaltyProvider.loyalties.length,
      itemBuilder: (context, index) {
        final loyalty = loyaltyProvider.loyalties[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: BarcodeCard(
            loyalty: loyalty,
            cardType: BarcodeCardType.loyalty,
            onCardTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BarcodeCardDetailScreen(loyalty: loyalty),
              ),
            ),
            onCopyTap: () => _copyToClipboard(loyalty.loyaltyNumber),
            onDeleteTap: () => _showBarcodeDeleteConfirmationDialog(
              id: loyalty.id!,
              name: loyalty.loyaltyName,
              type: BarcodeCardType.loyalty,
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityTab(BuildContext context) {
    final identityProvider = Provider.of<IdentityProvider>(context);
    if (identityProvider.identities.isEmpty) {
      return _buildEmptyState(
        context,
        "No identity cards added yet.\nTap the '+' to add one.",
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: identityProvider.identities.length,
      itemBuilder: (context, index) {
        final identity = identityProvider.identities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: BarcodeCard(
            identity: identity,
            cardType: BarcodeCardType.identity,
            onCardTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BarcodeCardDetailScreen(identity: identity),
              ),
            ),
            onCopyTap: () => _copyToClipboard(identity.identityNumber),
            onDeleteTap: () => _showBarcodeDeleteConfirmationDialog(
              id: identity.id!,
              name: identity.identityName,
              type: BarcodeCardType.identity,
            ),
          ),
        );
      },
    );
  }
}
