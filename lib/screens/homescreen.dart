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
              title: Text('Donate on Githib to Support Project'),
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
                                        color:
                                            Colors.deepPurple.withOpacity(0.5),
                                        blurRadius: 125,
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
                                          mask
                                              ? " XXYY \n XXYY \n XXYY \n $masknumber"
                                              : formattedNumber,
                                          style: const TextStyle(
                                              fontFamily: 'ZSpace',
                                              fontSize: 35),
                                        ),
                                      ),
                                    ),
                                    // Expiry
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
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
