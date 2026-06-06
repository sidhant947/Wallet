// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/services/card_utils.dart';
import 'package:wallet/services/encryption_service.dart';
import 'package:wallet/services/pkpass_service.dart';
import 'package:wallet/services/barcode_utils.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import 'package:wallet/widgets/barcode_card.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'db_helper.dart';

// --- Premium Liquid Glass Color Palette ---
// These colors are carefully chosen to complement the liquid glass aesthetic
// with deep, sophisticated tones that work beautifully with transparency effects

class CardColorData {
  final Color primary;
  final Color secondary;
  final Color accent;
  final String name;

  const CardColorData({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.name,
  });
}

// Premium color palette - Modern 2024 Design
const Map<String, CardColorData> cardColorPalette = {
  'obsidian': CardColorData(
    primary: Color(0xFF0F0F0F),
    secondary: Color(0xFF1A1A1A),
    accent: Color(0xFF262626),
    name: 'Obsidian',
  ),
  'midnight': CardColorData(
    primary: Color(0xFF0F172A),
    secondary: Color(0xFF1E293B),
    accent: Color(0xFF334155),
    name: 'Midnight',
  ),
  'slate': CardColorData(
    primary: Color(0xFF1E293B),
    secondary: Color(0xFF334155),
    accent: Color(0xFF475569),
    name: 'Slate',
  ),
  'indigo': CardColorData(
    primary: Color(0xFF1E1B4B),
    secondary: Color(0xFF312E81),
    accent: Color(0xFF4338CA),
    name: 'Indigo',
  ),
  'violet': CardColorData(
    primary: Color(0xFF2E1065),
    secondary: Color(0xFF4C1D95),
    accent: Color(0xFF6D28D9),
    name: 'Violet',
  ),
  'ocean': CardColorData(
    primary: Color(0xFF0C4A6E),
    secondary: Color(0xFF075985),
    accent: Color(0xFF0284C7),
    name: 'Ocean',
  ),
  'teal': CardColorData(
    primary: Color(0xFF134E4A),
    secondary: Color(0xFF115E59),
    accent: Color(0xFF0D9488),
    name: 'Teal',
  ),
  'emerald': CardColorData(
    primary: Color(0xFF064E3B),
    secondary: Color(0xFF065F46),
    accent: Color(0xFF059669),
    name: 'Emerald',
  ),
  'amber': CardColorData(
    primary: Color(0xFF78350F),
    secondary: Color(0xFF92400E),
    accent: Color(0xFFD97706),
    name: 'Amber',
  ),
  'rose': CardColorData(
    primary: Color(0xFF4C0519),
    secondary: Color(0xFF881337),
    accent: Color(0xFFE11D48),
    name: 'Rose',
  ),
};

// Legacy support - map old color names to new palette
const Map<String, Color> cardColors = {
  'default': Color(0xFF0D0D0D),
  'obsidian': Color(0xFF0D0D0D),
  'midnight': Color(0xFF0F0F23),
  'graphite': Color(0xFF1C1C1C),
  'titanium': Color(0xFF3A3A4A),
  'cosmic': Color(0xFF1A0A2E),
  'ocean': Color(0xFF0A1628),
  'emerald': Color(0xFF0A1F1A),
  'rose': Color(0xFF2A1A1F),
  // Legacy colors mapping to new palette
  'blue': Color(0xFF0A1628),
  'green': Color(0xFF0A1F1A),
  'red': Color(0xFF2A1A1F),
  'purple': Color(0xFF1A0A2E),
  'orange': Color(0xFF3A3A4A),
};

