package com.example.testapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import libXray.LibXray

class MainActivity: FlutterActivity() {
    private val CHANNEL = "vpn_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "xrayVersion") {
                try {
                    // Просто получаем Base64 от ядра и отдаем во Flutter
                    val base64Version = LibXray.xrayVersion()
                    result.success(base64Version)
                } catch (e: Exception) {
                    result.error("XRAY_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}