import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import 'package:wallet/models/wallet.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  Box<Loyalty>? dataBox;

  @override
  void initState() {
    super.initState();
    _openDataBox();
  }

  Future<void> _openDataBox() async {
    dataBox = await Hive.openBox<Loyalty>('loyalty');
    setState(() {});
  }

  void _removeData(BuildContext context, int index) {
    dataBox?.deleteAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(' Loyalty Card Deleted'),
      ),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      // ignore: avoid_print
      print('Text copied to clipboard!');
    }).catchError((e) {
      // ignore: avoid_print
      print('Error copying to clipboard: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (dataBox == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Icon(
            Icons.wallet,
            size: 30,
          ),
          centerTitle: true,
          backgroundColor: Colors.black,
        ),
        body: const Center(child: Text("Loading")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Icon(Icons.shopping_basket),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const LoyaltyDataEntryScreen()),
            );

            if (result != null) {
              setState(() {});
            }
          },
          backgroundColor: Colors.deepPurpleAccent.withOpacity(0.5),
          child: const Icon(Icons.shopping_basket_rounded)),
      body: Column(
        children: [
          ValueListenableBuilder(
            valueListenable: dataBox!.listenable(),
            builder: (context, Box<Loyalty> box, _) {
              if (box.isEmpty) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Add loyalty card , only 1 barcode supported now",
                        style: TextStyle(fontSize: 25),
                      ),
                      Lottie.asset("assets/loading.json"),
                    ],
                  ),
                );
              } else {
                return Expanded(
                  child: ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      var loyalty_cards = box.getAt(index);
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Slidable(
                          key: ValueKey(index),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (BuildContext context) {
                                  _removeData(context, index);
                                },
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withOpacity(0.2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.cyan.withOpacity(0.4),
                                    blurRadius: 250,
                                    spreadRadius: 30),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BarCodeScreen(
                                          name: loyalty_cards.loyalty_name,
                                          number: loyalty_cards.loyalty_number,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.all(10.0),
                                    child: Text(loyalty_cards!.loyalty_name,
                                        style: const TextStyle(
                                            fontFamily: 'Bebas', fontSize: 28)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class BarCodeScreen extends StatelessWidget {
  final String name;
  final String number;

  const BarCodeScreen({super.key, required this.name, required this.number});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          height: 200,
          child: SfBarcodeGenerator(
            value: number,
            showValue: true,
          ),
        ),
      ),
    );
  }
}

class LoyaltyDataEntryScreen extends StatefulWidget {
  const LoyaltyDataEntryScreen({super.key});
  @override
  State<LoyaltyDataEntryScreen> createState() => _LoyaltyDataEntryScreenState();
}

class _LoyaltyDataEntryScreenState extends State<LoyaltyDataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  void _addData() async {
    var dataBox = await Hive.openBox<Loyalty>('loyalty');
    String name = _nameController.text;
    String number = _numberController.text;
    if (name.isNotEmpty) {
      await dataBox.add(Loyalty(loyalty_name: name, loyalty_number: number));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Save Your Loyalty Card',
          style: TextStyle(fontFamily: 'Bebas', fontSize: 25),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                maxLength: 20,
                controller: _nameController,
                decoration: const InputDecoration(
                    hintText: 'Brand Name / Starbucks',
                    hintStyle: TextStyle(fontFamily: 'ZSpace'))),
            const SizedBox(height: 10),
            TextField(
              controller: _numberController,
              maxLength: 16,
              decoration: const InputDecoration(
                  hintText: 'Barcode Number / AB84350458',
                  hintStyle: TextStyle(fontFamily: 'ZSpace')),
            ),
            GestureDetector(
                onTap: _addData,
                child: Container(
                    padding: const EdgeInsets.all(5),
                    width: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                      ),
                    ),
                    child: const Text(
                      "Save Loyalty Card",
                      style: TextStyle(fontSize: 25),
                    ))),
          ],
        ),
      ),
    );
  }
}
