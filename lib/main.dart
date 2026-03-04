import 'package:flutter/material.dart';
import 'vpn_engine.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  final version = await VpnEngine.getVersion();

  await startVpn();

  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Xray Version: $version')
          ],
        ),
      ),
    ),
  ));
}

Future<void> startVpn() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final datDir = dir.path;

    // 1. Копируем geo-файлы, если их нет
    for (String fileName in ['geoip.dat', 'geosite.dat']) {
      final targetFile = File('$datDir/$fileName');
      if (!await targetFile.exists()) {
        final byteData = await rootBundle.load('assets/$fileName');
        await targetFile.writeAsBytes(byteData.buffer.asUint8List(
            byteData.offsetInBytes, byteData.lengthInBytes));
      }
    }

    // 2. Скачиваем и сохраняем конфиг
    final configPath = await VpnEngine.downloadAndSaveConfig('https://sub.safelane.pro/7L3B97txDSKT4zP1');
    
    // 4. Запускаем Xray
    final result = await VpnEngine.runXray(datDir, configPath);
    print("Результат запуска: $result");

  } catch (e) {
    print("Ошибка: $e");
  }
}