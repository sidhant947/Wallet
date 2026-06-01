import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/encryption_service.dart';

class ShareSecureScreen extends StatelessWidget {
  final Pass? pass;
  final Wallet? wallet;

  const ShareSecureScreen({super.key, this.pass, this.wallet})
      : assert(pass != null || wallet != null);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    // 1. Prepare data
    Map<String, dynamic> dataMap;
    String shareType;
    String displayName;

    if (pass != null) {
      dataMap = pass!.toMap();
      shareType = 'pass';
      displayName = pass!.organizationName;
    } else {
      dataMap = wallet!.toMap();
      shareType = 'wallet';
      displayName = wallet!.name;
    }

    // Remove local image paths and IDs
    dataMap.remove('frontImagePath');
    dataMap.remove('backImagePath');
    dataMap.remove('stripImagePath');
    dataMap.remove('thumbnailImagePath');
    dataMap.remove('id');

    // Add type metadata for the receiver
    final payload = {
      'type': shareType,
      'data': dataMap,
    };

    final jsonStr = jsonEncode(payload);
    
    // 2. Encrypt for transfer
    final encryptedData = EncryptionService.instance.encryptForTransfer(jsonStr);

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
                    if (encryptedData != null)
                      BarcodeWidget(
                        barcode: Barcode.qrCode(),
                        data: encryptedData,
                        width: 250,
                        height: 250,
                        color: Colors.black,
                      )
                    else
                      const Text('Failed to generate sharing code.', style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 24),
                    const Text(
                      'SCAN TO IMPORT',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Icon(Icons.security_rounded, color: Colors.green.shade400, size: 32),
              const SizedBox(height: 16),
              Text(
                'End-to-End Encrypted Transfer',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This QR code contains your data in a secure, encrypted format. Only another device running this app can decrypt and import it.',
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
}
