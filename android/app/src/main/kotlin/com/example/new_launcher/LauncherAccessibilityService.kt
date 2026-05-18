package com.example.new_launcher

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.view.accessibility.AccessibilityEvent
import android.accessibilityservice.AccessibilityServiceInfo

class LauncherAccessibilityService : AccessibilityService() {
    
    companion object {
        const val TAG = "LauncherAccessibilityService"
        
        private var instance: LauncherAccessibilityService? = null
        
        fun getInstance(): LauncherAccessibilityService? = instance
        
        const val GLOBAL_ACTION_BACK = AccessibilityService.GLOBAL_ACTION_BACK
        const val GLOBAL_ACTION_HOME = AccessibilityService.GLOBAL_ACTION_HOME
        const val GLOBAL_ACTION_RECENTS = AccessibilityService.GLOBAL_ACTION_RECENTS
        const val GLOBAL_ACTION_NOTIFICATIONS = AccessibilityService.GLOBAL_ACTION_NOTIFICATIONS
        const val GLOBAL_ACTION_QUICK_SETTINGS = AccessibilityService.GLOBAL_ACTION_QUICK_SETTINGS
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        
        // Configure service info
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPES_ALL_MASK
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.notificationTimeout = 100
        info.flags = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS or
                     AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                     AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        
        setServiceInfo(info)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Handle accessibility events if needed
    }
    
    override fun onInterrupt() {
        // Handle interruption
    }
    
    // Perform global action (renamed to avoid conflict with parent method)
    fun executeGlobalAction(action: Int): Boolean {
        return performGlobalAction(action)
    }
    
    // Go back
    fun goBack(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_BACK)
    }
    
    // Go home
    fun goHome(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_HOME)
    }
    
    // Open recents
    fun openRecents(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_RECENTS)
    }
    
    // Open notifications
    fun openNotifications(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)
    }
    
    // Open quick settings
    fun openQuickSettings(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
    }
    
    // Perform click at coordinates
    fun performClick(x: Float, y: Float): Boolean {
        val path = Path()
        path.moveTo(x, y)
        
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
            .build()
        
        return dispatchGesture(gesture, null, null)
    }
    
    // Perform swipe
    fun performSwipe(startX: Float, startY: Float, endX: Float, endY: Float, duration: Long): Boolean {
        val path = Path()
        path.moveTo(startX, startY)
        path.lineTo(endX, endY)
        
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, duration))
            .build()
        
        return dispatchGesture(gesture, null, null)
    }
    
    // Open app by package name
    fun openApp(packageName: String): Boolean {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return true
        }
        return false
    }
    
    // Open settings page
    fun openSettings(settingsAction: String): Boolean {
        try {
            val intent = Intent(settingsAction)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return true
        } catch (e: Exception) {
            return false
        }
    }
}