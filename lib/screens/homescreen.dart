import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/screens/identityscreen.dart';
import 'package:wallet/screens/loyaltyscreen.dart';
import 'package:wallet/pages/paybill.dart';
import '../models/dataentry.dart';
import '../models/db_helper.dart';
import '../models/provider_helper.dart';
import '../pages/walletdetails.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch wallets when the screen is first built
    context.read<WalletProvider>().fetchWallets();

    Future<void> launchUrlCustom(Uri url) async {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch $url');
      }
    }

    void removeData(BuildContext context, int id) async {
      await DatabaseHelper.instance.deleteWallet(id);
      context.read<WalletProvider>().fetchWallets(); // Refresh wallet list
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
          result.write(' ');
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Icon(
          Icons.wallet,
          size: 34,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          GestureDetector(
            onTap: () {
              launchUrlCustom(Uri.parse("https://buymeacoffee.com/sidhant947"));
            },
            child: Container(
                padding: EdgeInsets.all(10),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset("assets/bmcLogo.png"))),
          ),
        ],
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
                  launchUrlCustom(
                      Uri.parse("https://buymeacoffee.com/sidhant947"));
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    "assets/btn.png",
                    height: 50,
                  ),
                )),
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
              // After adding a card, update the wallet list in the provider
              context
                  .read<WalletProvider>()
                  .fetchWallets(); // Refresh wallet list
            }
          },
          backgroundColor: Colors.white,
          child: const Icon(
            Icons.add_card,
            color: Colors.black,
          )),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.wallets.isEmpty) {
            return Center(child: Lottie.asset("assets/loading.json"));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: provider.wallets.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    var wallet = provider.wallets[index];

                    String formattedNumber = formatCardNumber(wallet.number);

                    String masknumber =
                        wallet.number.substring(wallet.number.length - 4);

                    String formattedExpiry = formatExpiryNumber(wallet.expiry);

                    bool isMasked = provider.isMasked(wallet.id!);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Slidable(
                          key: ValueKey(wallet.id),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (BuildContext context) {
                                  removeData(context, wallet.id!);
                                },
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          startActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (BuildContext context) {
                                  provider.toggleMask(
                                      wallet.id!); // Toggle the mask
                                },
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                icon: isMasked
                                    ? Icons.visibility
                                    : Icons.visibility_off_rounded,
                                label: isMasked ? "Show" : "Hide",
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to WalletDetailScreen and pass the selected wallet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WalletDetailScreen(wallet: wallet),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(10),
                              height: MediaQuery.of(context).size.height * 0.30,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border:
                                    Border.all(color: Colors.white, width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    alignment: Alignment.topRight,
                                    margin: const EdgeInsets.all(10.0),
                                    child: FittedBox(
                                      child: Text(wallet.name,
                                          style: const TextStyle(
                                              fontFamily: 'Bebas',
                                              fontSize: 30)),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      copyToClipboard(wallet.number);
                                    },
                                    child: FittedBox(
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        alignment: Alignment.center,
                                        child: Text(
                                          isMasked
                                              ? "XXXX XXXX XXXX $masknumber"
                                              : formattedNumber,
                                          style: const TextStyle(
                                              fontFamily: 'ZSpace',
                                              fontSize: 22),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          isMasked ? "MM/YY" : formattedExpiry,
                                          style: const TextStyle(
                                              fontFamily: 'ZSpace',
                                              fontSize: 20),
                                        ),
                                      ),
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
        },
      ),
    );
  }
}
