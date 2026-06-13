import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/services/card_utils.dart';
import 'package:wallet/services/image_service.dart';
import 'package:wallet/widgets/color_picker.dart';
import 'package:wallet/widgets/form_section.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import 'package:wallet/widgets/image_picker_widget.dart';

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
    _nameController.addListener(_onFieldChanged);
    _numberController.addListener(_onNumberChanged);
    _expiryController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _onNumberChanged() {
    final detected = CardUtils.detectCardNetwork(_numberController.text);
    if (detected != null && detected != _network) {
      setState(() => _network = detected);
    } else if (mounted) {
      setState(() {});
    }
  }

  /// Get maximum card number length based on selected network
  int _getMaxCardLength(String network) {
    final validLengths = CardUtils.getValidLengthsForNetwork(network);
    return validLengths.reduce((a, b) => a > b ? a : b);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _numberController.removeListener(_onNumberChanged);
    _expiryController.removeListener(_onFieldChanged);
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
      name: _nameController.text.isEmpty ? "CARD NAME" : _nameController.text,
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
          FormSection(
            children: [
              ColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) =>
                    setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
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
                  if (!CardUtils.isValidCardNumber(v)) {
                    return 'Invalid card number';
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
            FormSection(
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
            FormSection(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CUSTOM FIELDS",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
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
