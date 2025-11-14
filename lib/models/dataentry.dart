// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'db_helper.dart';

// Enum to define the type of card we are creating
enum BarcodeCardType { identity, loyalty }

// --- Color Picker Widget and Color Definitions ---
const Map<String, Color> cardColors = {
  'default': Colors.black,
  'blue': Color(0xFF1565C0),
  'green': Color(0xFF2E7D32),
  'red': Color(0xFFC62828),
  'purple': Color(0xFF6A1B9A),
  'orange': Color(0xFFEF6C00),
};

// ... (ColorPicker widget remains the same) ...
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Card Color',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 16,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: cardColors.entries.map((entry) {
            final colorKey = entry.key;
            final colorValue = entry.value;
            final isSelected = selectedColor == colorKey;

            return GestureDetector(
              onTap: () => onColorSelected(colorKey),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorValue,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        )
                      : Border.all(color: Colors.grey.withAlpha(51)),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
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
                      ).colorScheme.primary.withAlpha(128),
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
Future<String?> saveImageToAppDirectory(File imageFile) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final fileExtension = p.extension(imageFile.path);
    final newFileName = '${const Uuid().v4()}$fileExtension';
    final newPath = p.join(directory.path, newFileName);
    final newFile = await imageFile.copy(newPath);
    return newFile.path;
  } catch (e) {
    debugPrint("Error saving image: $e");
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

  final _customFieldNameControllers = <TextEditingController>[];
  final _customFieldValueControllers = <TextEditingController>[];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
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
    for (var c in _customFieldNameControllers) {
      c.dispose();
    }
    for (var c in _customFieldValueControllers) {
      c.dispose();
    }
    super.dispose();
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                // FIXED: Changed input field label
                decoration: const InputDecoration(labelText: 'Card Name'),
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
                validator: (v) => v!.isEmpty ? 'Please enter an issuer' : null,
              ),
            ],
          ),
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
    );
  }
}

// -----------------------------------------------------------------------------
// BARCODE CARD DATA ENTRY FORM (MODIFIED)
// -----------------------------------------------------------------------------
class BarcodeCardEntryForm extends StatefulWidget {
  final BarcodeCardType cardType;
  const BarcodeCardEntryForm({super.key, required this.cardType});

  @override
  State<BarcodeCardEntryForm> createState() => _BarcodeCardEntryFormState();
}

class _BarcodeCardEntryFormState extends State<BarcodeCardEntryForm> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  String _selectedColor = 'default';
  File? _frontImageFile;
  File? _backImageFile;
  final ImagePicker _picker = ImagePicker();

  // --- ADDED ---
  @override
  void initState() {
    super.initState();
    // Add listeners to update the preview in real-time
    _nameController.addListener(() => setState(() {}));
    _numberController.addListener(() => setState(() {}));
  }

  // --- ADDED ---
  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Map<String, String> _getConfig() {
    switch (widget.cardType) {
      case BarcodeCardType.identity:
        return {
          'nameHint': 'Identity Name (e.g., Driver License)',
          'numberHint': '12345678 / XXXXX78923X',
          'saveButtonText': 'Save Identity Card',
        };
      case BarcodeCardType.loyalty:
        return {
          'nameHint': 'Program Name (e.g., Starbucks)',
          'numberHint': '87989237498',
          'saveButtonText': 'Save Loyalty Card',
        };
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

  void _addData() async {
    // ... (This function remains the same)
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
      String? frontImagePath;
      if (_frontImageFile != null) {
        frontImagePath = await saveImageToAppDirectory(_frontImageFile!);
      }
      String? backImagePath;
      if (_backImageFile != null) {
        backImagePath = await saveImageToAppDirectory(_backImageFile!);
      }

      if (widget.cardType == BarcodeCardType.identity) {
        final newIdentity = Identity(
          identityName: name,
          identityNumber: number,
          color: _selectedColor,
          frontImagePath: frontImagePath,
          backImagePath: backImagePath,
        );
        await IdentityDatabaseHelper.instance.insertIdentity(newIdentity);
      } else {
        final newLoyalty = Loyalty(
          loyaltyName: name,
          loyaltyNumber: number,
          color: _selectedColor,
          frontImagePath: frontImagePath,
          backImagePath: backImagePath,
        );
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
    // ... (This function remains the same)
    try {
      final result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        setState(() => _numberController.text = result.rawContent);
      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- ADDED ---
        // Live preview of the barcode card
        _BarcodeCardPreview(
          name: _nameController.text,
          number: _numberController.text,
          colorName: _selectedColor,
          cardType: widget.cardType,
          namePlaceholder: config['nameHint']!,
          numberPlaceholder: config['numberHint']!,
        ),

        // --- END OF ADDED SECTION ---
        const SizedBox(height: 24), // --- MODIFIED: Was 20
        ColorPicker(
          selectedColor: _selectedColor,
          onColorSelected: (color) => setState(() => _selectedColor = color),
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 24),
        ImagePickerWidget(
          title: 'Front Image (Optional)',
          imageFile: _frontImageFile,
          onPickImage: () => _pickImage(ImageSource.gallery, true),
          onRemoveImage: () => setState(() => _frontImageFile = null),
        ),
        const SizedBox(height: 16),
        ImagePickerWidget(
          title: 'Back Image (Optional)',
          imageFile: _backImageFile,
          onPickImage: () => _pickImage(ImageSource.gallery, false),
          onRemoveImage: () => setState(() => _backImageFile = null),
        ),
        const SizedBox(height: 40),
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
    );
  }
}

// -----------------------------------------------------------------------------
// --- ADDED: NEW WIDGET FOR BARCODE CARD PREVIEW ---
// -----------------------------------------------------------------------------
class _BarcodeCardPreview extends StatelessWidget {
  final String name;
  final String number;
  final String colorName;
  final BarcodeCardType cardType;
  final String namePlaceholder;
  final String numberPlaceholder;

  const _BarcodeCardPreview({
    required this.name,
    required this.number,
    required this.colorName,
    required this.cardType,
    required this.namePlaceholder,
    required this.numberPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    // Use the cardColors map to get the actual color from the name
    final Color cardBGColor = cardColors[colorName] ?? Colors.black;
    final String typeLabel = cardType == BarcodeCardType.identity
        ? 'Identity Card'
        : 'Loyalty Card';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20.0, top: 20.0),
      padding: const EdgeInsets.only(
        top: 20.0,
        left: 20.0,
        right: 20.0,
        bottom: 24.0,
      ),
      decoration: BoxDecoration(
        color: cardBGColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardBGColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                typeLabel,
                style: const TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 0.8),
                  fontSize: 14,
                ),
              ),
              // This is just a visual icon to match your home screen's card
              const Icon(
                Icons.copy_all_outlined,
                color: Color.fromRGBO(255, 255, 255, 0.8),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name.isEmpty ? namePlaceholder : name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Bebas', // Assuming you use this font
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            number.isEmpty ? numberPlaceholder : number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
