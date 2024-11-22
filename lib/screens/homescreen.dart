import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/screens/identityscreen.dart';
import '../pages/paybill.dart';
import '../models/wallet.dart';
import '../pages/data.dart';
import 'loyaltyscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Box<Wallet>? dataBox; // Use nullable Box

  bool mask = false;

  @override
  void initState() {
    super.initState();
    // Open the Hive box when the screen is initialized
    _openDataBox();
  }

  // Function to open the Hive box
  Future<void> _openDataBox() async {
    dataBox = await Hive.openBox<Wallet>('card');
    setState(() {}); // Trigger UI update once box is loaded
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

  Future<void> _launchURL(String link) async {
    final url = Uri.parse(link);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
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
      // extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Icon(
          Icons.wallet,
          size: 34,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PayBill()),
              );
            },
          ),
        ],
        backgroundColor: Colors.black,
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: <Widget>[
            GestureDetector(
              onTap: () {
                _launchURL("mailto:khatkarsidhant@gmail.com");
              },
              child: const UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.black),
                accountName: Text('For Suggestion/Queries'),
                accountEmail: Text('khatkarsidhant@gmail.com'),
              ),
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
                  child: Center(
                    child: Lottie.asset("assets/loading.json"),
                  ),
                );
              } else {
                return Expanded(
                  child: ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      var wallet = box.getAt(index);

                      String formattedNumber = formatCardNumber(wallet!.number);

                      String formattedExpiry =
                          formatExpiryNumber(wallet.expiry);

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
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            height: 200,
                            decoration: BoxDecoration(
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.white,
                                    spreadRadius: 0.25,
                                    blurRadius: 5,
                                    blurStyle: BlurStyle.outer),
                              ],
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Card Name
                                Container(
                                  alignment: Alignment.topRight,
                                  margin: const EdgeInsets.all(10.0),
                                  child: Text(wallet.name,
                                      style: const TextStyle(
                                          fontFamily: 'Bebas', fontSize: 28)),
                                ),
                                // Card Number
                                GestureDetector(
                                  onTap: () {
                                    copyToClipboard(wallet.number);
                                  },
                                  child: Text(
                                    formattedNumber,
                                    style: const TextStyle(
                                        fontFamily: 'ZSpace', fontSize: 20),
                                  ),
                                ),
                                // Expiry and CVV
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () {
                                        mask = !mask;
                                        setState(() {});
                                      },
                                      child: Text(
                                        mask ? formattedExpiry : "XX/XX",
                                        style: const TextStyle(
                                            fontFamily: 'ZenDots'),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        mask = !mask;
                                        setState(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        child: Text(
                                          mask ? wallet.cvv : "XXX",
                                          style: const TextStyle(
                                              fontFamily: 'ZenDots'),
                                        ),
                                      ),
                                    ),
                                  ],
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
