import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/db_helper.dart';
import '../models/provider_helper.dart';
import '../models/theme_provider.dart';

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
    double spendsInt = double.parse(spends);
    double rewardsInt = double.parse(rewards);
    double result = double.parse(
      ((spendsInt * rewardsInt) / 100).toStringAsFixed(2),
    );

    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Card Summary",
          style: themeProvider.getTextStyle(fontSize: 20),
        ),
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
          var wallet = provider.wallets.firstWhere(
            (w) => w.id == widget.wallet.id,
          );

          return ListView(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.all(20),
                height: 200,
                width: double.infinity,
                decoration: wallet.network == "rupay"
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blueGrey, Colors.black],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          tileMode:
                              TileMode.repeated, // This repeats the gradient
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.white24, blurRadius: 8),
                        ],
                      )
                    : wallet.network == "visa"
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo, Colors.cyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          tileMode:
                              TileMode.repeated, // This repeats the gradient
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.blue[700]!, blurRadius: 8),
                        ],
                      )
                    : wallet.network == "mastercard"
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.deepOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          tileMode:
                              TileMode.repeated, // This repeats the gradient
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.orange[200]!, blurRadius: 8),
                        ],
                      )
                    : BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black87, Colors.black],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          tileMode:
                              TileMode.repeated, // This repeats the gradient
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.white24, blurRadius: 20),
                        ],
                      ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      alignment: Alignment.topRight,
                      child: Text(
                        wallet.name,
                        style: themeProvider.getTextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      alignment: Alignment.center,
                      child: Text(
                        formatCardNumber(wallet.number),
                        style: themeProvider.getTextStyle(
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 20),
                          alignment: Alignment.topLeft,
                          child: Text(
                            formatExpiryNumber(wallet.expiry),
                            style: themeProvider.getTextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(right: 20),
                          alignment: Alignment.topLeft,
                          child: Image.asset(
                            "assets/network/${wallet.network}.png",
                            height: 25,
                          ),
                        ),
                      ],
                    ),
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
                            style: themeProvider.getTextStyle(fontSize: 18),
                          ),
                          Text(
                            wallet.maxlimit ?? 'No Data',
                            style: themeProvider.getTextStyle(fontSize: 18),
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
                                style: themeProvider.getTextStyle(fontSize: 18),
                              ),
                              Text(
                                double.parse(
                                  wallet.spends ?? "0",
                                ).toStringAsFixed(2),
                                style: themeProvider.getTextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Cashback Value",
                                style: themeProvider.getTextStyle(fontSize: 18),
                              ),
                              Text(
                                formatCashback(
                                  wallet.spends ?? '0',
                                  wallet.rewards ?? '0',
                                ),
                                style: themeProvider.getTextStyle(fontSize: 18),
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
                            style: themeProvider.getTextStyle(fontSize: 18),
                          ),
                          Text(
                            wallet.cardtype ?? 'Paid/LTF',
                            style: themeProvider.getTextStyle(fontSize: 18),
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
                            style: themeProvider.getTextStyle(fontSize: 18),
                          ),
                          Text(
                            wallet.billdate ?? 'No Date',
                            style: themeProvider.getTextStyle(fontSize: 18),
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
                            style: themeProvider.getTextStyle(fontSize: 18),
                          ),
                          Column(
                            children: [
                              Text(
                                wallet.annualFeeWaiver != null &&
                                        wallet.spends != null
                                    ? (double.parse(
                                                wallet.annualFeeWaiver ?? "0",
                                              ) <
                                              double.parse(wallet.spends ?? "0")
                                          ? "waived off"
                                          : wallet.annualFeeWaiver!)
                                    : "N/A",
                                style: themeProvider.getTextStyle(fontSize: 18),
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
                            style: themeProvider.getTextStyle(fontSize: 18),
                          ),
                          Text(
                            wallet.category ?? 'No Categories Added Yet',
                            style: themeProvider.getTextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    // Custom Fields Section
                    if (wallet.customFields != null &&
                        wallet.customFields!.isNotEmpty) ...[
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Custom Fields:",
                              style: themeProvider.getTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            ...wallet.customFields!.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${entry.key}:",
                                        style: themeProvider.getTextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        entry.value,
                                        style: themeProvider.getTextStyle(
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class WalletEditScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletEditScreen({super.key, required this.wallet});

  @override
  WalletEditScreenState createState() => WalletEditScreenState();
}

class WalletEditScreenState extends State<WalletEditScreen> {
  // Controller for each field to update the values
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _expiryController;
  late String _network;
  late TextEditingController _maxlimitController;
  late TextEditingController _spendsController;
  late TextEditingController _cardtypeController;
  late TextEditingController _billdateController;
  late TextEditingController _categoryController;
  late TextEditingController _annualFeeWaiverController;
  late TextEditingController _rewardsController;

  // Custom fields management
  Map<String, String> _customFields = {};
  final List<MapEntry<String, TextEditingController>> _customFieldControllers =
      [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize the controllers with the current wallet details
    _nameController = TextEditingController(text: widget.wallet.name);
    _numberController = TextEditingController(text: widget.wallet.number);
    _expiryController = TextEditingController(text: widget.wallet.expiry);
    _network = widget.wallet.network!;
    _maxlimitController = TextEditingController(text: widget.wallet.maxlimit);
    _spendsController = TextEditingController(text: widget.wallet.spends);
    _cardtypeController = TextEditingController(text: widget.wallet.cardtype);
    _billdateController = TextEditingController(text: widget.wallet.billdate);
    _categoryController = TextEditingController(text: widget.wallet.category);
    _annualFeeWaiverController = TextEditingController(
      text: widget.wallet.annualFeeWaiver,
    );
    _rewardsController = TextEditingController(text: widget.wallet.rewards);

    // Initialize custom fields
    _customFields = Map<String, String>.from(widget.wallet.customFields ?? {});
    _initializeCustomFieldControllers();
  }

  void _initializeCustomFieldControllers() {
    _customFieldControllers.clear();
    for (var entry in _customFields.entries) {
      _customFieldControllers.add(
        MapEntry(entry.key, TextEditingController(text: entry.value)),
      );
    }
  }

  void _addCustomField() {
    setState(() {
      String newKey = 'Custom Field ${_customFields.length + 1}';
      _customFields[newKey] = '';
      _customFieldControllers.add(MapEntry(newKey, TextEditingController()));
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      String keyToRemove = _customFieldControllers[index].key;
      _customFieldControllers[index].value.dispose();
      _customFieldControllers.removeAt(index);
      _customFields.remove(keyToRemove);
    });
  }

  void _updateCustomFieldKey(int index, String newKey) {
    setState(() {
      String oldKey = _customFieldControllers[index].key;
      String value = _customFields[oldKey] ?? '';
      _customFields.remove(oldKey);
      _customFields[newKey] = value;
      _customFieldControllers[index] = MapEntry(
        newKey,
        _customFieldControllers[index].value,
      );
    });
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

    // Dispose custom field controllers
    for (var controller in _customFieldControllers) {
      controller.value.dispose();
    }

    super.dispose();
  }

  // Function to save the updated wallet details
  void _saveUpdatedDetails() async {
    // Update custom fields from controllers
    for (int i = 0; i < _customFieldControllers.length; i++) {
      String key = _customFieldControllers[i].key;
      String value = _customFieldControllers[i].value.text;
      _customFields[key] = value;
    }

    final updatedWallet = Wallet(
      id: widget.wallet.id,
      name: _nameController.text,
      number: _numberController.text,
      expiry: _expiryController.text,
      network: _network, // Updated network
      issuer: widget.wallet.issuer,
      customFields: _customFields.isNotEmpty ? _customFields : null,
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
    if (mounted) {
      Navigator.pop(context, updatedWallet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(
          "Edit Card Details",
          style: themeProvider.getTextStyle(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveUpdatedDetails, // Save the updated details
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          var wallet = provider.wallets.firstWhere(
            (w) => w.id == widget.wallet.id,
          );

          // Update the controllers with the current wallet details
          _nameController.text = wallet.name;
          _numberController.text = wallet.number;
          _expiryController.text = wallet.expiry;
          _maxlimitController.text = wallet.maxlimit ?? '0';
          _spendsController.text = wallet.spends ?? '0';
          _cardtypeController.text = wallet.cardtype ?? 'Paid';
          _billdateController.text = wallet.billdate ?? '10';
          _categoryController.text = wallet.category ?? 'Amazon';
          _annualFeeWaiverController.text = wallet.annualFeeWaiver ?? '0';
          _rewardsController.text = wallet.rewards ?? '0';

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
                            decoration: const InputDecoration(
                              labelText: 'Card Name',
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Card Number',
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 16,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly, // Only digits allowed
                              LengthLimitingTextInputFormatter(
                                16,
                              ), // Limit to 16 digits
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
                              labelText: 'Expiry Date (MMYY)',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly, // Only digits allowed
                              LengthLimitingTextInputFormatter(
                                4,
                              ), // Limit to 4 digits
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

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: DropdownButtonFormField<String>(
                        initialValue: "rupay",
                        decoration: const InputDecoration(
                          labelText: 'Card Network',
                          // border: OutlineInputBorder(),
                        ),
                        items:
                            [
                              'rupay',
                              'visa',
                              'mastercard',
                              'amex',
                              'discover',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,

                                child: Text(
                                  value.toUpperCase(),
                                  style: const TextStyle(fontSize: 16),
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
                    ),

                    Container(
                      margin: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _maxlimitController,
                            decoration: const InputDecoration(
                              labelText: 'Max Limit',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter limits';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // Spends Input
                          TextFormField(
                            controller: _spendsController,
                            decoration: const InputDecoration(
                              labelText: 'Spends',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter spends';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // Card Type Input
                          TextFormField(
                            controller: _cardtypeController,
                            decoration: const InputDecoration(
                              labelText: 'Card Type',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a card type';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // Bill Date Input
                          TextFormField(
                            controller: _billdateController,
                            decoration: const InputDecoration(
                              labelText: 'Bill Date',
                            ),
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
                          SizedBox(height: 20),
                          // Category Input
                          TextFormField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a category';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // Annual Fee Waiver Input
                          TextFormField(
                            keyboardType: TextInputType.number,
                            controller: _annualFeeWaiverController,
                            decoration: const InputDecoration(
                              labelText: 'Annual Fee Waiver',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an annual fee waiver';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // Rewards Input
                          TextFormField(
                            keyboardType: TextInputType.number,
                            controller: _rewardsController,
                            decoration: const InputDecoration(
                              labelText: 'Cashback %',
                            ),
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
                          SizedBox(height: 30),
                          // Custom Fields Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Custom Fields',
                                style: themeProvider.getTextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                                onPressed: _addCustomField,
                                tooltip: 'Add Custom Field',
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // Custom Fields List
                          ..._customFieldControllers.asMap().entries.map((
                            entry,
                          ) {
                            int index = entry.key;
                            String fieldKey = entry.value.key;
                            TextEditingController controller =
                                entry.value.value;

                            return Container(
                              margin: EdgeInsets.only(bottom: 15),
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: fieldKey,
                                          decoration: InputDecoration(
                                            labelText: 'Field Name',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (value) {
                                            _updateCustomFieldKey(index, value);
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _removeCustomField(index),
                                        tooltip: 'Remove Field',
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: 'Field Value',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
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
