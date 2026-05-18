package com.example.new_launcher

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import android.content.Context

class MainActivity: FlutterActivity() {
    private val CHANNEL = "accessibility_service"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> {
                    val isEnabled = isAccessibilityServiceEnabled()
                    result.success(isEnabled)
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                "performGlobalAction" -> {
                    val action = call.argument<Int>("action") ?: 0
                    val success = performGlobalAction(action)
                    result.success(success)
                }
                "performClick" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    val success = performClick(x, y)
                    result.success(success)
                }
                "performSwipe" -> {
                    val startX = call.argument<Double>("startX")?.toFloat() ?: 0f
                    val startY = call.argument<Double>("startY")?.toFloat() ?: 0f
                    val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                    val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                    val duration = call.argument<Int>("duration")?.toLong() ?: 300L
                    val success = performSwipe(startX, startY, endX, endY, duration)
                    result.success(success)
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val success = launchApp(packageName)
                    result.success(success)
                }
                "openSettings" -> {
                    val action = call.argument<String>("action") ?: ""
                    val success = openSettings(action)
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun isAccessibilityServiceEnabled(): Boolean {
        val accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        
        return enabledServices.contains("com.example.new_launcher/.LauncherAccessibilityService")
    }
    
    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }
    
    private fun performGlobalAction(action: Int): Boolean {
        val service = LauncherAccessibilityService.getInstance()
        return service?.performGlobalAction(action) ?: false
    }
    
    private fun performClick(x: Float, y: Float): Boolean {
        val service = LauncherAccessibilityService.getInstance()
        return service?.performClick(x, y) ?: false
    }
    
    private fun performSwipe(startX: Float, startY: Float, endX: Float, endY: Float, duration: Long): Boolean {
        val service = LauncherAccessibilityService.getInstance()
        return service?.performSwipe(startX, startY, endX, endY, duration) ?: false
    }
    
    private fun launchApp(packageName: String): Boolean {
        val service = LauncherAccessibilityService.getInstance()
        return service?.openApp(packageName) ?: false
    }
    
    private fun openSettings(action: String): Boolean {
        try {
            val intent = Intent(action)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return true
        } catch (e: Exception) {
            return false
        }
    }
}