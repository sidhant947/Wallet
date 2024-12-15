import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/screens/identityscreen.dart';
import 'package:wallet/screens/loyaltyscreen.dart';
import 'package:wallet/pages/paybill.dart';
import '../models/db_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = PageController(viewportFraction: 0.8, keepPage: true);

  bool mask = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Fetch Wallets from the database
  Future<List<Wallet>> _fetchData() async {
    return await DatabaseHelper.instance.getWallets();
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  void _removeData(BuildContext context, int id) async {
    await DatabaseHelper.instance.deleteWallet(id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card Deleted'),
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
            GestureDetector(
              onTap: () {
                _launchUrl(Uri.parse("https://github.com/sponsors/sidhant947"));
              },
              child: const ListTile(
                leading: Icon(Icons.payments),
                title: Text('Donate on Github to Support Project'),
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
          backgroundColor: Colors.white,
          child: const Icon(
            Icons.add_card,
            color: Colors.black,
          )),
      body: FutureBuilder<List<Wallet>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Lottie.asset("assets/loading.json"));
          } else {
            var wallets = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    scrollDirection: Axis.vertical,
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      var wallet = wallets[index];

                      double deviceHeight =
                          MediaQuery.of(context).size.height * 0.60;

                      String formattedNumber = formatCardNumber(wallet.number);

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
                              key: ValueKey(wallet.id),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (BuildContext context) {
                                      _removeData(context, wallet.id!);
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
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      alignment: Alignment.topRight,
                                      margin: const EdgeInsets.all(10.0),
                                      child: Text(wallet.name,
                                          style: const TextStyle(
                                              fontFamily: 'Bebas',
                                              fontSize: 35)),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        copyToClipboard(wallet.number);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          mask
                                              ? "XXXX\nXXXX\nXXXX\n $masknumber"
                                              : formattedNumber,
                                          style: const TextStyle(
                                              fontFamily: 'ZSpace',
                                              fontSize: 30),
                                        ),
                                      ),
                                    ),
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
                ),
              ],
            );
          }
        },
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
        Wallet wallet = Wallet(name: name, number: number, expiry: expiry);
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
          'Save Your Card',
          style: TextStyle(fontFamily: 'Bebas', fontSize: 30),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(20),
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2)),
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
                        padding: EdgeInsets.all(10),
                        width: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2)),
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
