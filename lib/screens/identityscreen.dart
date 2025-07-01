import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:wallet/models/db_helper.dart';
import '../models/dataentry.dart'; // Assuming this imports IdentityDataEntryScreen

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
      final loadedIdentities =
          await IdentityDatabaseHelper.instance.getAllIdentities();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identity card deleted!')),
        );
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

  /// Copies text to the clipboard.
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identity number copied!')),
        );
      }
    }).catchError((e) {
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
    return Scaffold(
      backgroundColor: Colors.black, // Set Scaffold background to black
      appBar: AppBar(
        title: const Text(
          "Identity Cards",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
        backgroundColor: Colors.blueAccent.shade400, // Vibrant blue for FAB
        child: const Icon(Icons.add, color: Colors.white),
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
                      const Text(
                        "No identity cards yet!",
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      const Text(
                        "Tap '+' to add a new one.",
                        style: TextStyle(fontSize: 14, color: Colors.white54),
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
                              backgroundColor: Colors.redAccent
                                  .shade700, // Stronger red for delete
                              foregroundColor: Colors.white,
                              icon: Icons.delete_forever,
                              label: 'Delete',
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              _copyToClipboard(identity.identityNumber),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          // Dark Grey to Black gradient
          colors: [
            Colors.grey.shade900, // Dark Grey
            Colors.black, // Black
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Bebas',
                  fontSize: 32,
                  letterSpacing: 1.5,
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
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 35,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(
            color: Colors.white38, // Softer divider color
            thickness: 0.8,
            height: 1,
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white, // Retain white for Lottie contrast
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
            style: const TextStyle(
              color: Colors.white,
              letterSpacing: 2,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Tap to copy number",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
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
    return Scaffold(
      backgroundColor: Colors.black, // Consistent background
      appBar: AppBar(
        title: Text(
          "$identityName Barcode",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Scan to view $identityName",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: PageView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildBarcodeWidget(
                    Barcode.qrCode(),
                    qrNumber,
                    "QR Code",
                  ),
                  _buildBarcodeWidget(
                    Barcode.code128(),
                    qrNumber,
                    "Code 128",
                  ),
                  _buildBarcodeWidget(
                    Barcode.code39(),
                    qrNumber,
                    "Code 39",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Swipe for different formats",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeWidget(Barcode barcode, String data, String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BarcodeWidget(
          barcode: barcode,
          data: data,
          width: 200,
          height: 150,
          color: Colors.white, // Barcode color is white on black background
          errorBuilder: (context, error) => Center(
              child: Text('Error: $error',
                  style: const TextStyle(color: Colors.red))),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
