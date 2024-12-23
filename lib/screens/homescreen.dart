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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch wallets when the screen is first built
    context.read<WalletMaskProvider>().fetchWallets();

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
      context.read<WalletMaskProvider>().fetchWallets(); // Refresh wallet list
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
                launchUrlCustom(
                    Uri.parse("https://github.com/sponsors/sidhant947"));
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
              // After adding a card, update the wallet list in the provider
              context
                  .read<WalletMaskProvider>()
                  .fetchWallets(); // Refresh wallet list
            }
          },
          backgroundColor: Colors.white,
          child: const Icon(
            Icons.add_card,
            color: Colors.black,
          )),
      body: Consumer<WalletMaskProvider>(
        builder: (context, provider, child) {
          if (provider.wallets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  itemCount: provider.wallets.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    var wallet = provider.wallets[index];

                    double deviceHeight =
                        MediaQuery.of(context).size.height * 0.60;

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
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(10),
                            height: deviceHeight,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  alignment: Alignment.topRight,
                                  margin: const EdgeInsets.all(10.0),
                                  child: Text(wallet.name,
                                      style: const TextStyle(
                                          fontFamily: 'Bebas', fontSize: 35)),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    copyToClipboard(wallet.number);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    alignment: Alignment.center,
                                    child: Text(
                                      isMasked
                                          ? "XXXX XXXX XXXX $masknumber"
                                          : formattedNumber,
                                      style: const TextStyle(
                                          fontFamily: 'ZSpace', fontSize: 20),
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
                                        isMasked ? "MM/YY" : formattedExpiry,
                                        style: const TextStyle(
                                            fontFamily: 'ZSpace', fontSize: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
