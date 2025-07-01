import 'dart:math';
import 'dart:ui'; // Required for ImageFilter - still needed for some potential future use, or can be removed if not used by any other component

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/screens/summary.dart';
import 'package:wallet/screens/identityscreen.dart';
import 'package:wallet/screens/loyaltyscreen.dart';
import '../models/dataentry.dart';
import '../models/db_helper.dart';
import '../models/provider_helper.dart';
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
    Key? key,
    required this.cardHolderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.network,
    required this.isMasked,
    required this.lastFourDigits,
    required this.onTap,
    required this.onCopy,
  }) : super(key: key);

  // Helper to determine a basic background color based on network
  Color _getCardColor(String networkType) {
    switch (networkType.toLowerCase()) {
      case 'rupay':
        return Colors.blueGrey.shade700;
      case 'visa':
        return Colors.indigo.shade700;
      case 'mastercard':
        return Colors.deepOrange.shade700;
      default:
        return Colors.grey.shade800; // Default dark color
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getCardColor(network);

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
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
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
                    style: TextStyle(
                      fontFamily: 'Bebas', // Assuming Bebas is a simpler font
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
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
                  style: TextStyle(
                    fontFamily: 'ZSpace',
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Image.asset(
                  "assets/network/${network}.png",
                  height: 35,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback for missing network images
                    return Text(
                      network.toUpperCase(),
                      style: TextStyle(color: Colors.white70, fontSize: 14),
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

    Future<void> launchUrlCustom(Uri url) async {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    }

    void removeData(BuildContext context, int id) async {
      await DatabaseHelper.instance.deleteWallet(id);
      context.read<WalletProvider>().fetchWallets(); // Refresh wallet list
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Card Deleted')));
    }

    void copyToClipboard(String text) {
      Clipboard.setData(ClipboardData(text: text))
          .then((_) {
            print('Text copied to clipboard!');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied Card Details'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          })
          .catchError((e) {
            print('Error copying to clipboard: $e');
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
        title: const Icon(
          Icons.wallet,
          size: 34,
          color: Colors
              .white, // Ensure app bar icons are visible on dark background
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: <Widget>[
            const SizedBox(height: 100),
            ListTile(
              leading: const Icon(Icons.fingerprint, color: Colors.white70),
              title: const Text(
                'Identity Cards',
                style: TextStyle(color: Colors.white),
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
              leading: const Icon(Icons.shopping_basket, color: Colors.white70),
              title: const Text(
                'Loyalty Cards',
                style: TextStyle(color: Colors.white),
              ),
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
            const Divider(color: Colors.white30),

            ListTile(
              leading: const Icon(Icons.list, color: Colors.white70),
              title: const Text(
                'Summary',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Summary()),
                );
              },
            ),
            const Divider(color: Colors.white30),
            ListTile(
              title: const Text(
                "Follow on Instagram",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Send Your Suggestions & Feedback",
                style: TextStyle(color: Colors.white70),
              ),
              leading: Image.asset("assets/instaIcon.png", height: 30),
              onTap: () {
                launchUrlCustom(
                  Uri.parse("https://www.instagram.com/wallet.947/"),
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
            context
                .read<WalletProvider>()
                .fetchWallets(); // Refresh wallet list
          }
        },
        backgroundColor: Colors.white.withOpacity(0.8),
        child: const Icon(Icons.add_card, color: Colors.black),
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
                        value: 'other',
                        label: Text(
                          'Amex',
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
                      foregroundColor: Colors.white,
                      selectedForegroundColor: Colors.black,
                      selectedBackgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30, width: 0.8),
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
                          style: TextStyle(color: Colors.white70, fontSize: 16),
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
                                  foregroundColor: Colors.white,
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
                                  foregroundColor: Colors.white,
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
