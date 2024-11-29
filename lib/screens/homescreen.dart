import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:wallet/screens/identityscreen.dart';
import 'package:wallet/screens/loyaltyscreen.dart';
import '../pages/paybill.dart';
import '../models/wallet.dart';
import 'dart:convert';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = PageController(viewportFraction: 0.8, keepPage: true);
  Box<Wallet>? dataBox; // Use nullable Box

  bool mask = true;

  @override
  void initState() {
    super.initState();
    // Open the Hive box when the screen is initialized
    _openDataBox();
  }

  // Function to open the Hive box
  Future<void> _openDataBox() async {
    dataBox = await Hive.openBox<Wallet>('walletBox');
    setState(() {});
  }

  Future<void> convertHiveBoxToJson() async {
    var box = Hive.box<Wallet>('walletBox');

    Map<String, dynamic> boxData = {};

    for (var key in box.keys) {
      var wallet = box.get(key);
      boxData[key] = {
        "name": wallet!.name,
        "number": wallet.number,
        "expiry": wallet.expiry
      };
    }

    String jsonString = jsonEncode(boxData);

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String filePath = '${appDocDir.path}/wallet_data.json';

    File jsonFile = File(filePath);
    await jsonFile.writeAsString(jsonString);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Hive data has been saved as a JSON file at: App Directory'),
      ),
    );
  }

  void _removeData(BuildContext context, int index) {
    dataBox?.deleteAt(index); // Null-safe access
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card Deleted'),
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

  String formatCardNumber(String input) {
    StringBuffer result = StringBuffer();
    int count = 0;

    for (int i = 0; i < input.length; i++) {
      result.write(input[i]);
      count++;

      if (count == 4 && i != input.length - 1) {
        result.write('\n');
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

  @override
  Widget build(BuildContext context) {
    if (dataBox == null) {
      // Return a loading indicator while the box is being opened
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Icon(
          Icons.wallet,
          size: 34,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: <Widget>[
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              accountName: Text('For Suggestion/Queries'),
              accountEmail: Text('khatkarsidhant@gmail.com'),
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Identity Cards'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const IdentityScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_basket),
              title: const Text('Loyalty Cards'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoyaltyScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Pay Bills by UPI'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PayBill()),
                );
              },
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.payments),
              title: Text('Donate on Github to Support Project'),
            ),
            GestureDetector(
              onTap: convertHiveBoxToJson,
              child: const ListTile(
                title: Text("Backup"),
              ),
            ),
            const Divider(),
            Lottie.asset("assets/card.json"),
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
              setState(() {});
            }
          },
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add_card)),
      body: Column(
        children: [
          ValueListenableBuilder(
            valueListenable: dataBox!.listenable(),
            builder: (context, Box<Wallet> box, _) {
              if (box.isEmpty) {
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset("assets/loading.json"),
                      ListTile(
                        onTap: () {},
                        leading: Lottie.asset("assets/card.json"),
                        title: const Text("Restore Your data"),
                        subtitle:
                            const Text("Get your all previous cards back"),
                      )
                    ],
                  ),
                );
              } else {
                return Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    scrollDirection: Axis.vertical,
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      var wallet = box.getAt(index);

                      double deviceHeight =
                          MediaQuery.of(context).size.height * 0.60;

                      String formattedNumber = formatCardNumber(wallet!.number);

                      String masknumber =
                          wallet.number.substring(wallet.number.length - 4);

                      String formattedExpiry =
                          formatExpiryNumber(wallet.expiry);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(25),
                            child: Slidable(
                              key: ValueKey(index),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (BuildContext context) {
                                      _removeData(context, index);
                                    },
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: 'Delete',
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                height: deviceHeight,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Card Name
                                    Container(
                                      alignment: Alignment.topRight,
                                      margin: const EdgeInsets.all(10.0),
                                      child: Text(wallet.name,
                                          style: const TextStyle(
                                              fontFamily: 'Bebas',
                                              fontSize: 35)),
                                    ),
                                    // Card Number
                                    GestureDetector(
                                      onTap: () {
                                        copyToClipboard(wallet.number);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          mask ? masknumber : formattedNumber,
                                          style: const TextStyle(
                                              fontFamily: 'ZSpace',
                                              fontSize: 30),
                                        ),
                                      ),
                                    ),
                                    // Expiry
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            mask ? "MM/YY" : formattedExpiry,
                                            style: const TextStyle(
                                                fontFamily: 'ZSpace',
                                                fontSize: 20),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              mask = !mask;
                                            });
                                          },
                                          child: Container(
                                              padding: const EdgeInsets.all(20),
                                              child: mask
                                                  ? const Icon(
                                                      Icons.visibility,
                                                      size: 20,
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .visibility_off_rounded,
                                                      size: 20,
                                                    )),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void _addData() async {
    String name = _nameController.text;
    String number = _numberController.text;
    String expiry = _expiryController.text;

    var box = Hive.box<Wallet>('walletBox');

    if (name.isNotEmpty) {
      await box.put(
          "$name$expiry", Wallet(name: name, number: number, expiry: expiry));

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Save Your Card',
          style: TextStyle(fontFamily: 'Bebas', fontSize: 30),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextField(
                  maxLength: 20,
                  controller: _nameController,
                  decoration: const InputDecoration(
                      // labelText: 'Card Name',
                      hintText: 'Infinia',
                      hintStyle: TextStyle(fontFamily: 'ZSpace'))),
              const SizedBox(height: 10),
              TextFormField(
                controller: _numberController,
                maxLength: 16,
                decoration: const InputDecoration(
                    hintText: '1234567891234567',
                    hintStyle: TextStyle(fontFamily: 'ZSpace')),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.length < 15) {
                    return 'Please enter at least 15 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                maxLength: 4,
                controller: _expiryController,
                decoration: const InputDecoration(
                    hintText: "MMYY",
                    hintStyle: TextStyle(fontFamily: 'ZSpace')),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return 'Please enter at least 4 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                  onTap: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _addData();
                    }
                  },
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
                        "Save Card",
                        style: TextStyle(fontSize: 30),
                      ))),
            ],
          ),
        ),
      ),
    );
  }
}
