// lib/screens/loyaltyscreen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/pages/settings_page.dart';
import 'package:wallet/screens/homescreen.dart';
import 'package:wallet/screens/identityscreen.dart';
import 'package:wallet/widgets/barcode_card.dart';
import 'package:wallet/widgets/display_barcode_screen.dart';
import '../models/dataentry.dart';
import '../models/db_helper.dart';
import '../models/theme_provider.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  List<Loyalty>? _loyalties;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoyalties();
  }

  Future<void> _loadLoyalties() async {
    try {
      final loadedLoyalties = await LoyaltyDatabaseHelper.instance
          .getAllLoyalties();
      if (mounted) {
        setState(() {
          _loyalties = loadedLoyalties.cast<Loyalty>();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading loyalty cards: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loyalties = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load loyalty cards.')),
        );
      }
    }
  }

  void _removeData(BuildContext context, int id) async {
    try {
      await LoyaltyDatabaseHelper.instance.deleteLoyalty(id);
      await _loadLoyalties();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Loyalty card deleted!')));
      }
    } catch (e) {
      print('Error deleting loyalty card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete loyalty card.')),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Loyalty number copied!')));
      }
    });
  }

  Future<void> launchUrlCustom(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Loyalty Cards")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const SizedBox(height: 100),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: Text('Credit Cards', style: themeProvider.getTextStyle()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
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
            ListTile(
              leading: const Icon(Icons.shopping_basket_outlined),
              title: Text('Loyalty Cards', style: themeProvider.getTextStyle()),
              onTap: () => Navigator.pop(context),
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
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BarcodeDataEntryScreen(
                cardType: BarcodeCardType.loyalty,
              ),
            ),
          );
          if (result == true) {
            _loadLoyalties();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loyalties == null || _loyalties!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset("assets/empty.json", width: 200),
                  const SizedBox(height: 20),
                  Text(
                    "No loyalty cards yet.",
                    style: themeProvider.getTextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _loyalties!.length,
                itemBuilder: (context, index) {
                  final loyalty = _loyalties![index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: SizedBox(
                          height: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Slidable(
                              key: ValueKey(loyalty.id),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                extentRatio: 0.25,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) =>
                                        _removeData(context, loyalty.id!),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_outline,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ],
                              ),
                              child: BarcodeCard(
                                cardName: loyalty.loyaltyName,
                                cardNumber: loyalty.loyaltyNumber,
                                cardType: BarcodeCardType.loyalty,
                                onCardTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DisplayBarcodeScreen(
                                            barcodeData: loyalty.loyaltyNumber,
                                            cardName: loyalty.loyaltyName,
                                          ),
                                    ),
                                  );
                                },
                                onBarcodeIconTap: () =>
                                    _copyToClipboard(loyalty.loyaltyNumber),
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
    );
  }
}
