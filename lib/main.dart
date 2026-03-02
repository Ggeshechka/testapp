import 'package:flutter/material.dart';
import 'vpn_engine.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VpnTestScreen(),
    );
  }
}

class VpnTestScreen extends StatefulWidget {
  const VpnTestScreen({super.key});

  @override
  State<VpnTestScreen> createState() => _VpnTestScreenState();
}

class _VpnTestScreenState extends State<VpnTestScreen> {
  // Переменная, которая хранит текст для отображения на экране
  String _coreVersion = 'Версия пока не получена';

  // Асинхронная функция, которая обращается к ядру
  Future<void> _fetchVersion() async {
    try {
      // Получаем версию (здесь под капотом отработает FFI для десктопа или MethodChannel для мобилок)
      final version = await VpnEngine.getVersion();
      
      // Обновляем UI с полученным результатом
      setState(() {
        _coreVersion = 'Версия ядра: \n$version';
      });
    } catch (e) {
      // Выводим ошибку на экран, если что-то пошло не так
      setState(() {
        _coreVersion = 'Произошла ошибка: \n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест libxray'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:,
          ),
        ),
      ),
    );
  }
}