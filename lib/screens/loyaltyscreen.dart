import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/pages/settings_page.dart';
import 'package:wallet/screens/homescreen.dart';
import 'package:wallet/screens/identityscreen.dart';
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

  /// Loads loyalty cards from the SQLite database.
  Future<void> _loadLoyalties() async {
    try {
      final loadedLoyalties = await LoyaltyDatabaseHelper.instance
          .getAllLoyalties();
      setState(() {
        _loyalties = loadedLoyalties.cast<Loyalty>();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading loyalty cards: $e');
      setState(() {
        _isLoading = false;
        _loyalties = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load loyalty cards.')),
        );
      }
    }
  }

  /// Removes a loyalty card from the database and reloads the list.
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

  Future<void> launchUrlCustom(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  /// Copies text to the clipboard.
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text))
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Loyalty number copied!')),
            );
          }
        })
        .catchError((e) {
          print('Error copying to clipboard: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to copy loyalty number.')),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Loyalty Cards",
          style: themeProvider.getTextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: themeProvider.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.primaryColor),
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
                Icons.credit_card,
                color: themeProvider.secondaryColor,
              ),
              title: Text('Credit Cards', style: themeProvider.getTextStyle()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
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
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoyaltyDataEntryScreen()),
          );
          if (result == true) {
            _loadLoyalties();
          }
        },
        backgroundColor: themeProvider.accentColor,
        child: Icon(Icons.add_card, color: themeProvider.backgroundColor),
      ),
      body: _isLoading
          ? Center(
              child: Lottie.asset(
                "assets/loading.json",
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            )
          : _loyalties!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    "assets/empty.json",
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No loyalty cards yet!",
                    style: themeProvider.getTextStyle(
                      fontSize: 18,
                      color: themeProvider.secondaryColor,
                    ),
                  ),
                  Text(
                    "Tap '+' to add a new one.",
                    style: themeProvider.getTextStyle(
                      fontSize: 14,
                      color: themeProvider.secondaryColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _loyalties!.length,
              itemBuilder: (context, index) {
                final loyalty = _loyalties![index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Slidable(
                    key: ValueKey(loyalty.id),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (BuildContext context) =>
                              _removeData(context, loyalty.id!),
                          backgroundColor: Colors.redAccent.shade700,
                          foregroundColor: Colors.white,
                          icon: Icons.delete_forever,
                          label: 'Delete',
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoyaltyBarCodeScreen(
                              qrNumber: loyalty.loyaltyNumber,
                              loyaltyName: loyalty.loyaltyName,
                            ),
                          ),
                        );
                      },
                      onLongPress: () =>
                          _copyToClipboard(loyalty.loyaltyNumber),
                      child: LoyaltyCard(loyalty: loyalty),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ---
// Loyalty Card Widget
// ---

class LoyaltyCard extends StatelessWidget {
  final Loyalty loyalty;

  const LoyaltyCard({super.key, required this.loyalty});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode
              ? [Colors.indigo.shade900, Colors.black]
              : [Colors.indigo.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  loyalty.loyaltyName,
                  style: themeProvider.getTextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoyaltyBarCodeScreen(
                        qrNumber: loyalty.loyaltyNumber,
                        loyaltyName: loyalty.loyaltyName,
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.barcode_reader,
                  size: 35,
                  color: themeProvider.secondaryColor,
                ),
              ),
            ],
          ),
          Divider(color: themeProvider.borderColor, thickness: 0.8, height: 1),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              loyalty.loyaltyNumber,
              style: themeProvider.getTextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "Tap to view barcode, Long press to copy number",
            style: themeProvider.getTextStyle(
              fontSize: 12,
              color: themeProvider.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---
// Loyalty Barcode Screen (Colors updated for consistency)
// ---

class LoyaltyBarCodeScreen extends StatelessWidget {
  final String qrNumber;
  final String loyaltyName;

  const LoyaltyBarCodeScreen({
    super.key,
    required this.qrNumber,
    required this.loyaltyName,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          "$loyaltyName Barcode",
          style: themeProvider.getTextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: themeProvider.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.primaryColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Scan to use $loyaltyName",
              style: themeProvider.getTextStyle(
                fontSize: 16,
                color: themeProvider.secondaryColor,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: PageView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildBarcodeWidget(Barcode.code128(), qrNumber, "Code 128"),
                  _buildBarcodeWidget(Barcode.code39(), qrNumber, "Code 39"),
                  _buildBarcodeWidget(Barcode.qrCode(), qrNumber, "QR Code"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Swipe for different formats",
              style: themeProvider.getTextStyle(
                fontSize: 12,
                color: themeProvider.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeWidget(Barcode barcode, String data, String title) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BarcodeWidget(
              barcode: barcode,
              data: data,
              width: 200,
              height: 150,
              color: themeProvider.primaryColor,
              errorBuilder: (context, error) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: themeProvider.getTextStyle(
                fontSize: 14,
                color: themeProvider.secondaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
