import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/identity_card.dart';
import 'package:wallet/models/theme_provider.dart';
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

  bool _isPathValid(String? path) => path != null && path.isNotEmpty;

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentCard.name,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
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
                final result = await Navigator.push(
                  context,
                  SmoothPageRoute(
                    page: Scaffold(
                      appBar: AppBar(title: const Text('Edit Identity Card')),
                      body: IdentityCardEntryForm(existingCard: currentCard),
                    ),
                  ),
                );

                if (result == true && mounted) {
                  // Since IdentityCardEntryForm doesn't return the object but updates DB/Provider, 
                  // we might need to refresh or pop with true.
                  // For simplicity, let's pop back to homescreen which refreshes.
                  Navigator.pop(context, true);
                }
              },
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
              Clipboard.setData(ClipboardData(text: currentCard.value));
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
