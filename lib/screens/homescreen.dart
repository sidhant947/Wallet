import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/pages/settings_page.dart';
import 'package:wallet/screens/summary.dart';
import 'package:wallet/screens/identityscreen.dart';
import 'package:wallet/screens/loyaltyscreen.dart';
import '../models/dataentry.dart';
import '../models/db_helper.dart';
import '../models/provider_helper.dart';
import '../models/theme_provider.dart';
import '../pages/walletdetails.dart';

// -----------------------------------------------------------------------------
// Simplified Card Design Component
// -----------------------------------------------------------------------------
class SimpleCard extends StatelessWidget {
  final String cardHolderName;
  final String cardNumber;
  final String expiryDate;
  final String network;
  final bool isMasked;
  final String lastFourDigits;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const SimpleCard({
    super.key,
    required this.cardHolderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.network,
    required this.isMasked,
    required this.lastFourDigits,
    required this.onTap,
    required this.onCopy,
  });

  // Helper to determine a basic background color based on network
  Color _getCardColor(String networkType) {
    switch (networkType.toLowerCase()) {
      case 'rupay':
        return Colors.pinkAccent.shade700;
      case 'visa':
        return Colors.cyan.shade700;
      case 'mastercard':
        return Colors.deepOrange.shade700;
      default:
        return Colors.black; // Default dark color
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getCardColor(network);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.250,
        decoration: BoxDecoration(
          color: cardColor, // Simple solid color background
          borderRadius: BorderRadius.circular(12), // Slightly rounded corners
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    cardHolderName,
                    style: themeProvider.getTextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.wifi, // Generic card icon
                  color: Colors.white,
                  size: 30,
                ),
              ],
            ),
            GestureDetector(
              onTap: onCopy,
              child: Text(
                isMasked ? "XXXX XXXX XXXX $lastFourDigits" : cardNumber,
                style: TextStyle(
                  fontFamily:
                      'ZSpace', // Assuming ZSpace is a monospace-like font
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMasked ? "MM/YY" : expiryDate,
                  style: const TextStyle(
                    fontFamily: 'ZSpace',
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Image.asset(
                  "assets/network/$network.png",
                  height: 35,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback for missing network images
                    return Text(
                      network.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HomeScreen - Your main screen with integrated standard cards and filters
// -----------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'all'; // Default filter

  @override
  Widget build(BuildContext context) {
    // Fetch wallets when the screen is first built
    context.read<WalletProvider>().fetchWallets();
    final themeProvider = Provider.of<ThemeProvider>(context);

    Future<void> launchUrlCustom(Uri url) async {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    }

    void removeData(BuildContext context, int id) async {
      await DatabaseHelper.instance.deleteWallet(id);
      if (mounted) {
        context.read<WalletProvider>().fetchWallets(); // Refresh wallet list
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Card Deleted')));
      }
    }

    void copyToClipboard(String text) {
      Clipboard.setData(ClipboardData(text: text))
          .then((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied Card Details'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          })
          .catchError((e) {
            // Handle error silently or use a proper logging framework
          });
    }

    String formatCardNumber(String input) {
      StringBuffer result = StringBuffer();
      int count = 0;

      for (int i = 0; i < input.length; i++) {
        result.write(input[i]);
        count++;

        if (count == 4 && i != input.length - 1) {
          result.write(' ');
          count = 0;
        }
      }

      return result.toString();
    }

    String formatExpiryNumber(String input) {
      StringBuffer result = StringBuffer();
      int count = 0;

      for (int i = 0; i < input.length; i++) {
        result.write(input[i]);
        count++;

        if (count == 2 && i != input.length - 1) {
          result.write(' / ');
          count = 0;
        }
      }

      return result.toString();
    }

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Icon(Icons.wallet, size: 34, color: themeProvider.primaryColor),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      drawer: Drawer(
        backgroundColor: themeProvider.backgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: <Widget>[
            const SizedBox(height: 100),
            ListTile(
              leading: Icon(
                Icons.fingerprint,
                color: themeProvider.secondaryColor,
              ),
              title: Text(
                'Identity Cards',
                style: themeProvider.getTextStyle(),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IdentityScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.shopping_basket,
                color: themeProvider.secondaryColor,
              ),
              title: Text('Loyalty Cards', style: themeProvider.getTextStyle()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoyaltyScreen(),
                  ),
                );
              },
            ),
            Divider(color: themeProvider.borderColor),

            ListTile(
              leading: Icon(Icons.list, color: themeProvider.secondaryColor),
              title: Text('Summary', style: themeProvider.getTextStyle()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Summary()),
                );
              },
            ),
            Divider(color: themeProvider.borderColor),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: themeProvider.secondaryColor,
              ),
              title: Text('Settings', style: themeProvider.getTextStyle()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),

            Divider(color: themeProvider.borderColor),
            ListTile(
              title: Text(
                "Donate on Github",
                style: themeProvider.getTextStyle(),
              ),
              subtitle: Text(
                "Leave a Star on Repo",
                style: themeProvider.getTextStyle(
                  fontSize: 14,
                  color: themeProvider.secondaryColor,
                ),
              ),
              leading: Icon(Icons.star),
              onTap: () {
                launchUrlCustom(
                  Uri.parse("https://github.com/sidhant947/Wallet"),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DataEntryScreen()),
          );

          if (result != null) {
            // After adding a card, update the wallet list in the provider
            if (mounted) {
              context
                  .read<WalletProvider>()
                  .fetchWallets(); // Refresh wallet list
            }
          }
        },
        backgroundColor: themeProvider.accentColor,
        child: Icon(
          Icons.add_card,
          color: themeProvider.isDarkMode ? Colors.white : Colors.white,
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          // Filter the wallets based on the selected filter
          List<Wallet> filteredWallets = provider.wallets.where((wallet) {
            if (_selectedFilter == 'all') {
              return true;
            } else if (_selectedFilter == 'other') {
              return ![
                'visa',
                'mastercard',
                'rupay',
                'amex',
                'discover',
              ].contains(wallet.network?.toLowerCase());
            } else {
              return wallet.network?.toLowerCase() == _selectedFilter;
            }
          }).toList();

          if (provider.wallets.isEmpty) {
            return Center(child: Lottie.asset("assets/loading.json"));
          }

          return Column(
            children: [
              // Filter options - now wrapped in a SingleChildScrollView
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'all',
                        label: Text('All', softWrap: false), // Prevent wrapping
                      ),
                      ButtonSegment<String>(
                        value: 'visa',
                        label: Text(
                          'Visa',
                          softWrap: false,
                        ), // Prevent wrapping
                      ),
                      ButtonSegment<String>(
                        value: 'mastercard',
                        label: Text(
                          'Mastercard',
                          softWrap: false,
                        ), // Prevent wrapping
                      ),
                      ButtonSegment<String>(
                        value: 'rupay',
                        label: Text(
                          'Rupay',
                          softWrap: false,
                        ), // Prevent wrapping
                      ),
                      ButtonSegment<String>(
                        value: 'amex',
                        label: Text(
                          'Amex',
                          softWrap: false,
                        ), // Prevent wrapping
                      ),
                      ButtonSegment<String>(
                        value: 'discover',
                        label: Text(
                          'Discover',
                          softWrap: false,
                        ), // Prevent wrapping
                      ),
                    ],
                    selected: <String>{_selectedFilter},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedFilter = newSelection.first;
                      });
                    },
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      foregroundColor: themeProvider.primaryColor,
                      selectedForegroundColor: themeProvider.isDarkMode
                          ? Colors.black
                          : Colors.white,
                      selectedBackgroundColor: themeProvider.primaryColor,
                      side: BorderSide(
                        color: themeProvider.borderColor,
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      // Fixed minimum size for each button
                      minimumSize: const Size(
                        100,
                        40,
                      ), // Example: Width 100, Height 40
                      // No explicit padding here, letting minimumSize control the box
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredWallets.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_selectedFilter == 'all' ? '' : _selectedFilter} cards found.',
                          style: themeProvider.getTextStyle(
                            fontSize: 16,
                            color: themeProvider.secondaryColor,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredWallets.length,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          var wallet =
                              filteredWallets[index]; // Use filteredWallets

                          String formattedNumber = formatCardNumber(
                            wallet.number,
                          );

                          String masknumber = wallet.number.substring(
                            wallet.number.length - 4,
                          );

                          String formattedExpiry = formatExpiryNumber(
                            wallet.expiry,
                          );

                          return Slidable(
                            key: ValueKey(wallet.id),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (BuildContext context) {
                                    removeData(context, wallet.id!);
                                  },
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: themeProvider.primaryColor,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                            startActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (BuildContext context) {
                                    provider.toggleMask(
                                      wallet.id!,
                                    ); // Toggle the mask
                                  },
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: themeProvider.primaryColor,
                                  icon: provider.isMasked(wallet.id!)
                                      ? Icons.visibility
                                      : Icons.visibility_off_rounded,
                                  label: provider.isMasked(wallet.id!)
                                      ? "Show"
                                      : "Hide",
                                ),
                              ],
                            ),
                            child: SimpleCard(
                              // Changed to SimpleCard
                              cardHolderName: wallet.name,
                              cardNumber: formattedNumber,
                              expiryDate: formattedExpiry,
                              network: wallet.network ?? "N/A",
                              isMasked: provider.isMasked(wallet.id!),
                              lastFourDigits: masknumber,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WalletDetailScreen(wallet: wallet),
                                  ),
                                );
                              },
                              onCopy: () {
                                copyToClipboard(wallet.number);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// NOTE: _FuturisticPatternPainter is no longer used, can be removed if desired
// if no other part of your app uses it.
