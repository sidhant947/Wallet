import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/dataentry.dart';
import '../models/db_helper.dart';
import '../models/provider_helper.dart';
import '../models/theme_provider.dart';
import '../widgets/glass_credit_card.dart';

// (FullScreenImageViewer class remains the same)
class FullScreenImageViewer extends StatelessWidget {
  final File imageFile;
  const FullScreenImageViewer({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.file(imageFile),
        ),
      ),
    );
  }
}

// (WalletDetailScreen class remains the same)
class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletDetailScreen({super.key, required this.wallet});
  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late Wallet currentWallet;

  @override
  void initState() {
    super.initState();
    currentWallet = widget.wallet;
  }

  String _formatCashback(String? spends, String? rewards) {
    if (spends == null ||
        rewards == null ||
        spends.isEmpty ||
        rewards.isEmpty) {
      return '₹0.00';
    }
    double spendsVal = double.tryParse(spends) ?? 0;
    double rewardsVal = double.tryParse(rewards) ?? 0;
    double result = (spendsVal * rewardsVal) / 100;
    return '₹${result.toStringAsFixed(2)}';
  }

  String _getFeeWaiverStatus(Wallet wallet) {
    double spends = double.tryParse(wallet.spends ?? '0') ?? 0;
    double waiverRequirement =
        double.tryParse(wallet.annualFeeWaiver ?? '0') ?? 0;
    if (waiverRequirement == 0) return "Not Applicable";
    if (spends >= waiverRequirement) return "Waived Off";
    return "₹${(waiverRequirement - spends).toStringAsFixed(2)} more to waive";
  }

  Widget _buildImageThumbnail(String imagePath, String label) {
    final imageFile = File(imagePath);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FullScreenImageViewer(imageFile: imageFile),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFile,
                height: 100,
                width: 150,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 100,
                  width: 150,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.error_outline),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPathValid(String? path) => path != null && path.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentWallet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updatedWallet = await Navigator.push<Wallet>(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletEditScreen(wallet: currentWallet),
                ),
              );

              if (updatedWallet != null && mounted) {
                setState(() {
                  currentWallet = updatedWallet;
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SizedBox(
            height: 235,
            child: GlassCreditCard(
              isMasked: false,
              wallet: currentWallet,
              onCardTap: () {
                Clipboard.setData(ClipboardData(text: currentWallet.number));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Card Number Copied!')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (isPathValid(currentWallet.frontImagePath) ||
              isPathValid(currentWallet.backImagePath))
            _DetailSection(
              title: "Card Images",
              children: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (isPathValid(currentWallet.frontImagePath))
                        _buildImageThumbnail(
                          currentWallet.frontImagePath!,
                          'Front',
                        ),
                      if (isPathValid(currentWallet.backImagePath))
                        _buildImageThumbnail(
                          currentWallet.backImagePath!,
                          'Back',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          _DetailSection(
            title: "Financials",
            children: [
              _DetailTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Max Limit',
                value: '₹${currentWallet.maxlimit ?? 'N/A'}',
              ),
              _DetailTile(
                icon: Icons.receipt_long_outlined,
                title: 'Annual Spends',
                value: '₹${currentWallet.spends ?? '0.00'}',
              ),
              _DetailTile(
                icon: Icons.card_giftcard_outlined,
                title: 'Estimated Cashback',
                value: _formatCashback(
                  currentWallet.spends,
                  currentWallet.rewards,
                ),
              ),
            ],
          ),
          _DetailSection(
            title: "Billing & Terms",
            children: [
              _DetailTile(
                icon: Icons.event_note_outlined,
                title: 'Bill Generation Date',
                value: 'Every ${currentWallet.billdate ?? 'N/A'}',
              ),
              _DetailTile(
                icon: Icons.verified_outlined,
                title: 'Annual Fee Waiver',
                value: _getFeeWaiverStatus(currentWallet),
              ),
              _DetailTile(
                icon: Icons.credit_card,
                title: 'Card Type',
                value: currentWallet.cardtype ?? 'N/A',
              ),
            ],
          ),
          if (currentWallet.customFields != null &&
              currentWallet.customFields!.isNotEmpty)
            _DetailSection(
              title: "Custom Fields",
              children: currentWallet.customFields!.entries.map((entry) {
                return _DetailTile(
                  icon: Icons.info_outline,
                  title: entry.key,
                  value: entry.value,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// --- MODIFIED: WalletEditScreen ---

class WalletEditScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletEditScreen({super.key, required this.wallet});
  @override
  WalletEditScreenState createState() => WalletEditScreenState();
}

class WalletEditScreenState extends State<WalletEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController,
      _numberController,
      _expiryController,
      _issuerController,
      _maxlimitController,
      _spendsController,
      _cardtypeController,
      _billdateController,
      _categoryController,
      _annualFeeWaiverController,
      _rewardsController;
  late String _network;
  late String _selectedColor;
  final List<TextEditingController> _customFieldNameControllers = [];
  final List<TextEditingController> _customFieldValueControllers = [];

  // FIXED: Added state for image files and the picker
  File? _frontImageFile;
  File? _backImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final wallet = widget.wallet;
    _nameController = TextEditingController(text: wallet.name);
    _numberController = TextEditingController(text: wallet.number);
    _expiryController = TextEditingController(text: wallet.expiry);
    _network = wallet.network ?? "visa";
    _issuerController = TextEditingController(text: wallet.issuer);
    _maxlimitController = TextEditingController(text: wallet.maxlimit);
    _spendsController = TextEditingController(text: wallet.spends);
    _cardtypeController = TextEditingController(text: wallet.cardtype);
    _billdateController = TextEditingController(text: wallet.billdate);
    _categoryController = TextEditingController(text: wallet.category);
    _annualFeeWaiverController = TextEditingController(
      text: wallet.annualFeeWaiver,
    );
    _rewardsController = TextEditingController(text: wallet.rewards);
    _selectedColor = wallet.color ?? 'default';

    // FIXED: Initialize image files if they already exist
    if (wallet.frontImagePath != null && wallet.frontImagePath!.isNotEmpty) {
      _frontImageFile = File(wallet.frontImagePath!);
    }
    if (wallet.backImagePath != null && wallet.backImagePath!.isNotEmpty) {
      _backImageFile = File(wallet.backImagePath!);
    }

    if (wallet.customFields != null) {
      wallet.customFields!.forEach((key, value) {
        _customFieldNameControllers.add(TextEditingController(text: key));
        _customFieldValueControllers.add(TextEditingController(text: value));
      });
    }

    _nameController.addListener(_updatePreview);
    _numberController.addListener(_updatePreview);
    _expiryController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updatePreview);
    _numberController.removeListener(_updatePreview);
    _expiryController.removeListener(_updatePreview);
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _issuerController.dispose();
    _maxlimitController.dispose();
    _spendsController.dispose();
    _cardtypeController.dispose();
    _billdateController.dispose();
    _categoryController.dispose();
    _annualFeeWaiverController.dispose();
    _rewardsController.dispose();
    for (var controller in _customFieldNameControllers) {
      controller.dispose();
    }
    for (var controller in _customFieldValueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updatePreview() {
    if (mounted) {
      setState(() {});
    }
  }

  // FIXED: Added image picker logic
  Future<void> _pickImage(ImageSource source, bool isFront) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _frontImageFile = File(pickedFile.path);
        } else {
          _backImageFile = File(pickedFile.path);
        }
      });
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

  void _saveUpdatedDetails() async {
    if (_formKey.currentState!.validate()) {
      Map<String, String> customFields = {};
      for (int i = 0; i < _customFieldNameControllers.length; i++) {
        String fieldName = _customFieldNameControllers[i].text.trim();
        String fieldValue = _customFieldValueControllers[i].text.trim();
        if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
          customFields[fieldName] = fieldValue;
        }
      }

      // FIXED: Save new images if they were picked, otherwise keep the old ones.
      String? frontImagePath = widget.wallet.frontImagePath;
      if (_frontImageFile != null &&
          _frontImageFile!.path != widget.wallet.frontImagePath) {
        frontImagePath = await saveImageToAppDirectory(_frontImageFile!);
      } else if (_frontImageFile == null) {
        frontImagePath = null; // Handle image removal
      }

      String? backImagePath = widget.wallet.backImagePath;
      if (_backImageFile != null &&
          _backImageFile!.path != widget.wallet.backImagePath) {
        backImagePath = await saveImageToAppDirectory(_backImageFile!);
      } else if (_backImageFile == null) {
        backImagePath = null; // Handle image removal
      }

      final updatedWallet = Wallet(
        id: widget.wallet.id,
        name: _nameController.text,
        number: _numberController.text,
        expiry: _expiryController.text,
        network: _network,
        issuer: _issuerController.text,
        maxlimit: _maxlimitController.text,
        spends: _spendsController.text,
        cardtype: _cardtypeController.text,
        billdate: _billdateController.text,
        category: _categoryController.text,
        annualFeeWaiver: _annualFeeWaiverController.text,
        rewards: _rewardsController.text,
        customFields: customFields,
        color: _selectedColor,
        frontImagePath: frontImagePath,
        backImagePath: backImagePath,
      );
      final provider = context.read<WalletProvider>();
      final navigator = Navigator.of(context);
      await DatabaseHelper.instance.updateWallet(updatedWallet);

      provider.fetchWallets();
      navigator.pop(updatedWallet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewWallet = Wallet(
      id: widget.wallet.id,
      name: _nameController.text.isEmpty ? 'CARD NAME' : _nameController.text,
      number: _numberController.text,
      expiry: _expiryController.text,
      network: _network,
      color: _selectedColor,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Card"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _saveUpdatedDetails,
              child: const Text("SAVE"),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            GlassCreditCard(
              isMasked: false,
              wallet: previewWallet,
              onCardTap: () {},
            ),
            const SizedBox(height: 24),
            _DetailSection(
              title: "Primary Details",
              children: [
                ColorPicker(
                  selectedColor: _selectedColor,
                  onColorSelected: (color) {
                    setState(() => _selectedColor = color);
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Card Name'),
                  validator: (v) => v!.isEmpty ? 'Cannot be empty' : null,
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
                    labelText: 'Card Issuer (e.g. HDFC)',
                  ),
                  validator: (v) => v!.isEmpty ? 'Cannot be empty' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _network,
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
                    if (newValue != null) {
                      setState(() {
                        _network = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            // FIXED: Added image picker section
            _DetailSection(
              title: "Card Images",
              children: [
                ImagePickerWidget(
                  title: 'Front Image',
                  imageFile: _frontImageFile,
                  onPickImage: () => _pickImage(ImageSource.gallery, true),
                  onRemoveImage: () => setState(() => _frontImageFile = null),
                ),
                const SizedBox(height: 16),
                ImagePickerWidget(
                  title: 'Back Image',
                  imageFile: _backImageFile,
                  onPickImage: () => _pickImage(ImageSource.gallery, false),
                  onRemoveImage: () => setState(() => _backImageFile = null),
                ),
              ],
            ),
            _DetailSection(
              title: "Financials",
              children: [
                TextFormField(
                  controller: _maxlimitController,
                  decoration: const InputDecoration(labelText: 'Max Limit (₹)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _spendsController,
                  decoration: const InputDecoration(
                    labelText: 'Current Spends (₹)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rewardsController,
                  decoration: const InputDecoration(
                    labelText: 'Cashback Rate (%)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                ),
              ],
            ),
            _DetailSection(
              title: "Billing & Terms",
              children: [
                TextFormField(
                  controller: _billdateController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Date (e.g., 15)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _annualFeeWaiverController,
                  decoration: const InputDecoration(
                    labelText: 'Annual Fee Waiver on Spends of (₹)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardtypeController,
                  decoration: const InputDecoration(
                    labelText: 'Card Type (e.g., LTF, Paid)',
                  ),
                ),
              ],
            ),
            _DetailSection(
              title: "Custom Fields",
              children: [
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
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Custom Field"),
                    onPressed: _addCustomField,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// (Rest of the file remains the same: _DetailSection, _DetailTile)
class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DetailSection({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(51)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Provider.of<ThemeProvider>(
              context,
            ).getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: themeProvider.getTextStyle().color?.withAlpha(153),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
