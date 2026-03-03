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
            try {
                when (call.method) {
                    "xrayVersion" -> {
                        result.success(LibXray.xrayVersion())
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("XRAY_ERROR", e.message, null)
            }
        }
    }
}