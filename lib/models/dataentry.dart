import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'db_helper.dart';

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  String _network = "rupay";

  final _formKey = GlobalKey<FormState>();

  String formatCardNumber(String input) {
    StringBuffer result = StringBuffer();
    int count = 0;

    for (int i = 0; i < input.length; i++) {
      result.write(input[i]);
      count++;

      if (count == 4 && i != input.length - 1) {
        result.write('  ');
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

  void _addData() async {
    String name = _nameController.text;
    String number = _numberController.text;
    String expiry = _expiryController.text;

    // Ensure that card number and expiry are valid
    if (number.length > 14 && expiry.length == 4) {
      if (name.isNotEmpty) {
        Wallet wallet = Wallet(
            name: name, number: number, expiry: expiry, network: _network);
        await DatabaseHelper.instance.insertWallet(
            wallet); // Assuming you have a database helper to insert the wallet

        Navigator.pop(context, true);
      }
    } else {
      // Show a message if the card number or expiry is not valid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Card number must be 16 digits and expiry must be 4 digits'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Save New Card',
          style: TextStyle(fontFamily: 'Bebas', fontSize: 30),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: ListView(
        children: [
          _nameController.text.isEmpty &&
                  _expiryController.text.isEmpty &&
                  _numberController.text.isEmpty
              ? Container(
                  margin: EdgeInsets.all(20),
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.deepPurple, width: 2)),
                  child: Lottie.asset("assets/card.json"))
              : Container(
                  margin: EdgeInsets.all(20),
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.deepPurple, width: 2)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          padding: EdgeInsets.all(10),
                          alignment: Alignment.topRight,
                          child: Text(
                            _nameController.text,
                            style: TextStyle(fontSize: 18),
                          )),
                      Container(
                          padding: EdgeInsets.all(10),
                          alignment: Alignment.center,
                          child: Text(
                            formatCardNumber(_numberController.text),
                            style: TextStyle(fontSize: 25),
                          )),
                      Container(
                          padding: EdgeInsets.only(left: 20),
                          alignment: Alignment.topLeft,
                          child: Text(
                            formatExpiryNumber(_expiryController.text),
                            style: TextStyle(fontSize: 15),
                          )),
                    ],
                  ),
                ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    focusColor: Colors.black,
                    dropdownColor: Colors.black,
                    // padding: EdgeInsets.all(10),
                    value: "rupay",
                    decoration: const InputDecoration(
                        fillColor: Colors.black, border: null),
                    items: ['rupay', 'visa', 'mastercard', 'amex']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Center(
                          child: Image.asset(
                            "assets/network/$value.png",
                            height: 30,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _network = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a card type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  // Card Name Input
                  TextFormField(
                    controller: _nameController,
                    maxLength: 20,
                    decoration: const InputDecoration(labelText: 'Card Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    onChanged: (context) {
                      setState(() {});
                    },
                  ),

                  // Card Number Input (16 digits validation)
                  TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(labelText: 'Card Number'),
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Only digits allowed
                      LengthLimitingTextInputFormatter(
                          16), // Limit to 16 digits
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a card number';
                      }
                      if (value.length < 15) {
                        return 'Card number must be 16 digits';
                      }
                      return null;
                    },
                    onChanged: (context) {
                      setState(() {});
                    },
                  ),

                  // Expiry Date Input (4 digits validation)
                  TextFormField(
                    controller: _expiryController,
                    maxLength: 4,
                    decoration:
                        const InputDecoration(labelText: 'Expiry Date (MMYY)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Only digits allowed
                      LengthLimitingTextInputFormatter(4), // Limit to 4 digits
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an expiry date';
                      }
                      if (value.length != 4) {
                        return 'Expiry date must be 4 digits (MMYY)';
                      }
                      return null;
                    },
                    onChanged: (context) {
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 20),
                  // Save Button
                  GestureDetector(
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        _addData();
                      }
                    },
                    child: Container(
                        padding: const EdgeInsets.all(15),
                        width: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Save Card',
                          style: TextStyle(fontSize: 25),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Identity

class IdentityDataEntryScreen extends StatefulWidget {
  const IdentityDataEntryScreen({super.key});

  @override
  State<IdentityDataEntryScreen> createState() =>
      _IdentityDataEntryScreenState();
}

class _IdentityDataEntryScreenState extends State<IdentityDataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  void _addData() async {
    String name = _nameController.text.trim();
    String number = _numberController.text.trim();

    // Validate input
    if (name.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out both fields.'),
        ),
      );
      return;
    }

    try {
      // Create new Identity object
      Identity newIdentity =
          Identity(identityName: name, identityNumber: number);

      // Insert the new identity into the database
      await IdentityDatabaseHelper.instance.insertIdentity(newIdentity);

      // Pop the screen to go back
      Navigator.pop(context, true);
    } catch (e) {
      // Handle any errors during insertion
      print("Error inserting identity: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving identity card.'),
        ),
      );
    }
  }

  static final _possibleFormats = BarcodeFormat.values.toList()
    ..removeWhere((e) => e == BarcodeFormat.unknown);

  List<BarcodeFormat> selectedFormats = [..._possibleFormats];

  Future<void> _scan() async {
    final result = await BarcodeScanner.scan(
      options: ScanOptions(restrictFormat: selectedFormats),
    );
    setState(() => _numberController.text = result.rawContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Save Your Identity Card',
          style: TextStyle(fontFamily: 'Bebas', fontSize: 25),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Identity',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    hintText: '12345678 / XXXXX78923X',
                    hintStyle: TextStyle(fontFamily: 'ZSpace'),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _scan,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    width: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                    ),
                    child: const Text(
                      "Scan Barcode",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _addData,
              child: Container(
                padding: const EdgeInsets.all(15),
                width: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  "Save Loyalty Card",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Loyalty

// ignore: must_be_immutable
class LoyaltyDataEntryScreen extends StatefulWidget {
  LoyaltyDataEntryScreen({super.key});

  @override
  State<LoyaltyDataEntryScreen> createState() => _LoyaltyDataEntryScreenState();
}

class _LoyaltyDataEntryScreenState extends State<LoyaltyDataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  void _addData() async {
    String name = _nameController.text.trim();
    String number = _numberController.text.trim();

    // Validate input
    if (name.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out both fields.'),
        ),
      );
      return;
    }

    try {
      // Create new Loyalty object
      Loyalty newLoyalty = Loyalty(loyaltyName: name, loyaltyNumber: number);

      // Insert the new Loyalty into the database
      await LoyaltyDatabaseHelper.instance.insertLoyalty(newLoyalty);

      // Pop the screen to go back
      Navigator.pop(context, true);
    } catch (e) {
      // Handle any errors during insertion
      print("Error inserting Loyalty: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving Loyalty card.'),
        ),
      );
    }
  }

  static final _possibleFormats = BarcodeFormat.values.toList()
    ..removeWhere((e) => e == BarcodeFormat.unknown);

  List<BarcodeFormat> selectedFormats = [..._possibleFormats];

  Future<void> _scan() async {
    final result = await BarcodeScanner.scan(
      options: ScanOptions(restrictFormat: selectedFormats),
    );
    setState(() => _numberController.text = result.rawContent);
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Starbucks',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    hintText: '87989237498',
                    hintStyle: TextStyle(fontFamily: 'ZSpace'),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _scan,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    width: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                    ),
                    child: const Text(
                      "Scan Barcode",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _addData,
              child: Container(
                padding: const EdgeInsets.all(15),
                width: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  "Save Loyalty Card",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
