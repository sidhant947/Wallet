// lib/screens/identityscreen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/pages/settings_page.dart';
import 'package:wallet/screens/homescreen.dart';
import 'package:wallet/screens/loyaltyscreen.dart';
import 'package:wallet/widgets/barcode_card.dart';
import 'package:wallet/widgets/display_barcode_screen.dart';
import '../models/dataentry.dart';
import '../models/theme_provider.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  List<Identity>? _identities;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIdentities();
  }

  Future<void> _loadIdentities() async {
    try {
      final loadedIdentities = await IdentityDatabaseHelper.instance
          .getAllIdentities();
      if (mounted) {
        setState(() {
          _identities = loadedIdentities;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading identities: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _identities = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load identity cards.')),
        );
      }
    }
  }

  void _removeData(BuildContext context, int id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await IdentityDatabaseHelper.instance.deleteIdentity(id);
      await _loadIdentities();

      messenger.showSnackBar(
        const SnackBar(content: Text('Identity card deleted!')),
      );
    } catch (e) {
      debugPrint('Error deleting identity: $e');

      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete identity card.')),
      );
    }
  }

  void _copyToClipboard(String text) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(
      const SnackBar(content: Text('Identity number copied!')),
    );
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
      appBar: AppBar(title: const Text("Identity Cards")),
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
                cardType: BarcodeCardType.identity,
              ),
            ),
          );
          if (result == true) {
            _loadIdentities();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _identities == null || _identities!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset("assets/empty.json", width: 200),
                  const SizedBox(height: 20),
                  Text(
                    "No identity cards yet.",
                    style: themeProvider.getTextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _identities!.length,
                itemBuilder: (context, index) {
                  final identity = _identities![index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: SizedBox(
                          height: 220, // Taller for identity card layout
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Slidable(
                              key: ValueKey(identity.id),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                extentRatio: 0.25,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) =>
                                        _removeData(context, identity.id!),
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
                                cardName: identity.identityName,
                                cardNumber: identity.identityNumber,
                                cardType: BarcodeCardType.identity,
                                onCardTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DisplayBarcodeScreen(
                                            barcodeData:
                                                identity.identityNumber,
                                            cardName: identity.identityName,
                                          ),
                                    ),
                                  );
                                },
                                onBarcodeIconTap: () =>
                                    _copyToClipboard(identity.identityNumber),
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
