import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet/services/clipboard_service.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallet/models/identity_card.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/services/encryption_service.dart';
import 'package:wallet/widgets/identity_card_widget.dart';
import 'package:wallet/widgets/encrypted_image_display.dart';
import 'package:wallet/widgets/full_screen_image_viewer.dart';
import 'package:wallet/screens/homescreen.dart';
import 'package:wallet/widgets/identity_card_entry_form.dart';
import 'package:wallet/screens/share_secure_screen.dart';

class IdentityCardDetailScreen extends StatefulWidget {
  final IdentityCard card;

  const IdentityCardDetailScreen({super.key, required this.card});

  @override
  State<IdentityCardDetailScreen> createState() => _IdentityCardDetailScreenState();
}

class _IdentityCardDetailScreenState extends State<IdentityCardDetailScreen> {
  late IdentityCard currentCard;

  @override
  void initState() {
    super.initState();
    currentCard = widget.card;
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
            'Delete Identity Card?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${currentCard.name}"? This action cannot be undone.',
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
                await context.read<IdentityProvider>().deleteIdentity(currentCard.id!);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Identity Card Deleted!')),
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

  bool _isPathValid(String? path) => path != null && path.isNotEmpty;

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
      final tempFile = File('${tempDir.path}/id_doc_${DateTime.now().millisecondsSinceEpoch}.pdf');
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
    final isDark = themeProvider.isDarkMode;

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
                  SmoothPageRoute(page: ShareSecureScreen(identity: currentCard)),
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
                final navigator = Navigator.of(context);
                final result = await Navigator.push(
                  context,
                  SmoothPageRoute(
                    page: IdentityEditScreen(card: currentCard),
                  ),
                );

                if (result == true && mounted) {
                  navigator.pop(true);
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
              tooltip: 'Delete Identity Card',
              onPressed: _showDeleteConfirmationDialog,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          IdentityCardWidget(
            card: currentCard,
            onTap: () {
              ClipboardService.instance.copy(currentCard.value);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID Number Copied!')),
              );
            },
          ),
          const SizedBox(height: 24),
          
          if (_isPathValid(currentCard.frontImagePath) || _isPathValid(currentCard.backImagePath))
            _LiquidGlassDetailSection(
              title: "Identity Images",
              icon: Icons.photo_library_outlined,
              isDark: isDark,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_isPathValid(currentCard.frontImagePath))
                      _buildImageThumbnail(currentCard.frontImagePath!, 'Front', isDark),
                    if (_isPathValid(currentCard.backImagePath))
                      _buildImageThumbnail(currentCard.backImagePath!, 'Back', isDark),
                  ],
                ),
              ),
            ),

          if (_isPathValid(currentCard.pdfPath))
            _LiquidGlassDetailSection(
              title: "Attached Document",
              icon: Icons.picture_as_pdf_outlined,
              isDark: isDark,
              child: InkWell(
                onTap: () => _openPdf(currentCard.pdfPath!),
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
                              currentCard.pdfName ?? 'Identity Document.pdf',
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
            ),

          _LiquidGlassDetailSection(
            title: "Card Details",
            icon: Icons.badge_outlined,
            isDark: isDark,
            child: Column(
              children: [
                _buildDetailRow("Card Type", currentCard.cardType, isDark),
                _buildDetailRow("Name", currentCard.name, isDark),
                _buildDetailRow("ID Number", currentCard.value, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidGlassDetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;

  const _LiquidGlassDetailSection({
    required this.title,
    required this.icon,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
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
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class IdentityEditScreen extends StatefulWidget {
  final IdentityCard card;
  const IdentityEditScreen({super.key, required this.card});
  @override
  State<IdentityEditScreen> createState() => IdentityEditScreenState();
}

class IdentityEditScreenState extends State<IdentityEditScreen> {
  final _formKey = GlobalKey<IdentityCardEntryFormState>();
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            child: FilledButton(
              onPressed: () => _formKey.currentState?.save(),
              style: FilledButton.styleFrom(
                backgroundColor: _isDark ? Colors.white : Colors.black,
                foregroundColor: _isDark ? Colors.black : Colors.white,
              ),
              child: const Text("SAVE"),
            ),
          ),
        ],
      ),
      body: IdentityCardEntryForm(
        key: _formKey,
        existingCard: widget.card,
      ),
    );
  }
}
