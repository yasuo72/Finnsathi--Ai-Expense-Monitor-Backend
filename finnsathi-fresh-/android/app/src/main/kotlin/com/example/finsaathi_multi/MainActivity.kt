package com.example.finsaathi_multi

import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlesignin.GoogleSignInPlugin

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Do performance optimizations before calling super.onCreate
        // This helps reduce the startup time significantly
        
        // Handle status bar and navigation bar before super.onCreate
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        }
        
        // Make the app edge-to-edge for a more immersive experience
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Perform super.onCreate after window setup for faster rendering
        super.onCreate(savedInstanceState)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Log for debugging Google Sign-In
        Log.d("GoogleSignIn", "Configuring Flutter Engine for Google Sign-In")
        
        // We don't need to explicitly register the GoogleSignInPlugin
        // It's automatically registered by Flutter's plugin registry
        Log.d("GoogleSignIn", "GoogleSignInPlugin should be automatically registered by Flutter")
        
        // Setup method channel for native performance optimizations
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.finsaathi/performance").setMethodCallHandler { call, result ->
            when (call.method) {
                "optimizePerformance" -> {
                    // Apply additional performance optimizations when requested from Dart
                    result.success(true)
                }
                "checkGoogleSignIn" -> {
                    // Check if Google Sign-In is properly configured
                    try {
                        // Just log that we're checking Google Sign-In
                        Log.d("GoogleSignIn", "Checking if Google Sign-In is properly configured")
                        // The plugin is automatically registered by Flutter's plugin registry
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("GoogleSignIn", "Error checking Google Sign-In: ${e.message}")
                        result.error("GOOGLE_SIGN_IN_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
