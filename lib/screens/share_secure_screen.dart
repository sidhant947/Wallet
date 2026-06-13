import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/encryption_service.dart';
import 'package:wallet/services/pkpass_service.dart';

class ShareSecureScreen extends StatefulWidget {
  final Pass? pass;
  final Wallet? wallet;
  final IdentityCard? identity;

  const ShareSecureScreen({super.key, this.pass, this.wallet, this.identity})
      : assert(pass != null || wallet != null || identity != null);

  @override
  State<ShareSecureScreen> createState() => _ShareSecureScreenState();
}

class _ShareSecureScreenState extends State<ShareSecureScreen> {
  List<String>? _encryptedChunks;
  int _selectedChunkIndex = 0;

  Pass? get _pass => widget.pass;
  Wallet? get _wallet => widget.wallet;
  IdentityCard? get _identity => widget.identity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptPassword());
  }

  void _promptPassword() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();
        bool obscure = true;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
            title: const Text('Set Transfer Password', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter a password to encrypt the transfer. The receiver will need this to import.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
                  onSubmitted: (_) => _onPasswordSet(controller.text),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => _onPasswordSet(controller.text),
                child: const Text('Generate QR'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onPasswordSet(String password) {
    Navigator.pop(context);
    if (password.isEmpty) return;

    Map<String, dynamic> dataMap;
    String shareType;

    if (_pass != null) {
      dataMap = _pass!.toMap();
      shareType = 'pass';
    } else if (_wallet != null) {
      dataMap = _wallet!.toMap();
      shareType = 'wallet';
    } else {
      dataMap = _identity!.toMap();
      shareType = 'identity';
    }

    dataMap.remove('frontImagePath');
    dataMap.remove('backImagePath');
    dataMap.remove('stripImagePath');
    dataMap.remove('thumbnailImagePath');
    dataMap.remove('id');

    final payload = {'type': shareType, 'data': dataMap};
    final chunks = EncryptionService.instance.encryptForTransfer(jsonEncode(payload), password);
    dataMap.clear();
    payload.clear();

    if (chunks.isEmpty) return;
    setState(() {
      _encryptedChunks = chunks;
      _selectedChunkIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    String shareType;
    String displayName;

    if (_pass != null) {
      shareType = 'pass';
      displayName = _pass!.organizationName;
    } else if (_wallet != null) {
      shareType = 'wallet';
      displayName = _wallet!.name;
    } else {
      shareType = 'identity';
      displayName = _identity!.name;
    }

    final hasChunks = _encryptedChunks != null && _encryptedChunks!.isNotEmpty;
    final multiChunk = hasChunks && _encryptedChunks!.length > 1;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Share ${shareType == 'pass' ? 'Pass' : 'Card'}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!hasChunks)
                _buildPasswordPrompt(isDark, textColor)
              else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      BarcodeWidget(
                        barcode: Barcode.qrCode(),
                        data: _encryptedChunks![_selectedChunkIndex],
                        width: 250,
                        height: 250,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        multiChunk
                            ? 'SCAN ALL ${_encryptedChunks!.length} QR CODES'
                            : 'SCAN TO IMPORT',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (multiChunk) ...[
                  const SizedBox(height: 16),
                  _buildChunkNavigation(textColor),
                ],
              ],
              const SizedBox(height: 40),
              if (_pass != null) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final bytes = await PkpassService.instance.generatePkpass(_pass!);
                    if (bytes != null) {
                      String safeName = _pass!.organizationName
                          .replaceAll(RegExp(r'[^\w\s-]'), '')
                          .trim()
                          .replaceAll(' ', '_');
                      if (safeName.isEmpty) safeName = 'pass';
                      final fileName = '$safeName.pkpass';

                      if (Platform.isAndroid) {
                        try {
                          const channel = MethodChannel('com.sidhant.wallet/save_file');
                          await channel.invokeMethod('savePkpass', {
                            'bytes': bytes,
                            'name': fileName,
                          });
                        } catch (_) {
                          await FilePicker.platform.saveFile(
                            dialogTitle: 'Export Pass',
                            fileName: fileName,
                            bytes: bytes,
                          );
                        }
                      } else {
                        await FilePicker.platform.saveFile(
                          dialogTitle: 'Export Pass',
                          fileName: fileName,
                          bytes: bytes,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.file_download_rounded),
                  label: const Text('Export as .pkpass'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: textColor.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
              Icon(Icons.security_rounded, color: Colors.green.shade400, size: 32),
              const SizedBox(height: 16),
              Text(
                'Password-Encrypted Transfer',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasChunks && multiChunk
                    ? 'Your data is split across ${_encryptedChunks!.length} QR codes. The receiver must scan all of them and enter the password to decrypt.'
                    : 'This QR code contains your data encrypted with a password. The receiver must enter the same password to decrypt and import it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordPrompt(bool isDark, Color textColor) {
    return GestureDetector(
      onTap: _promptPassword,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: textColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Tap to Set Password',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'to generate QR code',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChunkNavigation(Color textColor) {
    final total = _encryptedChunks!.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _selectedChunkIndex > 0
                  ? () => setState(() => _selectedChunkIndex--)
                  : null,
              icon: Icon(Icons.chevron_left_rounded, color: textColor),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedChunkIndex + 1} / $total',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              onPressed: _selectedChunkIndex < total - 1
                  ? () => setState(() => _selectedChunkIndex++)
                  : null,
              icon: Icon(Icons.chevron_right_rounded, color: textColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Chunk dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final isActive = i == _selectedChunkIndex;
            final isScanned = i <= _selectedChunkIndex;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isScanned
                    ? Colors.green.withValues(alpha: isActive ? 1.0 : 0.5)
                    : textColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            final data = _encryptedChunks![_selectedChunkIndex];
            await Clipboard.setData(ClipboardData(text: data));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR data copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: Icon(Icons.copy_rounded, size: 16, color: textColor.withValues(alpha: 0.6)),
          label: Text(
            'Copy chunk data',
            style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12),
          ),
        ),
      ],
    );
  }
}
