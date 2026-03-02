package com.example.testapp

import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import libXray.LibXray

class MainActivity: FlutterActivity() {
    private val CHANNEL = "vpn_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getXrayVersion") {
                try {
                    // Вызываем функцию из AAR архива
                    val base64Version = LibXray.xrayVersion()
                    // Декодируем Base64
                    val decodedBytes = Base64.decode(base64Version, Base64.DEFAULT)
                    val versionStr = String(decodedBytes, Charsets.UTF_8)
                    
                    result.success(versionStr)
                } catch (e: Exception) {
                    result.error("XRAY_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}