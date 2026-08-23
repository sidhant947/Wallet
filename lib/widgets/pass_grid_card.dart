import 'package:flutter/material.dart';
import 'package:wallet/models/pass.dart';
import 'package:wallet/widgets/encrypted_image_display.dart';

enum PassDisplayMode { card, front, back }

class PassGridCard extends StatelessWidget {
  final Pass pass;
  final VoidCallback onCardTap;
  final VoidCallback onCardLongPress;
  final PassDisplayMode displayMode;

  const PassGridCard({
    super.key,
    required this.pass,
    required this.onCardTap,
    required this.onCardLongPress,
    this.displayMode = PassDisplayMode.front,
  });

  Color? _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onCardTap,
      onLongPress: onCardLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ISO/IEC 7810 ID-1 standard card ratio (1.586 : 1)
          AspectRatio(
            aspectRatio: 1.586,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildCardContent(context, isDark),
            ),
          ),
          const SizedBox(height: 6),
          // Organization / Title label
          Text(
            pass.organizationName.isNotEmpty
                ? pass.organizationName
                : (pass.logoText ?? 'Pass'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          // Description sub-label
          if (pass.description != null && pass.description!.isNotEmpty)
            Text(
              pass.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, bool isDark) {
    // Mode 1: Front Image (with fallback to digital card)
    if (displayMode == PassDisplayMode.front &&
        pass.frontImagePath != null &&
        pass.frontImagePath!.isNotEmpty) {
      return EncryptedImageDisplay(
        imagePath: pass.frontImagePath!,
        fit: BoxFit.cover,
      );
    }

    // Mode 2: Back Image (with fallback to digital card)
    if (displayMode == PassDisplayMode.back &&
        pass.backImagePath != null &&
        pass.backImagePath!.isNotEmpty) {
      return EncryptedImageDisplay(
        imagePath: pass.backImagePath!,
        fit: BoxFit.cover,
      );
    }

    // Mode 3: Styled Digital "Fake Card" View
    final customBgColor = _parseColor(pass.backgroundColor);
    final customFgColor =
        _parseColor(pass.foregroundColor) ??
        (isDark ? Colors.white : Colors.black87);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            customBgColor ??
            (isDark ? const Color(0xFF242424) : Colors.grey.shade100),
        gradient: customBgColor == null
            ? LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
                    : [Colors.grey.shade100, Colors.grey.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pass.organizationName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: customFgColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Icon(
                Icons.qr_code_2_rounded,
                size: 16,
                color: customFgColor.withValues(alpha: 0.7),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pass.logoText != null && pass.logoText!.isNotEmpty)
                Text(
                  pass.logoText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: customFgColor,
                  ),
                ),
              Text(
                pass.type.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: customFgColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
