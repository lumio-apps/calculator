import 'package:flutter/services.dart';

/// Opens the Android share sheet with [text]. Implemented in MainActivity.kt.
Future<void> shareText(String text) async {
  const channel = MethodChannel('lumio/share');
  try {
    await channel.invokeMethod<void>('shareText', {'text': text});
  } on PlatformException {
    // Sharing is not available; ignore.
  } on MissingPluginException {
    // Not running on Android; ignore.
  }
}
