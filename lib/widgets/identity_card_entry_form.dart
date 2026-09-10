import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/services/image_service.dart';
import 'package:wallet/services/auto_backup_service.dart';
import 'package:wallet/widgets/identity_card_widget.dart';
import 'package:wallet/widgets/color_picker.dart';

class IdentityCardEntryForm extends StatefulWidget {
  final IdentityCard? existingCard;
  const IdentityCardEntryForm({super.key, this.existingCard});

  @override
  State<IdentityCardEntryForm> createState() => IdentityCardEntryFormState();
}

class IdentityCardEntryFormState extends State<IdentityCardEntryForm> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _cardTypeController = TextEditingController();
  String? _frontImagePath;
  String? _backImagePath;
  String? _pdfPath;
  String? _pdfName;
  String _selectedColor = 'obsidian';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCard != null) {
      _nameController.text = widget.existingCard!.name;
      _valueController.text = widget.existingCard!.value;
      _cardTypeController.text = widget.existingCard!.cardType;
      _frontImagePath = widget.existingCard!.frontImagePath;
      _backImagePath = widget.existingCard!.backImagePath;
      _pdfPath = widget.existingCard!.pdfPath;
      _pdfName = widget.existingCard!.pdfName;
      _selectedColor = widget.existingCard!.color ?? 'obsidian';
    }
    _nameController.addListener(() => setState(() {}));
    _valueController.addListener(() => setState(() {}));
    _cardTypeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _cardTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final encryptedPath = await saveImageToAppDirectory(
        File(pickedFile.path),
      );
      setState(() {
        if (isFront) {
          _frontImagePath = encryptedPath;
        } else {
          _backImagePath = encryptedPath;
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
        final originalFile = File(result.files.single.path!);
        final encryptedPath = await saveImageToAppDirectory(originalFile);
        setState(() {
          _pdfPath = encryptedPath;
          _pdfName = result.files.single.name;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveData() async {
    final name = _nameController.text.trim();
    final value = _valueController.text.trim();
    final cardType = _cardTypeController.text.trim();

    if (name.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Value are required.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final card = IdentityCard(
        id: widget.existingCard?.id,
        name: name,
        value: value,
        cardType: cardType.isEmpty ? 'Identity Card' : cardType,
        frontImagePath: _frontImagePath,
        backImagePath: _backImagePath,
        pdfPath: _pdfPath,
        pdfName: _pdfName,
        color: _selectedColor,
        orderIndex: widget.existingCard?.orderIndex ?? 0,
      );

      if (widget.existingCard != null) {
        await IdentityDatabaseHelper.instance.updateIdentity(card);
      } else {
        await IdentityDatabaseHelper.instance.insertIdentity(card);
        AutoBackupService.triggerBackup();
      }

      if (mounted) {
        context.read<IdentityProvider>().fetchIdentities();
        Navigator.pop(context, true);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void save() => _saveData();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Preview
        IdentityCardWidget(
          card: IdentityCard(
            name: _nameController.text.isEmpty ? 'NAME' : _nameController.text,
            value: _valueController.text.isEmpty
                ? 'ID NUMBER'
                : _valueController.text,
            cardType: _cardTypeController.text.isEmpty
                ? 'IDENTITY CARD'
                : _cardTypeController.text,
            frontImagePath: _frontImagePath,
            backImagePath: _backImagePath,
            pdfPath: _pdfPath,
            pdfName: _pdfName,
            color: _selectedColor,
          ),
          onTap: () {},
        ),
        const SizedBox(height: 32),

        ColorPicker(
          selectedColor: _selectedColor,
          onColorSelected: (color) => setState(() => _selectedColor = color),
        ),
        const SizedBox(height: 32),

        TextField(
          controller: _cardTypeController,
          decoration: InputDecoration(
            labelText: 'Card Label (e.g. Passport, License)',
            hintText: 'e.g. Passport',
            prefixIcon: const Icon(Icons.label_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'e.g. John Doe',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _valueController,
          decoration: InputDecoration(
            labelText: 'ID Value / Number',
            hintText: 'e.g. 123-456-789',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),

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
                onClear: () => setState(() => _frontImagePath = null),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImagePickerTile(
                'Back Side',
                _backImagePath,
                () => _pickImage(false),
                isDark,
                onClear: () => setState(() => _backImagePath = null),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImagePickerTile(
                _pdfName ?? 'PDF Doc',
                _pdfPath,
                _pickPdf,
                isDark,
                icon: Icons.picture_as_pdf_outlined,
                onClear: () => setState(() {
                  _pdfPath = null;
                  _pdfName = null;
                }),
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        if (widget.existingCard == null)
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
              onPressed: _isSaving ? null : _saveData,
              child: _isSaving
                  ? CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : const Text(
                      'SAVE IDENTITY CARD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePickerTile(
    String label,
    String? path,
    VoidCallback onTap,
    bool isDark, {
    IconData? icon,
    VoidCallback? onClear,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: path != null
                        ? Colors.green.withValues(alpha: 0.5)
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
                child: path != null
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 28,
                      )
                    : Icon(
                        icon ?? Icons.add_a_photo_outlined,
                        size: 24,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
              ),
              if (path != null && onClear != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
