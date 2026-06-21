import 'dart:io';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/barcode_utils.dart';
import 'package:wallet/services/image_service.dart';
import 'package:wallet/widgets/barcode_card.dart';
import 'package:wallet/models/card_color_data.dart';
import 'package:wallet/widgets/color_picker.dart';
import 'package:wallet/models/pass_types.dart';

class BarcodeCardEntryForm extends StatefulWidget {
  final Pass? existingPass;
  const BarcodeCardEntryForm({
    super.key,
    this.existingPass,
  });

  @override
  State<BarcodeCardEntryForm> createState() => BarcodeCardEntryFormState();
}

class BarcodeCardEntryFormState extends State<BarcodeCardEntryForm> {
  final _organizationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoTextController = TextEditingController();
  final _barcodeValueController = TextEditingController();

  bool _showAdditionalDetails = false;
  bool _isSaving = false;

  String _selectedType = 'generic';
  String _selectedColor = 'obsidian';
  String _selectedBarcodeFormat = 'QR Code';
  String? _transitType;
  String? _frontImagePath;
  String? _backImagePath;

  final Map<String, List<Map<String, dynamic>>> _dynamicFields = {
    'primaryFields': [],
    'secondaryFields': [],
    'auxiliaryFields': [],
    'headerFields': [],
    'backFields': [],
  };