// --- Enhanced Color Picker Widget with Gradient Preview ---
class ColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    // Use the new premium palette
    final colorOptions = cardColorPalette.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text(
            'Card Style',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colorOptions.length,
            itemBuilder: (context, index) {
              final entry = colorOptions[index];
              final colorKey = entry.key;
              final colorData = entry.value;
              final isSelected =
                  selectedColor == colorKey ||
                  (selectedColor == 'default' && colorKey == 'obsidian');

              return Padding(
                padding: EdgeInsets.only(
                  right: index < colorOptions.length - 1 ? 12 : 0,
                ),
                child: GestureDetector(
                  onTap: () => onColorSelected(colorKey),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorData.accent,
                          colorData.secondary,
                          colorData.primary,
                        ],
                      ),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : Colors.white.withValues(alpha: 0.15),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorData.secondary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // Glass shine effect
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Selection indicator
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: isDark ? Colors.black : Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        // Color name
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Text(
                            colorData.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ... (ImagePickerWidget remains the same) ...
class ImagePickerWidget extends StatelessWidget {
  final String title;
  final File? imageFile;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const ImagePickerWidget({
    super.key,
    required this.title,
    this.imageFile,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0, top: 12.0),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 16,
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
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.502),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onPickImage,
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        imageFile!,
                        height: 150,
                        width: 250,
                        fit: BoxFit.cover,
                        cacheWidth: 500,
                        cacheHeight: 300,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: onRemoveImage,
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

// ... (saveImageToAppDirectory function remains the same) ...
/// Saves an image to the app's documents directory and encrypts it.
///
/// The image is first copied to the app directory, then encrypted using
/// AES-256-GCM. The original unencrypted file is deleted after encryption.
/// Returns the path to the encrypted file (.enc extension).
Future<String?> saveImageToAppDirectory(File imageFile) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final fileExtension = p.extension(imageFile.path);
    final newFileName = '${const Uuid().v4()}$fileExtension';
    final newPath = p.join(directory.path, newFileName);
    final newFile = await imageFile.copy(newPath);

    // Encrypt the saved image file
    final encryptedPath = await EncryptionService.instance.encryptImageFile(
      newFile.path,
    );

    // Securely delete the original source file (e.g. from camera cache or gallery)
    // to ensure no plaintext traces are left on disk.
    if (await imageFile.exists()) {
      await imageFile.delete();
      debugPrint("EncryptionService: Original source image deleted.");
    }

    return encryptedPath;
  } catch (e) {
    debugPrint("Error saving/encrypting image: $e");
    return null;
  }
}

// ... (CreditCardEntryForm remains the same) ...
class CreditCardEntryForm extends StatefulWidget {
  const CreditCardEntryForm({super.key});

  @override
  State<CreditCardEntryForm> createState() => _CreditCardEntryFormState();
}

class _CreditCardEntryFormState extends State<CreditCardEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _issuerController = TextEditingController();
  String _network = "visa";
  String _selectedColor = 'default';
  File? _frontImageFile;
  File? _backImageFile;
  bool _showAdditionalDetails = false;

  final _customFieldNameControllers = <TextEditingController>[];
  final _customFieldValueControllers = <TextEditingController>[];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _numberController.addListener(() {
      // Auto-detect and select card network
      final detected = CardUtils.detectCardNetwork(_numberController.text);
      if (detected != null && detected != _network) {
        setState(() => _network = detected);
      } else {
        setState(() {});
      }
    });
    _expiryController.addListener(() => setState(() {}));
  }

  /// Get maximum card number length based on selected network
  int _getMaxCardLength(String network) {
    final validLengths = CardUtils.getValidLengthsForNetwork(network);
    return validLengths.reduce((a, b) => a > b ? a : b);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _issuerController.dispose();
    for (var c in _customFieldNameControllers) {
      c.dispose();
    }
    for (var c in _customFieldValueControllers) {
      c.dispose();
    }
    super.dispose();
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

  void _addData() async {
    if (_formKey.currentState!.validate()) {
      String? frontImagePath;
      if (_frontImageFile != null) {
        frontImagePath = await saveImageToAppDirectory(_frontImageFile!);
      }
      String? backImagePath;
      if (_backImageFile != null) {
        backImagePath = await saveImageToAppDirectory(_backImageFile!);
      }

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
        color: _selectedColor,
        frontImagePath: frontImagePath,
        backImagePath: backImagePath,
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
    final previewWallet = Wallet(
      name: _nameController.text.isEmpty
          ? "CARD NAME" // FIXED: Changed placeholder on card preview
          : _nameController.text,
      number: _numberController.text.padRight(16, '•'),
      expiry: _expiryController.text.padRight(4, '•'),
      network: _network,
      color: _selectedColor,
    );

    return Form(
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
          _FormSection(
            children: [
              ColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) =>
                    setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                // FIXED: Changed input field label
                decoration: const InputDecoration(labelText: 'Card Name'),
                validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  suffixIcon: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      final isDark = themeProvider.isDarkMode;
                      final detectedNetwork = CardUtils.detectCardNetwork(
                        _numberController.text,
                      );
                      if (detectedNetwork == null ||
                          _numberController.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          detectedNetwork.toUpperCase(),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.702)
                                : Colors.black.withValues(alpha: 0.702),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_getMaxCardLength(_network)),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please enter a card number';
                  }
                  final detectedNetwork = CardUtils.detectCardNetwork(v);
                  if (detectedNetwork == null) {
                    return 'Unable to detect card network';
                  }
                  if (!CardUtils.isValidLengthForNetwork(v, detectedNetwork)) {
                    return CardUtils.getLengthErrorMessage(detectedNetwork);
                  }
                  return null;
                },
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
                validator: (v) => v!.isEmpty ? 'Please enter an issuer' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _network,
                decoration: const InputDecoration(labelText: 'Card Network'),
                items: ['visa', 'mastercard', 'rupay', 'amex', 'discover'].map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _network = newValue!),
              ),
            ],
          ),
          if (!_showAdditionalDetails)
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showAdditionalDetails = true),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Additional Info'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          if (_showAdditionalDetails) ...[
            _FormSection(
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
          ],
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BARCODE CARD DATA ENTRY FORM (MODIFIED)
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// BARCODE CARD DATA ENTRY FORM (MODIFIED for Passes)
// -----------------------------------------------------------------------------
enum EntryMode { selection, manual }

