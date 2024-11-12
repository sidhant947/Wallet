import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'wallet.dart';
import 'about.dart';
import 'data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Box<Wallet>? dataBox; // Use nullable Box

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
      const SnackBar(content: Text('Card Deleted')),
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
        result.write(' - ');
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
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutScreen()),
                  );
                },
                icon: const Icon(Icons.person))
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Icon(
          Icons.wallet,
          size: 34,
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
              icon: const Icon(Icons.person))
        ],
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
          child: const Icon(Icons.add)),
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
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                // Card Name
                                Container(
                                  margin: const EdgeInsets.all(10.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      copyToClipboard(wallet.name);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(300, 50),
                                    ),
                                    child: Text(
                                      wallet.name,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                // Card Number
                                Container(
                                  margin: const EdgeInsets.all(10.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      copyToClipboard(wallet.number);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(300, 50),
                                    ),
                                    child: Text(formattedNumber),
                                  ),
                                ),
                                // Expiry and CVV
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      margin: const EdgeInsets.all(10.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          copyToClipboard(wallet.expiry);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(100, 50),
                                        ),
                                        child: Text(formattedExpiry),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(10.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          copyToClipboard(wallet.cvv);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(100, 50),
                                        ),
                                        child: Text(wallet.cvv),
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
