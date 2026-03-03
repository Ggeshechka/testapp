import 'dart:io';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

typedef XrayVersionC = ffi.Pointer<Utf8> Function();
typedef XrayVersionDart = ffi.Pointer<Utf8> Function();

class VpnEngine {
  static const MethodChannel _channel = MethodChannel('vpn_channel');

  static Future<String> bridge(String android, String desktop) async {
    String base64Result = switch (Platform.operatingSystem) {
      'android' || 'ios' => await _channel.invokeMethod(android),
      _ => () {
        ffi.DynamicLibrary dylib = ffi.DynamicLibrary.open(
          switch(Platform.operatingSystem) {
            'windows' => 'libXray.dll',
            'macos' => 'libXray.dylib',
            'linux' => 'libXray.so',
            _ => throw UnsupportedError('Платформа не поддерживается')
          }
        );

        final getVersion = dylib
          .lookup<ffi.NativeFunction<XrayVersionC>>(desktop)
          .asFunction<XrayVersionDart>();

        final ffi.Pointer<Utf8> resultPtr = getVersion();
        return resultPtr.toDartString();
      }()
    };
    return utf8.decode(base64Decode(base64Result));
  }

  static Future<String> getVersion() {
    return bridge('xrayVersion', 'CGoXrayVersion');
  }
}