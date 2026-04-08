import 'package:flutter/material.dart';

/// A dialog that shows NFC scanning progress and status
class NfcScanDialog extends StatelessWidget {
  final String statusMessage;
  final bool isScanning;
  final VoidCallback? onCancel;
  final IconData icon;
  final String title;

  const NfcScanDialog({
    super.key,
    required this.statusMessage,
    this.isScanning = true,
    this.onCancel,
    this.icon = Icons.wifi,
    this.title = 'Scanning NFC Card',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NFC Icon with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isScanning)
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  Icon(
                    icon,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Status message
            Text(
              statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Cancel button
            if (onCancel != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A button widget that triggers NFC scanning
class NfcScanButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isEnabled;
  final String? label;
  final IconData icon;

  const NfcScanButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
    this.label,
    this.icon = Icons.wifi,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label ?? 'Scan with NFC'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
