// lib/models/dataentry.dart

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/widgets/glass_credit_card.dart'; // Import the shared GlassCreditCard
import 'db_helper.dart';

// Enum to define the type of card we are creating
enum BarcodeCardType { identity, loyalty }

// -----------------------------------------------------------------------------
// CREDIT CARD DATA ENTRY SCREEN (WITH LIVE PREVIEW)
// -----------------------------------------------------------------------------
class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _issuerController = TextEditingController();
  String _network = "visa"; // Default to a common network

  final _customFieldNameControllers = <TextEditingController>[];
  final _customFieldValueControllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    // Add listeners to update the UI on text change
    _nameController.addListener(() => setState(() {}));
    _numberController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _issuerController.dispose();
    for (var controller in _customFieldNameControllers) {
      controller.dispose();
    }
    for (var controller in _customFieldValueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addData() async {
    if (_formKey.currentState!.validate()) {
      Map<String, String> customFields = {};
      for (int i = 0; i < _customFieldNameControllers.length; i++) {
        String fieldName = _customFieldNameControllers[i].text;
        String fieldValue = _customFieldValueControllers[i].text;
        if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
          customFields[fieldName] = fieldValue;
        }
      }

      Wallet wallet = Wallet(
        name: _nameController.text,
        number: _numberController.text,
        expiry: _expiryController.text,
        network: _network,
        issuer: _issuerController.text,
        customFields: customFields.isNotEmpty ? customFields : null,
      );
      await DatabaseHelper.instance.insertWallet(wallet);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _addCustomField() {
    setState(() {
      _customFieldNameControllers.add(TextEditingController());
      _customFieldValueControllers.add(TextEditingController());
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFieldNameControllers[index].dispose();
      _customFieldValueControllers[index].dispose();
      _customFieldNameControllers.removeAt(index);
      _customFieldValueControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Create a dummy wallet for the preview
    final previewWallet = Wallet(
      name: _nameController.text.isEmpty ? "CARDHOLDER" : _nameController.text,
      number: _numberController.text.padRight(16, '•'),
      expiry: _expiryController.text.padRight(4, '•'),
      network: _network,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Card')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Live Card Preview
            GlassCreditCard(
              wallet: previewWallet,
              isMasked: false, // Always show details in preview
              onCardTap: () {}, // No action on tap in preview
            ),
            const SizedBox(height: 24),

            // Form Fields Section
            _FormSection(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _network,
                  decoration: const InputDecoration(labelText: 'Card Network'),
                  items: ['visa', 'mastercard', 'rupay', 'amex', 'discover']
                      .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.toUpperCase()),
                        );
                      })
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _network = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Cardholder Name',
                  ),
                  validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(labelText: 'Card Number'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  validator: (v) =>
                      v!.length < 15 ? 'Enter a valid number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(labelText: 'Expiry (MMYY)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) => v!.length != 4 ? 'Must be 4 digits' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _issuerController,
                  decoration: const InputDecoration(
                    labelText: 'Card Issuer (e.g., HDFC)',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter an issuer' : null,
                ),
              ],
            ),

            // Custom Fields Section
            _FormSection(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Custom Fields",
                      style: themeProvider.getTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: _addCustomField,
                    ),
                  ],
                ),
                if (_customFieldNameControllers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        "No custom fields added.",
                        style: themeProvider.getTextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _customFieldNameControllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customFieldNameControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Field Name',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _customFieldValueControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Value',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeCustomField(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _addData,
              child: const Text('Save Card'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// UPDATED BARCODE DATA ENTRY SCREEN
// -----------------------------------------------------------------------------
class BarcodeDataEntryScreen extends StatefulWidget {
  final BarcodeCardType cardType;

  const BarcodeDataEntryScreen({super.key, required this.cardType});

  @override
  State<BarcodeDataEntryScreen> createState() => _BarcodeDataEntryScreenState();
}

class _BarcodeDataEntryScreenState extends State<BarcodeDataEntryScreen> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();

  Map<String, String> _getConfig() {
    switch (widget.cardType) {
      case BarcodeCardType.identity:
        return {
          'appBarTitle': 'Save Identity Card',
          'nameHint': 'Identity Name (e.g., Driver License)',
          'numberHint': '12345678 / XXXXX78923X',
          'saveButtonText': 'Save Identity Card',
        };
      case BarcodeCardType.loyalty:
        return {
          'appBarTitle': 'Save Loyalty Card',
          'nameHint': 'Program Name (e.g., Starbucks)',
          'numberHint': '87989237498',
          'saveButtonText': 'Save Loyalty Card',
        };
    }
  }

  void _addData() async {
    final name = _nameController.text.trim();
    final number = _numberController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (name.isEmpty || number.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    try {
      if (widget.cardType == BarcodeCardType.identity) {
        final newIdentity = Identity(
          identityName: name,
          identityNumber: number,
        );
        await IdentityDatabaseHelper.instance.insertIdentity(newIdentity);
      } else {
        final newLoyalty = Loyalty(loyaltyName: name, loyaltyNumber: number);
        await LoyaltyDatabaseHelper.instance.insertLoyalty(newLoyalty);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Error saving card.')),
        );
      }
    }
  }

  Future<void> _scan() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        setState(() => _numberController.text = result.rawContent);
      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        // Handle camera permission denied
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Scaffold(
      appBar: AppBar(title: Text(config['appBarTitle']!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: config['nameHint']),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numberController,
              decoration: InputDecoration(labelText: config['numberHint']),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Scan Barcode"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withAlpha(128),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _scan,
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _addData,
              child: Text(config['saveButtonText']!),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Helper widget for styling form sections
class _FormSection extends StatelessWidget {
  final List<Widget> children;
  const _FormSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
