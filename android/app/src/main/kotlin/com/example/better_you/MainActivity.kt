package com.example.better_you

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.better_you/lock"
    private var pendingLockData: Map<String, String>? = null
    private val TAG = "BetterYouNative"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Show activity over lockscreen and keep screen on
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "Configuring Flutter Engine")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLockData" -> {
                    val lockData = mutableMapOf<String, String>()
                    
                    // Check pending data first
                    pendingLockData?.let {
                        Log.d(TAG, "Returning pending lock data: $it")
                        lockData.putAll(it)
                        pendingLockData = null
                    } ?: run {
                        // Check current intent extras
                        val pkg = intent.getStringExtra("locked_app")
                        val quest = intent.getStringExtra("quest")
                        if (pkg != null) {
                            Log.d(TAG, "Returning intent lock data: $pkg")
                            lockData["locked_app"] = pkg
                            lockData["quest"] = quest ?: "Complete your quest"
                        } else {
                            // Try serializable as fallback
                            intent.getSerializableExtra("locked_app")?.let { 
                                Log.d(TAG, "Returning serializable lock data: $it")
                                lockData["locked_app"] = it.toString() 
                            }
                            intent.getSerializableExtra("quest")?.let { 
                                lockData["quest"] = it.toString() 
                            }
                        }
                    }
                    
                    // Clear extras to avoid re-triggering
                    intent.removeExtra("locked_app")
                    intent.removeExtra("quest")
                    
                    result.success(lockData)
                }
                "checkOverlayPermission" -> {
                    result.success(android.provider.Settings.canDrawOverlays(this))
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "${packageName}/${AppBlockingService::class.java.canonicalName}"
        val enabled = android.provider.Settings.Secure.getInt(
            contentResolver,
            android.provider.Settings.Secure.ACCESSIBILITY_ENABLED, 0
        )
        if (enabled == 1) {
            val settingValue = android.provider.Settings.Secure.getString(
                contentResolver,
                android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            return settingValue?.contains(service) == true
        }
        return false
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        Log.d(TAG, "Received new intent")
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val pkg = intent.getStringExtra("locked_app") ?: 
                  intent.getSerializableExtra("locked_app")?.toString()
        val quest = intent.getStringExtra("quest") ?: 
                    intent.getSerializableExtra("quest")?.toString()
        
        if (pkg != null) {
            Log.d(TAG, "Handling lock intent for: $pkg")
            val data = mapOf("locked_app" to pkg, "quest" to (quest ?: "Complete your quest"))
            pendingLockData = data
            
            // Notify Flutter if engine is already running
            flutterEngine?.let {
                Log.d(TAG, "Notifying Flutter directly via MethodChannel")
                MethodChannel(it.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onLockTriggered", data)
            }
        }
    }
}
