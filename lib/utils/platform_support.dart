import 'dart:io';

/// Whether the current platform supports local notifications and background fetch.
bool get supportsNotifications => Platform.isAndroid || Platform.isIOS;
