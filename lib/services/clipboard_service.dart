import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  static final ClipboardService _instance = ClipboardService._();
  static ClipboardService get instance => _instance;

  ClipboardService._();

  Timer? _clearTimer;
  String? _currentContent;

  static const Duration _defaultClearDuration = Duration(seconds: 15);

  String? get currentContent => _currentContent;

  Future<void> copy(String text, {Duration? clearAfter}) async {
    await Clipboard.setData(ClipboardData(text: text));
    _currentContent = text;

    _clearTimer?.cancel();
    _clearTimer = Timer(clearAfter ?? _defaultClearDuration, _clearClipboard);
  }

  Future<void> _clearClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == _currentContent) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (_) {}

    _currentContent = null;
    _clearTimer = null;
  }

  void cancelAutoClear() {
    _clearTimer?.cancel();
    _clearTimer = null;
    _currentContent = null;
  }
}
