package com.angelosonsy.fatorty

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// قناة بسيطة لفتح تطبيق تاني مثبّت على الجهاز (فوري، إنستاباي..) من
/// غير ما نضيف باكدج خارجي كامل لمجرد العملية البسيطة دي. لو التطبيق
/// مش متثبّت، بترجع false وDart بيتولى الانتقال لصفحة Google Play بدل
/// كده (شوف app_launcher.dart).
class MainActivity : FlutterActivity() {
    private val channelName = "com.angelosonsy.fatorty/app_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openApp" -> {
                        val packageName = call.argument<String>("package")
                        if (packageName.isNullOrEmpty()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        try {
                            val launchIntent =
                                packageManager.getLaunchIntentForPackage(packageName)
                            if (launchIntent != null) {
                                startActivity(launchIntent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
