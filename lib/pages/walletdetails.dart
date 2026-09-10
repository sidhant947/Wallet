import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet/services/clipboard_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:wallet/services/encryption_service.dart';
import 'package:wallet/services/image_service.dart';
import 'package:wallet/widgets/color_picker.dart';
import 'package:wallet/screens/homescreen.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/services/card_utils.dart';
import 'package:wallet/widgets/full_screen_image_viewer.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import 'package:wallet/widgets/encrypted_image_display.dart';
import 'package:wallet/screens/share_secure_screen.dart';

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

  void _showDeleteConfirmationDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          title: Text(
            'Delete Card?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${currentWallet.name}"? This action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await context.read<WalletProvider>().deleteWallet(currentWallet.id!);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Card Deleted!')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _formatCashback(String? spends, String? rewards, String symbol) {
    if (spends == null ||
        rewards == null ||
        spends.isEmpty ||
        rewards.isEmpty) {
      return '${symbol}0.00';
    }
    double spendsVal = double.tryParse(spends) ?? 0;
    double rewardsVal = double.tryParse(rewards) ?? 0;
    double result = (spendsVal * rewardsVal) / 100;
    return '$symbol${result.toStringAsFixed(2)}';
  }

  String _getFeeWaiverStatus(Wallet wallet, String symbol) {
    double spends = double.tryParse(wallet.spends ?? '0') ?? 0;
    double waiverRequirement =
        double.tryParse(wallet.annualFeeWaiver ?? '0') ?? 0;
    if (waiverRequirement == 0) return "Not Applicable";
    if (spends >= waiverRequirement) return "Waived Off";
    return "$symbol${(waiverRequirement - spends).toStringAsFixed(2)} more to waive";
  }

  Future<void> _openPdf(String pdfPath) async {
    try {
      final bytes = await EncryptionService.instance.decryptImageToBytes(pdfPath);
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to decrypt PDF attachment.')),
          );
        }
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/card_doc_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await tempFile.writeAsBytes(bytes);
      final result = await OpenFilex.open(tempFile.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message.isNotEmpty ? result.message : 'Could not open PDF file.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening PDF document.')),
        );
      }
    }
  }

  Widget _buildImageThumbnail(String imagePath, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                SmoothPageRoute(
                  page: FullScreenImageViewer(imagePath: imagePath),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.102)
                      : Colors.black.withValues(alpha: 0.078),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.302)
                        : Colors.black.withValues(alpha: 0.078),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: EncryptedImageDisplay(
                  imagePath: imagePath,
                  height: 100,
                  width: 150,
                  fit: BoxFit.cover,
                  cacheHeight: 200,
                  cacheWidth: 300,
                  errorWidget: Container(
                    height: 100,
                    width: 150,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.051)
                        : Colors.black.withValues(alpha: 0.031),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final symbol = startupProvider.selectedCurrencySymbol;
    bool isPathValid(String? path) => path != null && path.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.078)
                : Colors.black.withValues(alpha: 0.051),
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
                  ? Colors.white.withValues(alpha: 0.078)
                  : Colors.black.withValues(alpha: 0.051),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.share_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  SmoothPageRoute(page: ShareSecureScreen(wallet: currentWallet)),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.078)
                  : Colors.black.withValues(alpha: 0.051),
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
                  SmoothPageRoute(
                    page: WalletEditScreen(wallet: currentWallet),
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
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.078)
                  : Colors.black.withValues(alpha: 0.051),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              tooltip: 'Delete Card',
              onPressed: _showDeleteConfirmationDialog,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          GlassCreditCard(
            isMasked: false,
            wallet: currentWallet,
            onCardTap: () {
              ClipboardService.instance.copy(currentWallet.number);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Card Number Copied!')),
              );
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                ClipboardService.instance.copy(currentWallet.number);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Card Number Copied!')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text(
                'Tap card or here to copy card number',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          if (isPathValid(currentWallet.pdfPath))
            _LiquidGlassDetailSection(
              title: "Attached Document",
              icon: Icons.picture_as_pdf_outlined,
              children: [
                InkWell(
                  onTap: () => _openPdf(currentWallet.pdfPath!),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentWallet.pdfName ?? 'Card Document.pdf',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to view / open PDF',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.open_in_new_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black38),
                      ],
                    ),
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
                value: '$symbol${currentWallet.maxlimit ?? 'N/A'}',
              ),
              _LiquidGlassDetailTile(
                icon: Icons.receipt_long_outlined,
                title: 'Annual Spends',
                value: '$symbol${currentWallet.spends ?? '0.00'}',
              ),
              _LiquidGlassDetailTile(
                icon: Icons.card_giftcard_outlined,
                title: 'Estimated Cashback',
                value: _formatCashback(
                  currentWallet.spends,
                  currentWallet.rewards,
                  symbol,
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
                value: _getFeeWaiverStatus(currentWallet, symbol),
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
  File? _pdfFile;
  String? _pdfName;
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
    if (wallet.pdfPath != null && wallet.pdfPath!.isNotEmpty) {
      _pdfFile = File(wallet.pdfPath!);
      _pdfName = wallet.pdfName;
    }

    if (wallet.customFields != null) {
      wallet.customFields!.forEach((key, value) {
        _customFieldNameControllers.add(TextEditingController(text: key));
        _customFieldValueControllers.add(TextEditingController(text: value));
      });
    }

    _nameController.addListener(_updatePreview);
    _numberController.addListener(() {
      // Auto-detect and select card network
      final detected = CardUtils.detectCardNetwork(_numberController.text);
      if (detected != null && detected != _network) {
        setState(() => _network = detected);
      }
      _updatePreview();
    });
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
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
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

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _pdfFile = File(result.files.single.path!);
          _pdfName = result.files.single.name;
        });
      }
    } catch (_) {}
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

  /// Get maximum card number length
  int _getMaxCardLength(String network) {
    return 19;
  }

  void _saveUpdatedDetails() async {
    final provider = context.read<WalletProvider>();
    final navigator = Navigator.of(context);

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

      String? pdfPath = widget.wallet.pdfPath;
      String? pdfName = widget.wallet.pdfName;
      if (_pdfFile != null &&
          _pdfFile!.path != widget.wallet.pdfPath) {
        pdfPath = await saveImageToAppDirectory(_pdfFile!);
        pdfName = _pdfName;
      } else if (_pdfFile == null) {
        pdfPath = null;
        pdfName = null;
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
        pdfPath: pdfPath,
        pdfName: pdfName,
      );
      await DatabaseHelper.instance.updateWallet(updatedWallet);

      await provider.fetchWallets();
      navigator.pop(updatedWallet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final symbol = startupProvider.selectedCurrencySymbol;

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
        title: const SizedBox.shrink(),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
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
                _buildTextField(
                  _nameController,
                  'Card Name',
                  isDark,
                  validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _numberController,
                  'Card Number',
                  isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      _getMaxCardLength(_network),
                    ),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter a card number';
                    }
                    final cleaned = v.replaceAll(RegExp(r'\D'), '');
                    if (cleaned.length < 13 || cleaned.length > 19) {
                      return 'Card number must be 13-19 digits';
                    }
                    return null;
                  },
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
                  validator: (v) => v!.isEmpty ? 'Please enter an issuer' : null,
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
                const SizedBox(height: 16),
                _buildPdfPicker(isDark),
              ],
            ),
            _LiquidGlassDetailSection(
              title: "Financials",
              icon: Icons.account_balance_wallet_outlined,
              children: [
                _buildTextField(
                  _maxlimitController,
                  'Max Limit ($symbol)',
                  isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _spendsController,
                  'Current Spends ($symbol)',
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
                  'Annual Fee Waiver on Spends of ($symbol)',
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
    Widget? suffixIcon,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
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
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
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
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 14,
            ),
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
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
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
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageFile.path.endsWith('.enc')
                            ? EncryptedImageDisplay(
                                imagePath: imageFile.path,
                                height: 150,
                                width: 250,
                                fit: BoxFit.cover,
                                cacheWidth: 500,
                                cacheHeight: 300,
                              )
                            : Image.file(
                                imageFile,
                                height: 150,
                                width: 250,
                                fit: BoxFit.cover,
                                cacheWidth: 500,
                                cacheHeight: 300,
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
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

  Widget _buildPdfPicker(bool isDark) {
    final textColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0, top: 12.0),
          child: Text(
            'PDF DOCUMENT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Center(
          child: _pdfFile == null
              ? OutlinedButton.icon(
                  icon: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  label: Text(
                    "Select PDF",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _pickPdf,
                )
              : Container(
                  width: 250,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pdfName ?? 'Document.pdf',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () => setState(() {
                          _pdfFile = null;
                          _pdfName = null;
                        }),
                      ),
                    ],
                  ),
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
    final textTheme = Theme.of(context).textTheme;
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
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
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
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
    final textTheme = Theme.of(context).textTheme;
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    return InkWell(
      onTap: () {
        if (value.isNotEmpty && value != 'N/A') {
          HapticFeedback.lightImpact();
          ClipboardService.instance.copy(value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title copied!'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
