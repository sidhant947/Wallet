import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/pages/settings_page.dart';
import 'package:wallet/screens/homescreen.dart';
import 'package:wallet/screens/loyaltyscreen.dart';
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

  /// Loads identities from the SQLite database.
  Future<void> _loadIdentities() async {
    try {
      final loadedIdentities = await IdentityDatabaseHelper.instance
          .getAllIdentities();
      setState(() {
        _identities = loadedIdentities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading identities: $e');
      setState(() {
        _isLoading = false;
        _identities = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load identity cards.')),
        );
      }
    }
  }

  /// Removes an identity from the database and reloads the list.
  void _removeData(BuildContext context, int id) async {
    try {
      await IdentityDatabaseHelper.instance.deleteIdentity(id);
      await _loadIdentities();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Identity card deleted!')));
      }
    } catch (e) {
      print('Error deleting identity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete identity card.')),
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
              const SnackBar(content: Text('Identity number copied!')),
            );
          }
        })
        .catchError((e) {
          print('Error copying to clipboard: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to copy identity number.')),
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
          "Identity Cards",
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
            MaterialPageRoute(
              builder: (context) => const IdentityDataEntryScreen(),
            ),
          );
          if (result == true) {
            _loadIdentities();
          }
        },
        backgroundColor: themeProvider.accentColor,
        child: Icon(Icons.add, color: themeProvider.backgroundColor),
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
          : _identities!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    "assets/loading.json",
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No identity cards yet!",
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
              itemCount: _identities!.length,
              itemBuilder: (context, index) {
                final identity = _identities![index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Slidable(
                    key: ValueKey(identity.id),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (BuildContext context) =>
                              _removeData(context, identity.id!),
                          backgroundColor: Colors.redAccent.shade700,
                          foregroundColor: Colors.white,
                          icon: Icons.delete_forever,
                          label: 'Delete',
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(identity.identityNumber),
                      child: IdentityCard(identity: identity),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ---
// Identity Card Widget
// ---

class IdentityCard extends StatelessWidget {
  final Identity identity;

  const IdentityCard({super.key, required this.identity});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode
              ? [Colors.grey.shade900, Colors.black]
              : [Colors.grey.shade100, Colors.white],
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                identity.identityName,
                style: themeProvider.getTextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IdentityBarCodeScreen(
                        qrNumber: identity.identityNumber,
                        identityName: identity.identityName,
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 35,
                  color: themeProvider.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(color: themeProvider.borderColor, thickness: 0.8, height: 1),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: themeProvider.isDarkMode
                  ? Colors.white
                  : Colors.grey.shade200,
              child: Lottie.asset(
                "assets/card.json",
                width: 70,
                height: 70,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            identity.identityNumber,
            style: themeProvider.getTextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tap to copy number",
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
// Identity Barcode Screen (Colors updated for consistency)
// ---

class IdentityBarCodeScreen extends StatelessWidget {
  final String qrNumber;
  final String identityName;

  const IdentityBarCodeScreen({
    super.key,
    required this.qrNumber,
    required this.identityName,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          "$identityName Barcode",
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
              "Scan to view $identityName",
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
                  _buildBarcodeWidget(Barcode.qrCode(), qrNumber, "QR Code"),
                  _buildBarcodeWidget(Barcode.code128(), qrNumber, "Code 128"),
                  _buildBarcodeWidget(Barcode.code39(), qrNumber, "Code 39"),
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
