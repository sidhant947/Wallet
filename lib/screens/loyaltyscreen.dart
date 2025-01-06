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
  final PageController _controller = PageController(viewportFraction: 0.8);
  List<Loyalty>? loyalties;

  @override
  void initState() {
    super.initState();
    _loadLoyalties();
  }

  // Load loyalties from SQLite database
  Future<void> _loadLoyalties() async {
    loyalties = (await LoyaltyDatabaseHelper.instance.getAllLoyalties())
        .cast<Loyalty>();
    setState(() {});
  }

  void _removeData(BuildContext context, int id) async {
    await LoyaltyDatabaseHelper.instance.deleteLoyalty(id);
    _loadLoyalties(); // Reload the list after deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loyalty Card Deleted'),
      ),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      print('Text copied to clipboard!');
    }).catchError((e) {
      print('Error copying to clipboard: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        title: const Text(
          "Loyalty Cards",
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const LoyaltyDataEntryScreen()),
          );
          if (result != null) {
            _loadLoyalties(); // Reload list after new Loyalty is added
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          loyalties == null
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: loyalties!.isEmpty
                      ? Center(
                          child: Lottie.asset("assets/loading.json"),
                        )
                      : PageView.builder(
                          controller: _controller,
                          scrollDirection: Axis.vertical,
                          itemCount: loyalties!.length,
                          itemBuilder: (context, index) {
                            var Loyalty = loyalties![index];
                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Slidable(
                                key: ValueKey(index),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (BuildContext context) {
                                        _removeData(context, Loyalty.id!);
                                      },
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white)),
                                  padding: const EdgeInsets.all(10),
                                  child: ListView(
                                    children: [
                                      Container(
                                        alignment: Alignment.center,
                                        margin: const EdgeInsets.all(10.0),
                                        child: Text(Loyalty.loyaltyName,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Bebas',
                                                fontSize: 28)),
                                      ),
                                      BarcodeWidget(
                                        barcode: Barcode.code128(),
                                        data: Loyalty.loyaltyNumber, // Content
                                        width: 200,
                                        height: 200,
                                        color: Colors.white,
                                      ),
                                      BarcodeWidget(
                                        barcode: Barcode.code39(),
                                        data: Loyalty.loyaltyNumber, // Content
                                        width: 200,
                                        height: 200,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}
