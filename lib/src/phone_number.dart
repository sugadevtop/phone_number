import 'dart:async';

import 'package:flutter/services.dart';

class PhoneNumber {
  static const _channel = MethodChannel('com.julienvignali/phone_number');

  Future<String> format(String string, String region) {
    assert(string != null);
    assert(region != null);

    final args = {'string': string, 'region': region};
    return _channel.invokeMethod<String>('format', args);
  }

  Future<Map<String, dynamic>> parse(
    String string, {
    String region,
    bool ignoreType = false,
  }) {
    assert(string != null);

    return _channel.invokeMapMethod<String, dynamic>('parse', {
      'string': string,
      'region': region,
      'ignoreType': ignoreType,
    });
  }

  Future<Map<String, int>> allSupportedRegions() {
    return _channel.invokeMapMethod<String, int>('getRegions');
  }
}
