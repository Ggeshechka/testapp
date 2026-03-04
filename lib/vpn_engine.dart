import 'dart:io';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;


class VpnEngine {
  static const MethodChannel _channel = MethodChannel('vpn_channel');

  static final ffi.DynamicLibrary _dylib = ffi.DynamicLibrary.open(
    switch (Platform.operatingSystem) {
      'windows' => 'libXray.dll',
      'macos' => 'libXray.dylib',
      'linux' => 'libXray.so',
      _ => throw UnsupportedError('Платформа не поддерживается')
    }
  );

  static Future<String> bridge(String android, String desktop, [String? value]) async {
    final String? base64Value = value != null ? base64Encode(utf8.encode(value)) : null;

    String base64Result = switch (Platform.operatingSystem) {
      'android' || 'ios' => await _channel.invokeMethod(
          android,
          base64Value != null ? {'base64Text': base64Value} : null,
        ),
      _ => () {
          if (base64Value == null) {
            final func = _dylib
                .lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function()>>(desktop)
                .asFunction<ffi.Pointer<Utf8> Function()>();
            return func().toDartString();
          } else {
            final func = _dylib
                .lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>)>>(desktop)
                .asFunction<ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>)>();
            
            final argPtr = base64Value.toNativeUtf8();
            final result = func(argPtr).toDartString();
            calloc.free(argPtr);
            
            return result;
          }
        }()
    };
    return utf8.decode(base64Decode(base64Result));
  }

  static Future<String> getVersion() {
    return bridge('xrayVersion', 'CGoXrayVersion');
  }

  static Future<String> stopXray() {
    return bridge('stopXray', 'CGoStopXray');
  }

  static Future<String> downloadAndSaveConfig(String url) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/config.json');

    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'happ/'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> configs = jsonDecode(response.body);
      if (configs.isNotEmpty) {
        Map<String, dynamic> config = configs[0];

        // 1. Настраиваем TUN со сниффингом трафика
        config['inbounds'] = [
          {
            "tag": "tun-in",
            "port": 10808,
            "protocol": "tun",
            "settings": {
              "autoRoute": true,
              "strictRoute": true,
              "stack": "system"
            },
            "sniffing": {
              "enabled": true,
              "destOverride": ["http", "tls", "fakedns"],
              "routeOnly": true
            }
          }
        ];

        // 2. Перехватываем DNS
        config['dns'] = {
          "servers": ["1.1.1.1", "8.8.8.8"]
        };

        // 3. Жестко направляем весь TCP/UDP трафик в прокси, удаляя старые правила
        config['routing'] = {
          "domainStrategy": "AsIs",
          "rules": [
            {
              "type": "field",
              "network": "tcp,udp",
              "outboundTag": "proxy"
            }
          ]
        };

        await file.writeAsString(jsonEncode(config));
        return file.path;
      } else {
        throw Exception("Пустой список серверов");
      }
    } else {
      throw Exception("Ошибка скачивания: ${response.statusCode}");
    }
  }

  static Future<String> buildMphCache(String datDir, String configPath) async {
    final requestData = {
      "datDir": datDir,
      "mphCachePath": "$datDir/mph.cache",
      "configPath": configPath,
    };
    return bridge('buildMphCache', 'CGoBuildMphCache', jsonEncode(requestData));
  }

  static Future<String> runXray(String datDir, String configPath) async {
    final requestData = {
      "datDir": datDir,
      "mphCachePath": "",
      "configPath": configPath,
    };
    return bridge('runXray', 'CGoRunXray', jsonEncode(requestData));
  }
}