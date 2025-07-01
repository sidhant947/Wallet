import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import '../models/dataentry.dart';
import '../models/db_helper.dart';

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
      final loadedLoyalties =
          await LoyaltyDatabaseHelper.instance.getAllLoyalties();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loyalty card deleted!')),
        );
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

  /// Copies text to the clipboard.
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loyalty number copied!')),
        );
      }
    }).catchError((e) {
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
    return Scaffold(
      backgroundColor: Colors.black, // Set Scaffold background to black
      appBar: AppBar(
        title: const Text(
          "Loyalty Cards",
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
            MaterialPageRoute(builder: (context) => LoyaltyDataEntryScreen()),
          );
          if (result == true) {
            _loadLoyalties();
          }
        },
        backgroundColor: Colors.blueAccent.shade400, // Consistent FAB color
        child: const Icon(Icons.add_card, color: Colors.white),
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
                      const Text(
                        "No loyalty cards yet!",
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
                              backgroundColor: Colors.redAccent
                                  .shade700, // Consistent delete color
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
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          // Deep Indigo to Black gradient
          colors: [
            Colors.indigo.shade900, // Deep Indigo
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  loyalty.loyaltyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Bebas',
                    fontSize: 32,
                    letterSpacing: 1.5,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                child: const Icon(
                  Icons.barcode_reader,
                  size: 35,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Divider(
            color: Colors.white38, // Softer divider color
            thickness: 0.8,
            height: 1,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              loyalty.loyaltyNumber,
              style: const TextStyle(
                color: Colors.white,
                letterSpacing: 2,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Text(
            "Tap to view barcode, Long press to copy number",
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
    return Scaffold(
      backgroundColor: Colors.black, // Consistent background
      appBar: AppBar(
        title: Text(
          "$loyaltyName Barcode",
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
              "Scan to use $loyaltyName",
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
                    Barcode.code128(),
                    qrNumber,
                    "Code 128",
                  ),
                  _buildBarcodeWidget(
                    Barcode.code39(),
                    qrNumber,
                    "Code 39",
                  ),
                  _buildBarcodeWidget(
                    Barcode.qrCode(),
                    qrNumber,
                    "QR Code",
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
