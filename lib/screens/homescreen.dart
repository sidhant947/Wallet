// lib/screens/homescreen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/pages/settings_page.dart';
import 'package:wallet/screens/summary.dart';
import 'package:wallet/screens/identityscreen.dart';
import 'package:wallet/screens/loyaltyscreen.dart';
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
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
    });
  }

  Future<void> launchUrlCustom(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void removeData(BuildContext context, int id) async {
    // Capture context-dependent objects before the async gap
    final provider = context.read<WalletProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    await DatabaseHelper.instance.deleteWallet(id);

    // Use the captured objects after the await.
    // The 'mounted' check is still a good practice.
    if (mounted) {
      provider.fetchWallets();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Card Deleted',
            style: TextStyle(color: theme.colorScheme.onSecondary),
          ),
          backgroundColor: theme.colorScheme.secondary,
        ),
      );
    }
  }

  void copyToClipboard(String text) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Card number copied',
            style: TextStyle(color: theme.colorScheme.onSecondary),
          ),
          backgroundColor: theme.colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);

    List<Wallet> filteredWallets = walletProvider.wallets.where((wallet) {
      if (_selectedFilter == 'all') return true;
      return wallet.network?.toLowerCase() == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Icon(
          Icons.wallet_outlined,
          size: 34,
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const SizedBox(height: 100),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: Text('Credit Cards', style: themeProvider.getTextStyle()),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_basket_outlined),
              title: Text('Loyalty Cards', style: themeProvider.getTextStyle()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoyaltyScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: Text(
                'Identity Cards',
                style: themeProvider.getTextStyle(),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IdentityScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.summarize_outlined),
              title: Text('Summary', style: themeProvider.getTextStyle()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Summary()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text('Settings', style: themeProvider.getTextStyle()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(
                "Donate on Github",
                style: themeProvider.getTextStyle(),
              ),
              onTap: () => launchUrlCustom(
                Uri.parse("https://github.com/sidhant947/Wallet"),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Capture provider before the async gap
          final provider = context.read<WalletProvider>();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DataEntryScreen()),
          );
          if (result == true && mounted) {
            provider.fetchWallets();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
                  // This textStyle applies the Bebas font to all segments
                  textStyle: const TextStyle(fontFamily: 'Bebas', fontSize: 14),
                  backgroundColor: Theme.of(context).cardColor,
                  side: BorderSide(color: Colors.grey.withAlpha(51)),
                  foregroundColor: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.color?.withAlpha(179),
                  selectedForegroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimary,
                  selectedBackgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredWallets.isEmpty
                ? Center(
                    child: walletProvider.wallets.isEmpty
                        ? Lottie.asset("assets/empty.json", width: 200)
                        : Text(
                            'No cards match this filter.',
                            style: themeProvider.getTextStyle(
                              color: Colors.grey,
                            ),
                          ),
                  )
                : AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: filteredWallets.length,
                      itemBuilder: (context, index) {
                        var wallet = filteredWallets[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              // ** FIXED ** Wrapped the Slidable in a SizedBox for fixed height
                              child: SizedBox(
                                height:
                                    235, // Adjust this value to fit your card perfectly
                                child: Slidable(
                                  key: ValueKey(wallet.id),
                                  startActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.25,
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) => walletProvider
                                            .toggleMask(wallet.id!),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                        icon:
                                            walletProvider.isMasked(wallet.id!)
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          bottomLeft: Radius.circular(20),
                                        ),
                                      ),
                                    ],
                                  ),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.25,
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) =>
                                            removeData(context, wallet.id!),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete_outline,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: GlassCreditCard(
                                    wallet: wallet,
                                    isMasked: walletProvider.isMasked(
                                      wallet.id!,
                                    ),
                                    onCardTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            WalletDetailScreen(wallet: wallet),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
