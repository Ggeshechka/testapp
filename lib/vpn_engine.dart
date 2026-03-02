import 'dart:io';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

// Сигнатуры C-функции для FFI
typedef XrayVersionC = ffi.Pointer<Utf8> Function();
typedef XrayVersionDart = ffi.Pointer<Utf8> Function();

class VpnEngine {
  // Канал для связи с мобильными ОС
  static const MethodChannel _channel = MethodChannel('vpn_channel');

  static Future<String> getVersion() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Для мобильных вызываем нативный код [3]
      return await _channel.invokeMethod('getXrayVersion');
    } else {
      // Для десктопов вызываем напрямую через FFI
      return _getVersionFfi();
    }
  }

  static String _getVersionFfi() {
    ffi.DynamicLibrary dylib;
    
    if (Platform.isWindows) {
      dylib = ffi.DynamicLibrary.open('libXray.dll');
    } else if (Platform.isMacOS) {
      dylib = ffi.DynamicLibrary.open('libXray.dylib');
    } else if (Platform.isLinux) {
      dylib = ffi.DynamicLibrary.open('libXray.so');
    } else {
      throw UnsupportedError('Платформа не поддерживается');
    } // 

    final getVersion = dylib
       .lookup<ffi.NativeFunction<XrayVersionC>>('CGoXrayVersion')
       .asFunction<XrayVersionDart>();

    final ffi.Pointer<Utf8> resultPtr = getVersion();
    final String base64Result = resultPtr.toDartString();
    
    // Декодируем Base64 ответ от ядра 
    return utf8.decode(base64Decode(base64Result));
  }
}