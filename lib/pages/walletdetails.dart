// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/dataentry.dart';
import '../models/db_helper.dart';
import '../models/provider_helper.dart';
import '../models/theme_provider.dart';
import '../widgets/glass_credit_card.dart';

// FullScreenImageViewer with liquid glass theme
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
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
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

// WalletDetailScreen with liquid glass design
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

  Widget _buildImageThumbnail(String imagePath, String label, bool isDark) {
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  height: 100,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 100,
                    width: 150,
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    child: Icon(
                      Icons.error_outline,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    bool isPathValid(String? path) => path != null && path.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentWallet.name),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () async {
                final updatedWallet = await Navigator.push<Wallet>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WalletEditScreen(wallet: currentWallet),
                  ),
                );

                if (updatedWallet != null && mounted) {
                  setState(() {
                    currentWallet = updatedWallet;
                  });
                }
              },
            ),
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
          const SizedBox(height: 20),
          if (isPathValid(currentWallet.frontImagePath) ||
              isPathValid(currentWallet.backImagePath))
            _LiquidGlassDetailSection(
              title: "Card Images",
              icon: Icons.photo_library_outlined,
              children: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (isPathValid(currentWallet.frontImagePath))
                        _buildImageThumbnail(
                          currentWallet.frontImagePath!,
                          'Front',
                          isDark,
                        ),
                      if (isPathValid(currentWallet.backImagePath))
                        _buildImageThumbnail(
                          currentWallet.backImagePath!,
                          'Back',
                          isDark,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          _LiquidGlassDetailSection(
            title: "Financials",
            icon: Icons.account_balance_wallet_outlined,
            children: [
              _LiquidGlassDetailTile(
                icon: Icons.credit_score_outlined,
                title: 'Max Limit',
                value: '₹${currentWallet.maxlimit ?? 'N/A'}',
              ),
              _LiquidGlassDetailTile(
                icon: Icons.receipt_long_outlined,
                title: 'Annual Spends',
                value: '₹${currentWallet.spends ?? '0.00'}',
              ),
              _LiquidGlassDetailTile(
                icon: Icons.card_giftcard_outlined,
                title: 'Estimated Cashback',
                value: _formatCashback(
                  currentWallet.spends,
                  currentWallet.rewards,
                ),
                valueColor: Colors.green.shade400,
              ),
            ],
          ),
          _LiquidGlassDetailSection(
            title: "Billing & Terms",
            icon: Icons.event_note_outlined,
            children: [
              _LiquidGlassDetailTile(
                icon: Icons.calendar_today_outlined,
                title: 'Bill Generation Date',
                value: 'Every ${currentWallet.billdate ?? 'N/A'}',
              ),
              _LiquidGlassDetailTile(
                icon: Icons.verified_outlined,
                title: 'Annual Fee Waiver',
                value: _getFeeWaiverStatus(currentWallet),
              ),
              _LiquidGlassDetailTile(
                icon: Icons.credit_card_outlined,
                title: 'Card Type',
                value: currentWallet.cardtype ?? 'N/A',
              ),
            ],
          ),
          if (currentWallet.customFields != null &&
              currentWallet.customFields!.isNotEmpty)
            _LiquidGlassDetailSection(
              title: "Custom Fields",
              icon: Icons.tune_outlined,
              children: currentWallet.customFields!.entries.map((entry) {
                return _LiquidGlassDetailTile(
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

// --- WalletEditScreen with liquid glass design ---
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

      String? frontImagePath = widget.wallet.frontImagePath;
      if (_frontImageFile != null &&
          _frontImageFile!.path != widget.wallet.frontImagePath) {
        frontImagePath = await saveImageToAppDirectory(_frontImageFile!);
      } else if (_frontImageFile == null) {
        frontImagePath = null;
      }

      String? backImagePath = widget.wallet.backImagePath;
      if (_backImageFile != null &&
          _backImageFile!.path != widget.wallet.backImagePath) {
        backImagePath = await saveImageToAppDirectory(_backImageFile!);
      } else if (_backImageFile == null) {
        backImagePath = null;
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

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
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            child: FilledButton(
              onPressed: _saveUpdatedDetails,
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
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
            _LiquidGlassDetailSection(
              title: "Primary Details",
              icon: Icons.credit_card_outlined,
              children: [
                ColorPicker(
                  selectedColor: _selectedColor,
                  onColorSelected: (color) {
                    setState(() => _selectedColor = color);
                  },
                ),
                const SizedBox(height: 24),
                _buildTextField(_nameController, 'Card Name', isDark),
                const SizedBox(height: 16),
                _buildTextField(
                  _numberController,
                  'Card Number',
                  isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  validator: (v) =>
                      v!.length < 15 ? 'Enter a valid number' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _expiryController,
                  'Expiry (MMYY)',
                  isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) => v!.length != 4 ? 'Must be 4 digits' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _issuerController,
                  'Card Issuer (e.g. HDFC)',
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildDropdown('Card Network', _network, isDark, (newValue) {
                  if (newValue != null) {
                    setState(() => _network = newValue);
                  }
                }),
              ],
            ),
            _LiquidGlassDetailSection(
              title: "Card Images",
              icon: Icons.photo_library_outlined,
              children: [
                _buildImagePicker(
                  'Front Image',
                  _frontImageFile,
                  isDark,
                  () => _pickImage(ImageSource.gallery, true),
                  () => setState(() => _frontImageFile = null),
                ),
                const SizedBox(height: 16),
                _buildImagePicker(
                  'Back Image',
                  _backImageFile,
                  isDark,
                  () => _pickImage(ImageSource.gallery, false),
                  () => setState(() => _backImageFile = null),
                ),
              ],
            ),
            _LiquidGlassDetailSection(
              title: "Financials",
              icon: Icons.account_balance_wallet_outlined,
              children: [
                _buildTextField(
                  _maxlimitController,
                  'Max Limit (₹)',
                  isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _spendsController,
                  'Current Spends (₹)',
                  isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _rewardsController,
                  'Cashback Rate (%)',
                  isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                ),
              ],
            ),
            _LiquidGlassDetailSection(
              title: "Billing & Terms",
              icon: Icons.event_note_outlined,
              children: [
                _buildTextField(
                  _billdateController,
                  'Bill Date (e.g., 15)',
                  isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _annualFeeWaiverController,
                  'Annual Fee Waiver on Spends of (₹)',
                  isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _cardtypeController,
                  'Card Type (e.g., LTF, Paid)',
                  isDark,
                ),
              ],
            ),
            _LiquidGlassDetailSection(
              title: "Custom Fields",
              icon: Icons.tune_outlined,
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
                            child: _buildTextField(
                              _customFieldNameControllers[index],
                              'Field Name',
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              _customFieldValueControllers[index],
                              'Value',
                              isDark,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red.shade400,
                            ),
                            onPressed: () => _removeCustomField(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Center(
                  child: TextButton.icon(
                    icon: Icon(
                      Icons.add_rounded,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    label: Text(
                      "Add Custom Field",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool isDark, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator ?? (v) => v!.isEmpty ? 'Cannot be empty' : null,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    bool isDark,
    ValueChanged<String?> onChanged,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.5)),
          border: InputBorder.none,
        ),
        dropdownColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        style: TextStyle(color: textColor),
        items: ['visa', 'mastercard', 'rupay', 'amex', 'discover'].map((
          String value,
        ) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value.toUpperCase()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildImagePicker(
    String title,
    File? imageFile,
    bool isDark,
    VoidCallback onPick,
    VoidCallback onRemove,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            title,
            style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14),
          ),
        ),
        Center(
          child: imageFile == null
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text("Select Image"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onPick,
                )
              : Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.08),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          imageFile,
                          height: 150,
                          width: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: onRemove,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// --- LIQUID GLASS DETAIL SECTION ---
class _LiquidGlassDetailSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const _LiquidGlassDetailSection({
    required this.title,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor.withOpacity(0.4)),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: textColor.withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.03),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- LIQUID GLASS DETAIL TILE ---
class _LiquidGlassDetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _LiquidGlassDetailTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: textColor.withOpacity(0.6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? textColor,
            ),
          ),
        ],
      ),
    );
  }
}
