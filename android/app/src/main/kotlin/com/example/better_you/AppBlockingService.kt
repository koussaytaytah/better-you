package com.example.better_you

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

class AppBlockingService : AccessibilityService() {
    private val TAG = "AppBlockingService"
    private var lastPackageName: String? = null

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            if (packageName == lastPackageName) return
            lastPackageName = packageName

            Log.d(TAG, "Package changed to: $packageName")

            if (packageName == "com.example.better_you") return

            // Check if this package is limited
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val limitsJson = prefs.getString("flutter.app_limits", "{}")
            
            try {
                // Parse the JSON string from SharedPreferences directly
                val limits = JSONObject(limitsJson ?: "{}")
                
                if (limits.has(packageName)) {
                    val limitData = limits.getJSONObject(packageName)
                    val limitMins = limitData.optInt("limit", 0)
                    val quest = limitData.optString("quest", "Complete your quest")
                    
                    // We rely on the BackgroundService to track time and set a flag
                    // Or we can check the usage here if we want to be more aggressive
                    // For now, let's check a "is_locked" flag set by the background service
                    val lockedAppsJson = prefs.getString("flutter.locked_apps_status", "{}")
                    val lockedApps = JSONObject(lockedAppsJson ?: "{}")
                    
                    if (lockedApps.optBoolean(packageName, false)) {
                        Log.d(TAG, "Blocking app: $packageName")
                        blockApp(packageName, quest)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking limits", e)
            }
        }
    }

    private fun blockApp(packageName: String, quest: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("locked_app", packageName)
            putExtra("quest", quest)
        }
        startActivity(intent)
    }

    override fun onInterrupt() {}

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Service connected")
    }
}