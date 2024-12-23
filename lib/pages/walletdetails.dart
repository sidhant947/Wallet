import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/db_helper.dart';
import '../models/provider_helper.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
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

  String formatCashback(String spends, String rewards) {
    if (spends.isEmpty || rewards.isEmpty) {
      return '0';
    }
    int spendsInt = int.parse(spends);
    int rewardsInt = int.parse(rewards);
    int result = (spendsInt * rewardsInt) ~/ 100;

    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Card Summary"),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to the edit screen with the current wallet details
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletEditScreen(wallet: widget.wallet),
                ),
              ).then((updatedWallet) {
                if (updatedWallet != null) {
                  // Refresh the wallet list with the updated wallet
                  context.read<WalletProvider>().fetchWallets();
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          var wallet =
              provider.wallets.firstWhere((w) => w.id == widget.wallet.id);

          return ListView(
            // crossAxisAlignment: CrossAxisAlignment.start,
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
                          wallet.name,
                          style: TextStyle(fontSize: 18),
                        )),
                    Container(
                        padding: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        child: Text(
                          formatCardNumber(wallet.number),
                          style: TextStyle(fontSize: 25),
                        )),
                    Container(
                        padding: EdgeInsets.only(left: 20),
                        alignment: Alignment.topLeft,
                        child: Text(
                          formatExpiryNumber(wallet.expiry),
                          style: TextStyle(fontSize: 15),
                        )),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Max Limit",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            wallet.maxlimit ?? 'No Data',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Annual Spends",
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                wallet.spends ?? 'No Spends',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Cashback Value",
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                formatCashback(wallet.spends ?? '0',
                                        wallet.rewards ?? '0') ??
                                    'No Cashback',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Type: ",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            wallet.cardtype ?? 'Paid/LTF',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Bill Generation Date: ",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            wallet.billdate ?? 'No Date',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Annual fee Waiver: ",
                            style: TextStyle(fontSize: 18),
                          ),
                          Column(
                            children: [
                              Text(
                                wallet.annualFeeWaiver ?? 'No Spends',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            "Card Spend Category: ",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            wallet.category ?? 'No Categories Added Yet',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class WalletEditScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletEditScreen({super.key, required this.wallet});

  @override
  _WalletEditScreenState createState() => _WalletEditScreenState();
}

class _WalletEditScreenState extends State<WalletEditScreen> {
  // Controller for each field to update the values
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _expiryController;
  late TextEditingController _maxlimitController;
  late TextEditingController _spendsController;
  late TextEditingController _cardtypeController;
  late TextEditingController _billdateController;
  late TextEditingController _categoryController;
  late TextEditingController _annualFeeWaiverController;
  late TextEditingController _rewardsController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize the controllers with the current wallet details
    _nameController = TextEditingController(text: widget.wallet.name);
    _numberController = TextEditingController(text: widget.wallet.number);
    _expiryController = TextEditingController(text: widget.wallet.expiry);
    _maxlimitController = TextEditingController(text: widget.wallet.maxlimit);
    _spendsController = TextEditingController(text: widget.wallet.spends);
    _cardtypeController = TextEditingController(text: widget.wallet.cardtype);
    _billdateController = TextEditingController(text: widget.wallet.billdate);
    _categoryController = TextEditingController(text: widget.wallet.category);
    _annualFeeWaiverController =
        TextEditingController(text: widget.wallet.annualFeeWaiver);
    _rewardsController = TextEditingController(text: widget.wallet.rewards);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _maxlimitController.dispose();
    _spendsController.dispose();
    _cardtypeController.dispose();
    _billdateController.dispose();
    _categoryController.dispose();
    _annualFeeWaiverController.dispose();
    _rewardsController.dispose();

    super.dispose();
  }

  // Function to save the updated wallet details
  void _saveUpdatedDetails() async {
    final updatedWallet = Wallet(
      id: widget.wallet.id,
      name: _nameController.text,
      number: _numberController.text,
      expiry: _expiryController.text,
      maxlimit: _maxlimitController.text,
      spends: _spendsController.text,
      cardtype: _cardtypeController.text,
      billdate: _billdateController.text,
      category: _categoryController.text,
      annualFeeWaiver: _annualFeeWaiverController.text,
      rewards: _rewardsController.text,
    );

    // Save the updated wallet details to the database
    await DatabaseHelper.instance.updateWallet(updatedWallet);

    // Go back to the previous screen with the updated wallet
    Navigator.pop(context, updatedWallet);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text("Edit Card Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveUpdatedDetails, // Save the updated details
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          var wallet =
              provider.wallets.firstWhere((w) => w.id == widget.wallet.id);

          // Update the controllers with the current wallet details
          _nameController.text = wallet.name;
          _numberController.text = wallet.number;
          _expiryController.text = wallet.expiry;
          _maxlimitController.text = wallet.maxlimit ?? '';
          _spendsController.text = wallet.spends ?? '';
          _cardtypeController.text = wallet.cardtype ?? '';
          _billdateController.text = wallet.billdate ?? '';
          _categoryController.text = wallet.category ?? '';
          _annualFeeWaiverController.text = wallet.annualFeeWaiver ?? '';
          _rewardsController.text = wallet.rewards ?? '';

          return ListView(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    // Card Name Input
                    Container(
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            maxLength: 20,
                            decoration:
                                const InputDecoration(labelText: 'Card Name'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name';
                              }
                              return null;
                            },
                          ),

                          // Card Number Input (16 digits validation)
                          TextFormField(
                            controller: _numberController,
                            decoration:
                                const InputDecoration(labelText: 'Card Number'),
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
                          ),

                          // Expiry Date Input (4 digits validation)
                          TextFormField(
                            controller: _expiryController,
                            maxLength: 4,
                            decoration: const InputDecoration(
                                labelText: 'Expiry Date (MMYY)'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly, // Only digits allowed
                              LengthLimitingTextInputFormatter(
                                  4), // Limit to 4 digits
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
                          ),
                        ],
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _maxlimitController,
                            decoration:
                                const InputDecoration(labelText: 'Max Limit'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter limits';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // Spends Input
                          TextFormField(
                            controller: _spendsController,
                            decoration:
                                const InputDecoration(labelText: 'Spends'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter spends';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // Card Type Input
                          TextFormField(
                            controller: _cardtypeController,
                            decoration:
                                const InputDecoration(labelText: 'Card Type'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a card type';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // Bill Date Input
                          TextFormField(
                            controller: _billdateController,
                            decoration:
                                const InputDecoration(labelText: 'Bill Date'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a bill date';
                              }
                              if (value.length > 2) {
                                return 'Enter a valid date 1-31';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // Category Input
                          TextFormField(
                            controller: _categoryController,
                            decoration:
                                const InputDecoration(labelText: 'Category'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a category';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // Annual Fee Waiver Input
                          TextFormField(
                            controller: _annualFeeWaiverController,
                            decoration: const InputDecoration(
                                labelText: 'Annual Fee Waiver'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an annual fee waiver';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // Rewards Input
                          TextFormField(
                            controller: _rewardsController,
                            decoration:
                                const InputDecoration(labelText: 'Cashback %'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter rewards';
                              }
                              if (value.length > 2) {
                                return 'Enter a valid percentage 0-99';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    )
                    // Save Button
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
