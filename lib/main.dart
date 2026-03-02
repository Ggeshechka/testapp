import 'package:flutter/material.dart';
import 'vpn_engine.dart';

Future<void> main() async {
  // Обязательно для вызова MethodChannel до отрисовки UI
  WidgetsFlutterBinding.ensureInitialized(); 

  final version = await VpnEngine.getVersion();

  runApp(MaterialApp(
    home: Scaffold( // Scaffold нужен, чтобы текст не налез на шторку уведомлений
      body: Center(
        child: Text(version),
      ),
    ),
  ));
}