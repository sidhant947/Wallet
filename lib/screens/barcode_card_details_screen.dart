import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/dataentry.dart';
import 'package:wallet/screens/homescreen.dart';
import 'package:wallet/widgets/display_barcode_screen.dart';
import 'share_secure_screen.dart';

class BarcodeCardDetailScreen extends StatefulWidget {
  final Pass pass;

  const BarcodeCardDetailScreen({super.key, required this.pass});

  @override
  State<BarcodeCardDetailScreen> createState() => _BarcodeCardDetailScreenState();
}

class _BarcodeCardDetailScreenState extends State<BarcodeCardDetailScreen> {
  @override
  void initState() {
    super.initState();
    _maximizeBrightness();
  }

  Future<void> _maximizeBrightness() async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
    } catch (e) {
      debugPrint('Error setting brightness: $e');
    }
  }

  Future<void> _restoreBrightness() async {
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('Error resetting brightness: $e');
    }
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
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
      case 'storeCard':
        if (fieldType == 'primary') return "Pass Details";
        return "Account Details";
      case 'coupon':
        if (fieldType == 'primary') return "Offer Details";
        return "Coupon Info";
      default:
        if (fieldType == 'primary') return "Card Details";
        return "Information";
    }
  }

  Barcode _getBarcodeType(String? format) {
    switch (format?.toUpperCase()) {
      case 'PKBarcodeFormatQR': return Barcode.qrCode();
      case 'PKBarcodeFormatPDF417': return Barcode.pdf417();
      case 'PKBarcodeFormatAztec': return Barcode.aztec();
      case 'PKBarcodeFormatCode128': return Barcode.code128();
      default: return Barcode.qrCode();
    }
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
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Edit Pass')),
          body: BarcodeCardEntryForm(existingPass: widget.pass),
        ),
      ),
    );
    if (result == true && context.mounted) Navigator.pop(context, true);
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
