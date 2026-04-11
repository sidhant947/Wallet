import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wallet/services/encryption_service.dart';

/// A widget that displays an encrypted image file.
///
/// Automatically decrypts the image when loading and cleans up
/// temporary decrypted files after use.
class EncryptedImageDisplay extends StatefulWidget {
  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final int? cacheHeight;
  final int? cacheWidth;
  final Widget? placeholder;
  final Widget? errorWidget;

  const EncryptedImageDisplay({
    super.key,
    required this.imagePath,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.cacheHeight,
    this.cacheWidth,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<EncryptedImageDisplay> createState() => _EncryptedImageDisplayState();
}

class _EncryptedImageDisplayState extends State<EncryptedImageDisplay> {
  String? _decryptedImagePath;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _decryptImage();
  }

  @override
  void didUpdateWidget(EncryptedImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _clearTempFile();
      _decryptedImagePath = null;
      _isLoading = true;
      _hasError = false;
      _decryptImage();
    }
  }

  @override
  void dispose() {
    _clearTempFile();
    super.dispose();
  }

  Future<void> _decryptImage() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final decryptedPath = await EncryptionService.instance.decryptImageFile(
        widget.imagePath,
      );

      if (mounted) {
        setState(() {
          _decryptedImagePath = decryptedPath;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('EncryptedImageDisplay: Decryption failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearTempFile() async {
    if (_decryptedImagePath != null && _decryptedImagePath!.isNotEmpty) {
      try {
        final tempFile = File(_decryptedImagePath!);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('EncryptedImageDisplay: Failed to cleanup temp file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            height: widget.height,
            width: widget.width,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    if (_hasError || _decryptedImagePath == null) {
      return widget.errorWidget ??
          Container(
            height: widget.height,
            width: widget.width,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
    }

    return Image.file(
      File(_decryptedImagePath!),
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      cacheHeight: widget.cacheHeight,
      cacheWidth: widget.cacheWidth,
      errorBuilder: (c, e, s) {
        debugPrint('EncryptedImageDisplay: Image load error: $e');
        return widget.errorWidget ??
            Container(
              height: widget.height,
              width: widget.width,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
      },
    );
  }
}
