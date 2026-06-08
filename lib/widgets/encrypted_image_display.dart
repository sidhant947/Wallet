import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:wallet/services/encryption_service.dart';

/// A widget that displays an encrypted image file.
///
/// Automatically decrypts the image directly into memory for security,
/// avoiding temporary plaintext files on disk.
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
  Uint8List? _imageBytes;
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
      _imageBytes = null;
      _isLoading = true;
      _hasError = false;
      _decryptImage();
    }
  }

  Future<void> _decryptImage() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final bytes = await EncryptionService.instance.decryptImageToBytes(
        widget.imagePath,
      );

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
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

    if (_hasError || _imageBytes == null) {
      return widget.errorWidget ??
          Container(
            height: widget.height,
            width: widget.width,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
    }

    return Image.memory(
      _imageBytes!,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      cacheHeight: widget.cacheHeight,
      cacheWidth: widget.cacheWidth,
      errorBuilder: (c, e, s) {
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
