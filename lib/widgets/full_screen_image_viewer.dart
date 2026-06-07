import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:wallet/services/encryption_service.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String? imagePath;
  final Uint8List? imageBytes;

  const FullScreenImageViewer({
    super.key,
    this.imagePath,
    this.imageBytes,
  }) : assert(imagePath != null || imageBytes != null);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  Uint8List? _bytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageBytes != null) {
      _bytes = widget.imageBytes;
    } else {
      _loadBytes();
    }
  }

  Future<void> _loadBytes() async {
    setState(() => _isLoading = true);
    final bytes = await EncryptionService.instance.decryptImageToBytes(widget.imagePath!);
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.102),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : _bytes == null
                ? const Icon(Icons.broken_image, color: Colors.white54, size: 64)
                : InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.memory(_bytes!, cacheWidth: 1000),
                  ),
      ),
    );
  }
}