  final List<String> _passTypes = [
    // Retail
    'loyaltyCard',
    'giftCard',
    'offer',
    'coupon',
    'storeCard',
    // Tickets & Transit
    'boardingPass',
    'eventTicket',
    'transitPass',
    // Access
    'digitalCarKey',
    'campusId',
    'corporateBadge',
    'hotelKey',
    'multiFamilyKey',
    // Health
    'healthInsuranceCard',
    'healthTestRecord',
    'healthVaccineCard',
    // Identity
    'digitalCredential',
    // Generic
    'generic',
    'genericPrivate',
    'inStorePayment',
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
      _frontImagePath = p.frontImagePath;
      _backImagePath = p.backImagePath;

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
        final matchingEntry = cardColorPalette.entries
            .cast<MapEntry<String, CardColorData>?>()
            .firstWhere(
              (entry) {
                if (entry == null) return false;
                final hex =
                    '#${(entry.value.primary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
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

    setState(() => _isSaving = true);
    try {
      final pass = Pass(
        id: widget.existingPass?.id,
        type: _selectedType,
        organizationName: org,
        description: _descriptionController.text.trim(),
        logoText: _logoTextController.text.trim(),
        barcodeValue: value,
        barcodeFormat: BarcodeUtils.getInternalFormatName(
          _selectedBarcodeFormat,
        ),
        transitType: _transitType,
        frontImagePath: _frontImagePath,
        backImagePath: _backImagePath,
        stripImagePath: widget.existingPass?.stripImagePath,
        thumbnailImagePath: widget.existingPass?.thumbnailImagePath,
        fields: _dynamicFields,
        backgroundColor:
            '#${((cardColorPalette[_selectedColor]?.primary ?? Colors.black).toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      );

      if (widget.existingPass != null) {
        await PassDatabaseHelper.instance.updatePass(pass);
      } else {
        await PassDatabaseHelper.instance.insertPass(pass);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (_) {} finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void save() => _addData();

  Future<void> _scan() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        setState(() {
          _barcodeValueController.text = result.rawContent;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final encryptedPath = await saveImageToAppDirectory(File(pickedFile.path));
      setState(() {
        if (isFront) {
          _frontImagePath = encryptedPath;
        } else {
          _backImagePath = encryptedPath;
        }
      });
    }
  }

  Widget _buildImagePickerTile(String label, String? path, VoidCallback onTap, bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: path != null 
                  ? Colors.green.withValues(alpha: 0.5) 
                  : (isDark ? Colors.white12 : Colors.black12),
              ),
            ),
            child: path != null
              ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28)
              : Icon(
                  Icons.add_a_photo_outlined,
                  size: 24,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
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
      case 'loyaltyCard':
      case 'storeCard':
        _dynamicFields['primaryFields']!.add({'label': 'MEMBER NAME', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'BALANCE', 'value': ''},
          {'label': 'TIER', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'ACCOUNT #', 'value': ''},
          {'label': 'POINTS', 'value': ''},
        ]);
        break;
      case 'giftCard':
        _dynamicFields['primaryFields']!.add({'label': 'CARD NUMBER', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'BALANCE', 'value': ''},
          {'label': 'PIN', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'RECIPIENT', 'value': ''},
          {'label': 'EVENT #', 'value': ''},
        ]);
        break;
      case 'offer':
        _dynamicFields['primaryFields']!.add({'label': 'OFFER', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'PROVIDER', 'value': ''},
          {'label': 'EXPIRES', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'TERMS', 'value': ''},
          {'label': 'CODE', 'value': ''},
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
      case 'transitPass':
        _dynamicFields['primaryFields']!.addAll([
          {'label': 'FROM', 'value': ''},
          {'label': 'TO', 'value': ''},
        ]);
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'ROUTE', 'value': ''},
          {'label': 'FARE CLASS', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'SEAT', 'value': ''},
          {'label': 'COACH', 'value': ''},
          {'label': 'PLATFORM', 'value': ''},
        ]);
        break;
      case 'digitalCarKey':
        _dynamicFields['primaryFields']!.add({'label': 'VEHICLE', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'KEY STATUS', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'VIN', 'value': ''},
          {'label': 'DEVICE', 'value': ''},
        ]);
        break;
      case 'campusId':
        _dynamicFields['primaryFields']!.add({'label': 'STUDENT NAME', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'UNIVERSITY', 'value': ''},
          {'label': 'ID #', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'DORM', 'value': ''},
          {'label': 'YEAR', 'value': ''},
        ]);
        break;
      case 'corporateBadge':
        _dynamicFields['primaryFields']!.add({'label': 'EMPLOYEE NAME', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'COMPANY', 'value': ''},
          {'label': 'DEPT', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'ID #', 'value': ''},
          {'label': 'ACCESS LEVEL', 'value': ''},
        ]);
        break;
      case 'hotelKey':
        _dynamicFields['primaryFields']!.add({'label': 'GUEST NAME', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'HOTEL', 'value': ''},
          {'label': 'ROOM #', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'CHECK-IN', 'value': ''},
          {'label': 'CHECK-OUT', 'value': ''},
        ]);
        break;
      case 'multiFamilyKey':
        _dynamicFields['primaryFields']!.add({'label': 'RESIDENT NAME', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'PROPERTY', 'value': ''},
          {'label': 'UNIT #', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'ACCESS LEVEL', 'value': ''},
        ]);
        break;
      case 'healthInsuranceCard':
        _dynamicFields['primaryFields']!.add({'label': 'MEMBER NAME', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'POLICY #', 'value': ''},
          {'label': 'PROVIDER', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'GROUP #', 'value': ''},
          {'label': 'PCN', 'value': ''},
        ]);
        break;
      case 'healthTestRecord':
        _dynamicFields['primaryFields']!.add({'label': 'TEST TYPE', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'RESULT', 'value': ''},
          {'label': 'DATE', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'LAB', 'value': ''},
          {'label': 'PROVIDER', 'value': ''},
        ]);
        break;
      case 'healthVaccineCard':
        _dynamicFields['primaryFields']!.add({'label': 'VACCINE', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'DOSE', 'value': ''},
          {'label': 'DATE', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'MANUFACTURER', 'value': ''},
          {'label': 'LOT #', 'value': ''},
        ]);
        break;
      case 'digitalCredential':
        _dynamicFields['primaryFields']!.add({'label': 'DOCUMENT TYPE', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'ISSUER', 'value': ''},
          {'label': 'ID #', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'EXPIRY', 'value': ''},
          {'label': 'VERIFIED', 'value': ''},
        ]);
        break;
      case 'genericPrivate':
        _dynamicFields['primaryFields']!.add({'label': 'ORGANIZATION', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'DATA TYPE', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'ID #', 'value': ''},
          {'label': 'NOTES', 'value': ''},
        ]);
        break;
      case 'inStorePayment':
        _dynamicFields['primaryFields']!.add({'label': 'CARD NUMBER', 'value': ''});
        _dynamicFields['secondaryFields']!.addAll([
          {'label': 'MEMBER NAME', 'value': ''},
        ]);
        _dynamicFields['auxiliaryFields']!.addAll([
          {'label': 'CARD TYPE', 'value': ''},
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
        _dynamicFields['secondaryFields']!.add(
          {'label': 'DETAILS', 'value': ''},
        );
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
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
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

  List<DropdownMenuItem<String>> _buildCategorizedPassTypeItems() {
    final items = <DropdownMenuItem<String>>[];
    final categories = [
      PassCategory.retail,
      PassCategory.tickets,
      PassCategory.access,
      PassCategory.health,
      PassCategory.identity,
      PassCategory.generic,
    ];

    for (final category in categories) {
      final typesInCategory = _passTypes
          .where((t) => PassType.fromValue(t).category == category)
          .toList();
      if (typesInCategory.isEmpty) continue;

      // Add category header
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: 'header_${category.name}',
          child: Text(
            '── ${category.label.toUpperCase()} ──',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black45,
              letterSpacing: 1,
            ),
          ),
        ),
      );

      for (final type in typesInCategory) {
        items.add(
          DropdownMenuItem<String>(
            value: type,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: [
                  Icon(
                    PassType.fromValue(type).icon,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Text(getPassTypeLabel(type)),
                ],
              ),
            ),
          ),
        );
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return _buildManualEntryView();
  }

  Widget _buildManualEntryView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [

        BarcodeCard(
          pass: Pass(
            type: _selectedType,
            organizationName:
                _organizationController.text.isEmpty
                    ? 'ORGANIZATION'
                    : _organizationController.text,
            description:
                _descriptionController.text.isEmpty
                    ? widget.existingPass?.description
                    : _descriptionController.text,
            logoText:
                _logoTextController.text.isEmpty
                    ? widget.existingPass?.logoText
                    : _logoTextController.text,
            barcodeValue:
                _barcodeValueController.text.isEmpty
                    ? '123456789'
                    : _barcodeValueController.text,
            barcodeFormat: BarcodeUtils.getInternalFormatName(
              _selectedBarcodeFormat,
            ),
            transitType: _transitType,
            fields: _dynamicFields,
            frontImagePath: _frontImagePath,
            backImagePath: _backImagePath,
            stripImagePath: widget.existingPass?.stripImagePath,
            thumbnailImagePath: widget.existingPass?.thumbnailImagePath,
            backgroundColor:
                '#${((cardColorPalette[_selectedColor]?.primary ?? Colors.black).toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            foregroundColor: widget.existingPass?.foregroundColor,
            labelColor: widget.existingPass?.labelColor,
          ),
          onCardTap: () {},
        ),
        const SizedBox(height: 24),
        ColorPicker(
          selectedColor: _selectedColor,
          onColorSelected: (color) => setState(() => _selectedColor = color),
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
          initialValue: _selectedBarcodeFormat,
          decoration: const InputDecoration(labelText: 'Barcode Format'),
          items:
              BarcodeUtils.supportedFormats.keys
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
          onChanged: (v) => setState(() => _selectedBarcodeFormat = v!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedType,
          decoration: const InputDecoration(labelText: 'Pass Category'),
          items: _buildCategorizedPassTypeItems(),
          onChanged: (v) {
            if (v != null && v != _selectedType) {
              setState(() {
                _selectedType = v;
                _prepopulateFields(force: true);
              });
            }
          },
        ),
        if (_selectedType == 'boardingPass' || _selectedType == 'transitPass') ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _transitType,
            decoration: const InputDecoration(labelText: 'Transit Type'),
            items: [
              'BUS',
              'RAIL',
              'TRAM',
              'FERRY',
              'OTHER',
              'PKTransitTypeAir',
              'PKTransitTypeBoat',
              'PKTransitTypeBus',
              'PKTransitTypeRail',
            ]
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.replaceFirst('PKTransitType', '')),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _transitType = v!),
          ),
        ],
        const SizedBox(height: 24),

        Text(
          'ATTACHMENTS (OPTIONAL)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.black54,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildImagePickerTile(
                'Front Side',
                _frontImagePath,
                () => _pickImage(true),
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildImagePickerTile(
                'Back Side',
                _backImagePath,
                () => _pickImage(false),
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (!_showAdditionalDetails)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showAdditionalDetails = true),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Additional Details'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),

        if (_showAdditionalDetails) ...[
          const Divider(height: 48),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _logoTextController,
            decoration: const InputDecoration(labelText: 'Logo Text'),
          ),
          const SizedBox(height: 32),

          // Dynamic Fields Sections
          _buildFieldSection('Primary Fields (Main Info)', 'primaryFields'),
          _buildFieldSection('Secondary Fields (Details)', 'secondaryFields'),
          _buildFieldSection('Auxiliary Fields (More)', 'auxiliaryFields'),
          _buildFieldSection('Header Fields (Top Right)', 'headerFields'),
          _buildFieldSection('Back Details (Fine Print)', 'backFields'),
        ],

        const SizedBox(height: 32),
        if (widget.existingPass == null)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _isSaving ? null : _addData,
              child: _isSaving
                  ? CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : const Text(
                      'SAVE PASS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