class BarcodeCardEntryForm extends StatefulWidget {
  final Pass? existingPass;
  const BarcodeCardEntryForm({
    super.key,
    this.existingPass,
  });

  @override
  State<BarcodeCardEntryForm> createState() => _BarcodeCardEntryFormState();
}

class _BarcodeCardEntryFormState extends State<BarcodeCardEntryForm> {
  final _organizationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoTextController = TextEditingController();
  final _barcodeValueController = TextEditingController();

  bool _showAdditionalDetails = false;

  String _selectedType = 'generic';
  String _selectedColor = 'obsidian';
  String _selectedBarcodeFormat = 'QR Code';
  String? _transitType;
  
  final Map<String, List<Map<String, dynamic>>> _dynamicFields = {
    'primaryFields': [],
    'secondaryFields': [],
    'auxiliaryFields': [],
    'headerFields': [],
    'backFields': [],
  };
  
  final List<String> _passTypes = [
    'generic',
    'boardingPass',
    'coupon',
    'eventTicket',
    'storeCard',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.existingPass != null) {

      _showAdditionalDetails = true;
      final p = widget.existingPass!;
      _organizationController.text = p.organizationName;
      _descriptionController.text = p.description ?? '';
      _logoTextController.text = p.logoText ?? '';
      _barcodeValueController.text = p.barcodeValue;
      _selectedType = p.type;
      _transitType = p.transitType;
      _selectedBarcodeFormat = BarcodeUtils.getLabelFromFormat(p.barcodeFormat);

      // Deep copy fields if they exist
      if (p.fields != null) {
        p.fields!.forEach((key, value) {
          if (value is List && _dynamicFields.containsKey(key)) {
            _dynamicFields[key] = List<Map<String, dynamic>>.from(
              value.map((v) => Map<String, dynamic>.from(v as Map)),
            );
          }
        });
      }

      // Load color from existing pass background color
      if (p.backgroundColor != null) {
        final matchingEntry = cardColorPalette.entries.cast<MapEntry<String, CardColorData>?>().firstWhere(
          (entry) {
            if (entry == null) return false;
            final hex = '#${(entry.value.primary.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
            return p.backgroundColor!.toLowerCase() == hex.toLowerCase();
          },
          orElse: () => null,
        );
        if (matchingEntry != null) {
          _selectedColor = matchingEntry.key;
        }
      }
    } else {
      _prepopulateFields();
    }

