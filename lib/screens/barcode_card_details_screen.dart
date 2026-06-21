import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/widgets/barcode_card_entry_form.dart';
import 'package:wallet/screens/homescreen.dart';
import 'package:wallet/services/barcode_utils.dart';
import 'package:wallet/widgets/display_barcode_screen.dart';
import 'package:wallet/widgets/encrypted_image_display.dart';
import 'package:wallet/widgets/full_screen_image_viewer.dart';
import 'package:wallet/widgets/barcode_card.dart';
import 'share_secure_screen.dart';

class BarcodeCardDetailScreen extends StatefulWidget {
  final Pass pass;

  const BarcodeCardDetailScreen({super.key, required this.pass});

  @override
  State<BarcodeCardDetailScreen> createState() => _BarcodeCardDetailScreenState();
}

class _BarcodeCardDetailScreenState extends State<BarcodeCardDetailScreen> {
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
    final p = widget.pass;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.organizationName),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: Icon(Icons.share_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
              tooltip: 'Share Pass (Encrypted Data)',
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  SmoothPageRoute(page: ShareSecureScreen(pass: widget.pass)),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: Icon(Icons.edit, color: isDark ? Colors.white : Colors.black, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                _navigateToEditScreen(context);
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          BarcodeCard(
            pass: p,
            onCardTap: () {
              if (p.barcodeValue.isNotEmpty) {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    page: DisplayBarcodeScreen(
                      barcodeData: p.barcodeValue,
                      barcodeFormat: p.barcodeFormat,
                      cardName: p.organizationName,
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Barcode Section
          if (p.barcodeValue.isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    page: DisplayBarcodeScreen(
                      barcodeData: p.barcodeValue,
                      barcodeFormat: p.barcodeFormat,
                      cardName: p.organizationName,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: _getBarcodeType(p.barcodeFormat),
                      data: p.barcodeValue,
                      color: Colors.black,
                      height: 180,
                      width: double.infinity,
                      errorBuilder: (context, error) => const Center(
                        child: Text('Invalid Barcode Data', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                    if (p.barcodeAltText != null || p.barcodeValue.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        p.barcodeAltText ?? p.barcodeValue,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 18,
                          letterSpacing: 4,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],

          if (_isPathValid(p.frontImagePath) ||
              _isPathValid(p.backImagePath) ||
              _isPathValid(p.stripImagePath) ||
              _isPathValid(p.thumbnailImagePath))
            _LiquidGlassSection(
              title: "Pass Images",
              icon: Icons.photo_library_outlined,
              isDark: isDark,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isPathValid(p.frontImagePath))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildImageThumbnail(p.frontImagePath!, 'Front', isDark),
                      ),
                    if (_isPathValid(p.backImagePath))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildImageThumbnail(p.backImagePath!, 'Back', isDark),
                      ),
                    if (_isPathValid(p.stripImagePath))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildImageThumbnail(p.stripImagePath!, 'Strip', isDark),
                      ),
                    if (_isPathValid(p.thumbnailImagePath))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildImageThumbnail(p.thumbnailImagePath!, 'Thumbnail', isDark),
                      ),
                  ],
                ),
              ),
            ),

          if (p.description != null && p.description!.isNotEmpty)
            _buildInfoSection("Description", p.description!, isDark),

          const SizedBox(height: 24),

          // Fields Sections - Structured by Pass Type
          if (p.fields != null) ...[
            if (p.fields!['primaryFields'] != null) 
              _buildFieldsSection(_getSectionTitle(p.type, 'primary'), p.fields!['primaryFields'], isDark, Icons.star_outline_rounded),
            if (p.fields!['secondaryFields'] != null) 
              _buildFieldsSection(_getSectionTitle(p.type, 'secondary'), p.fields!['secondaryFields'], isDark, Icons.info_outline_rounded),
            if (p.fields!['auxiliaryFields'] != null) 
              _buildFieldsSection(_getSectionTitle(p.type, 'auxiliary'), p.fields!['auxiliaryFields'], isDark, Icons.grid_view_rounded),
            if (p.fields!['headerFields'] != null) 
              _buildFieldsSection("Header Details", p.fields!['headerFields'], isDark, Icons.list_alt_rounded),
            if (p.fields!['backFields'] != null) 
              _buildFieldsSection("Additional Info", p.fields!['backFields'], isDark, Icons.more_horiz_rounded),
          ],

          const SizedBox(height: 32),

          // No Images Section here (removed as per instructions)
        ],
      ),
    );
  }

  String _getSectionTitle(String passType, String fieldType) {
    switch (passType) {
      case 'boardingPass':
        if (fieldType == 'primary') return "Flight Details";
        if (fieldType == 'secondary') return "Passenger Info";
        return "Travel Info";
      case 'eventTicket':
        if (fieldType == 'primary') return "Event Details";
        if (fieldType == 'secondary') return "Venue Info";
        return "Ticket Details";
      case 'loyaltyCard':
      case 'storeCard':
        if (fieldType == 'primary') return "Member Info";
        if (fieldType == 'secondary') return "Account Details";
        return "Rewards Info";
      case 'giftCard':
        if (fieldType == 'primary') return "Card Info";
        if (fieldType == 'secondary') return "Balance & PIN";
        return "Gift Details";
      case 'offer':
        if (fieldType == 'primary') return "Offer Details";
        if (fieldType == 'secondary') return "Provider Info";
        return "Terms";
      case 'coupon':
        if (fieldType == 'primary') return "Offer Details";
        return "Coupon Info";
      case 'transitPass':
        if (fieldType == 'primary') return "Route Details";
        if (fieldType == 'secondary') return "Trip Info";
        return "Fare Details";
      case 'digitalCarKey':
        if (fieldType == 'primary') return "Vehicle Info";
        if (fieldType == 'secondary') return "Key Details";
        return "Access Info";
      case 'campusId':
        if (fieldType == 'primary') return "Student Info";
        if (fieldType == 'secondary') return "University Details";
        return "Access Info";
      case 'corporateBadge':
        if (fieldType == 'primary') return "Employee Info";
        if (fieldType == 'secondary') return "Company Details";
        return "Access Info";
      case 'hotelKey':
        if (fieldType == 'primary') return "Guest Info";
        if (fieldType == 'secondary') return "Hotel Details";
        return "Stay Details";
      case 'multiFamilyKey':
        if (fieldType == 'primary') return "Resident Info";
        if (fieldType == 'secondary') return "Property Details";
        return "Access Info";
      case 'healthInsuranceCard':
        if (fieldType == 'primary') return "Member Info";
        if (fieldType == 'secondary') return "Policy Details";
        return "Coverage Info";
      case 'healthTestRecord':
        if (fieldType == 'primary') return "Test Info";
        if (fieldType == 'secondary') return "Results";
        return "Lab Details";
      case 'healthVaccineCard':
        if (fieldType == 'primary') return "Vaccine Info";
        if (fieldType == 'secondary') return "Dose Details";
        return "Manufacturer Info";
      case 'digitalCredential':
        if (fieldType == 'primary') return "Document Info";
        if (fieldType == 'secondary') return "Issuer Details";
        return "Verification";
      case 'genericPrivate':
        if (fieldType == 'primary') return "Organization";
        if (fieldType == 'secondary') return "Data Details";
        return "Additional Info";
      case 'inStorePayment':
        if (fieldType == 'primary') return "Card Info";
        if (fieldType == 'secondary') return "Account Details";
        return "Payment Info";
      default:
        if (fieldType == 'primary') return "Card Details";
        return "Information";
    }
  }

  Barcode _getBarcodeType(String? format) {
    return BarcodeUtils.getBarcodeFromFormat(format);
  }

  Widget _buildInfoSection(String title, String content, bool isDark) {
    return _LiquidGlassSection(
      title: title,
      icon: Icons.description_outlined,
      isDark: isDark,
      child: Text(content, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.5)),
    );
  }

  Widget _buildFieldsSection(String title, dynamic fields, bool isDark, IconData icon) {
    if (fields is! List || fields.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: _LiquidGlassSection(
        title: title,
        icon: icon,
        isDark: isDark,
        child: Column(
          children: fields.map((f) => _buildDetailRow(f['label'] ?? '', f['value']?.toString() ?? '', isDark)).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassEditScreen(pass: widget.pass),
      ),
    );
    if (result == true && context.mounted) Navigator.pop(context, true);
  }
}

class PassEditScreen extends StatefulWidget {
  final Pass pass;
  const PassEditScreen({super.key, required this.pass});
  @override
  State<PassEditScreen> createState() => PassEditScreenState();
}

class PassEditScreenState extends State<PassEditScreen> {
  final _formKey = GlobalKey<BarcodeCardEntryFormState>();
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
      body: BarcodeCardEntryForm(
        key: _formKey,
        existingPass: widget.pass,
      ),
    );
  }
}

class _LiquidGlassSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;
  const _LiquidGlassSection({required this.title, required this.icon, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(children: [Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38), const SizedBox(width: 8), Text(title.toUpperCase(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 11))]),
        ),
        Container(padding: const EdgeInsets.all(16), width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5)), child: child),
      ],
    );
  }
}