    _organizationController.addListener(() => setState(() {}));
    _barcodeValueController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _organizationController.dispose();
    _descriptionController.dispose();
    _logoTextController.dispose();
    _barcodeValueController.dispose();
    super.dispose();
  }

  void _addData() async {
    final org = _organizationController.text.trim();
    final value = _barcodeValueController.text.trim();

    if (org.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization is required.')),
      );
      return;
    }

    try {
      final pass = Pass(
        id: widget.existingPass?.id,
        type: _selectedType,
        organizationName: org,
        description: _descriptionController.text.trim(),
        logoText: _logoTextController.text.trim(),
        barcodeValue: value,
        barcodeFormat: BarcodeUtils.getInternalFormatName(_selectedBarcodeFormat),
        transitType: _transitType,
        frontImagePath: null,
        backImagePath: null,
        stripImagePath: null,
        thumbnailImagePath: null,
        fields: _dynamicFields,
        backgroundColor: '#${((cardColorPalette[_selectedColor]?.primary ?? Colors.black).value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      );

      if (widget.existingPass != null) {
        await PassDatabaseHelper.instance.updatePass(pass);
      } else {
        await PassDatabaseHelper.instance.insertPass(pass);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving pass: $e');
    }
  }

  Future<void> _scan() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        setState(() {
          _barcodeValueController.text = result.rawContent;
    
        });
      }
    } catch (e) {
      debugPrint('Scan error: $e');
    }
  }

  Future<void> _importPkpass() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pkpass'],
      );

      if (result != null && result.files.single.path != null) {
        final pass = await PkpassService.instance.parsePkpass(result.files.single.path!);
        if (pass != null) {
          if (mounted) {
            // Confirm import
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Import Pass'),
                content: Text('Do you want to import "${pass.organizationName}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Import'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await PassDatabaseHelper.instance.insertPass(pass);
              if (mounted) {
                context.read<PassProvider>().fetchPasses();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pass imported successfully!')),
                );
                Navigator.pop(context, true);
              }
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to parse .pkpass file.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _prepopulateFields({bool force = false}) {
    if (force) {
      for (var list in _dynamicFields.values) {
        list.clear();
      }
      // Reset transit type if not boarding pass
      if (_selectedType != 'boardingPass') {
        _transitType = null;
      }
    } else {
      // Only pre-populate if all field sections are currently empty
      bool allEmpty = _dynamicFields.values.every((list) => list.isEmpty);
      if (!allEmpty) return;
    }

    switch (_selectedType) {
      case 'boardingPass':
        _dynamicFields['primaryFields']!.addAll([
          {'label': 'FROM', 'value': ''},
          {'label': 'TO', 'value': ''},
        ]);
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'PASSENGER', 'value': ''},
          {'label': 'FLIGHT', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'GATE', 'value': ''},
          {'label': 'SEAT', 'value': ''},
          {'label': 'DEPARTURE', 'value': ''},
          {'label': 'ARRIVAL', 'value': ''},
        ]);
        break;
      case 'storeCard':
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'BALANCE', 'value': ''},
          {'label': 'MEMBER NAME', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'TIER', 'value': ''},
          {'label': 'ACCOUNT #', 'value': ''},
        ]);
        break;
      case 'eventTicket':
        _dynamicFields['primaryFields']!.add({'label': 'EVENT', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'VENUE', 'value': ''},
          {'label': 'DATE', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'SECTION', 'value': ''},
          {'label': 'ROW', 'value': ''},
          {'label': 'SEAT', 'value': ''},
          {'label': 'TIME', 'value': ''},
        ]);
        break;
      case 'coupon':
        _dynamicFields['primaryFields']!.add({'label': 'OFFER', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'EXPIRES', 'value': ''},
          {'label': 'MERCHANT', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.add({'label': 'TERMS', 'value': ''});
        break;
      case 'generic':
        _dynamicFields['secondaryFields']!.add({'label': 'DETAILS', 'value': ''});
        _dynamicFields['auxiliaryFields']!.add({'label': 'DATE', 'value': ''});
        break;
    }
    
    // Always add some default back fields
    _dynamicFields['backFields']!.addAll([
      {'label': 'TERMS & CONDITIONS', 'value': ''},
      {'label': 'CONTACT', 'value': ''},
    ]);
  }

  Widget _buildFieldSection(String title, String sectionKey) {
    final fields = _dynamicFields[sectionKey]!;
    if (fields.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...List.generate(fields.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TextFormField(
              initialValue: fields[index]['value']?.toString(),
              decoration: InputDecoration(
                labelText: fields[index]['label']?.toString().toUpperCase(),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => fields[index]['value'] = val),
            ),
          );
        }),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
      ],
    );
  }

  String _getPassTypeLabel(String type) {
    switch (type) {
      case 'boardingPass': return 'BOARDING PASS';
      case 'eventTicket': return 'EVENT TICKET';
      case 'coupon': return 'COUPON';
      case 'storeCard': return 'STORE CARD';
      case 'generic': return 'GENERIC / OTHER';
      default: return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildManualEntryView();
  }

  Widget _buildManualEntryView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        BarcodeCard(
          pass: Pass(
            type: _selectedType,
            organizationName: _organizationController.text.isEmpty ? 'ORGANIZATION' : _organizationController.text,
            description: _descriptionController.text.isEmpty ? widget.existingPass?.description : _descriptionController.text,
            logoText: _logoTextController.text.isEmpty ? widget.existingPass?.logoText : _logoTextController.text,
            barcodeValue: _barcodeValueController.text.isEmpty ? '123456789' : _barcodeValueController.text,
            barcodeFormat: BarcodeUtils.getInternalFormatName(_selectedBarcodeFormat),
            transitType: _transitType,
            fields: _dynamicFields,
            frontImagePath: null,
            backImagePath: null,
            stripImagePath: null,
            thumbnailImagePath: null,
            backgroundColor: '#${((cardColorPalette[_selectedColor]?.primary ?? Colors.black).value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            foregroundColor: widget.existingPass?.foregroundColor,
            labelColor: widget.existingPass?.labelColor,
          ),
          onCardTap: () {},
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _organizationController,
          decoration: const InputDecoration(labelText: 'Name (Organization)'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _barcodeValueController,
          decoration: InputDecoration(
            labelText: 'Barcode Value',
            suffixIcon: IconButton(
              icon: const Icon(Icons.camera_alt_rounded),
              tooltip: 'Scan Barcode',
              onPressed: _scan,
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedBarcodeFormat,
          decoration: const InputDecoration(labelText: 'Barcode Format'),
          items: BarcodeUtils.supportedFormats.keys.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
          onChanged: (v) => setState(() => _selectedBarcodeFormat = v!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: const InputDecoration(labelText: 'Pass Category'),
          items: _passTypes.map((t) => DropdownMenuItem(value: t, child: Text(_getPassTypeLabel(t)))).toList(),
          onChanged: (v) {
            if (v != null && v != _selectedType) {
              setState(() {
                _selectedType = v;
                _prepopulateFields(force: true);
              });
            }
          },
        ),
        if (_selectedType == 'boardingPass') ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _transitType,
            decoration: const InputDecoration(labelText: 'Transit Type'),
            items: ['PKTransitTypeAir', 'PKTransitTypeBoat', 'PKTransitTypeBus', 'PKTransitTypeRail']
                .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceFirst('PKTransitType', '')))).toList(),
            onChanged: (v) => setState(() => _transitType = v!),
          ),
        ],
        const SizedBox(height: 24),
        
        if (!_showAdditionalDetails)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showAdditionalDetails = true),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Additional Details'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          
        if (_showAdditionalDetails) ...[
          const Divider(height: 48),
          const SizedBox(height: 16),
          TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 16),
          TextFormField(controller: _logoTextController, decoration: const InputDecoration(labelText: 'Logo Text')),
          const SizedBox(height: 32),
          
          // Dynamic Fields Sections
          _buildFieldSection('Primary Fields (Main Info)', 'primaryFields'),
          _buildFieldSection('Secondary Fields (Details)', 'secondaryFields'),
          _buildFieldSection('Auxiliary Fields (More)', 'auxiliaryFields'),
          _buildFieldSection('Header Fields (Top Right)', 'headerFields'),
          _buildFieldSection('Back Details (Fine Print)', 'backFields'),
        ],
        
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _addData,
          child: const Text('Save Pass'),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _importPkpass,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Import .pkpass file'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.purple,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ... (_FormSection widget remains the same) ...
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.051), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
