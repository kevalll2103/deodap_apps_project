package com.example.calllogmonitor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import kotlinx.coroutines.*
import java.text.SimpleDateFormat
import java.util.*

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_WAREHOUSE_ID = "flutter.warehouse_id"
        private const val KEY_DEVICE_ID = "flutter.user_id"
        private const val KEY_MOBILE_NUMBER = "flutter.mobile_number"
        private const val KEY_AUTO_START_ENABLED = "flutter.auto_start_enabled"
        private const val KEY_LAST_BOOT_TIME = "flutter.last_boot_time"
        private const val KEY_BOOT_COUNT = "flutter.boot_count"
        private const val KEY_SERVICE_START_ATTEMPTS = "flutter.service_start_attempts"
        private const val MAX_START_ATTEMPTS = 3
        private const val RETRY_DELAY_MS = 5000L
    }

    override fun onReceive(context: Context, intent: Intent) {
        val currentTime = System.currentTimeMillis()
        val timeString = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date(currentTime))

        Log.i(TAG, "=== Boot Receiver Triggered ===")
        Log.i(TAG, "Action: ${intent.action}")
        Log.i(TAG, "Time: $timeString")
        Log.i(TAG, "Android Version: ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
        Log.i(TAG, "Device: ${Build.MANUFACTURER} ${Build.MODEL}")

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.i(TAG, "Device boot completed - full system startup")
                handleBootEvent(context, "BOOT_COMPLETED", currentTime)
            }
            Intent.ACTION_LOCKED_BOOT_COMPLETED -> {
                Log.i(TAG, "Device boot completed - locked mode (Android 7+)")
                handleBootEvent(context, "LOCKED_BOOT_COMPLETED", currentTime)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.i(TAG, "App package replaced/updated")
                handleBootEvent(context, "PACKAGE_REPLACED", currentTime)
            }
            Intent.ACTION_PACKAGE_REPLACED -> {
                val packageName = intent.dataString
                Log.i(TAG, "Package replaced: $packageName")
                if (packageName?.contains(context.packageName) == true) {
                    handleBootEvent(context, "PACKAGE_REPLACED", currentTime)
                }
            }
            Intent.ACTION_USER_UNLOCKED -> {
                Log.i(TAG, "User unlocked device")
                handleBootEvent(context, "USER_UNLOCKED", currentTime)
            }
            else -> {
                Log.w(TAG, "Unhandled action: ${intent.action}")
            }
        }
    }

    private fun handleBootEvent(context: Context, eventType: String, currentTime: Long) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            updateBootStatistics(prefs, eventType, currentTime)

            val autoStartEnabled = prefs.getBoolean(KEY_AUTO_START_ENABLED, true)
            if (!autoStartEnabled) {
                Log.i(TAG, "Auto-start is disabled, skipping service start")
                return
            }

            val configValidation = validateConfiguration(prefs)
            if (!configValidation.isValid) {
                Log.w(TAG, "Configuration validation failed: ${configValidation.reason}")
                logConfigurationStatus(prefs)
                return
            }

            Log.i(TAG, "Configuration validated successfully")
            startServiceWithRetry(context, prefs, eventType)

        } catch (e: Exception) {
            Log.e(TAG, "Error in handleBootEvent", e)
        }
    }

    private fun updateBootStatistics(prefs: SharedPreferences, eventType: String, currentTime: Long) {
        val bootCount = prefs.getInt(KEY_BOOT_COUNT, 0) + 1

        prefs.edit()
            .putLong(KEY_LAST_BOOT_TIME, currentTime)
            .putInt(KEY_BOOT_COUNT, bootCount)
            .putString("flutter.last_boot_event", eventType)
            .apply()

        Log.i(TAG, "Boot statistics updated - Count: $bootCount, Event: $eventType")
    }

    private fun validateConfiguration(prefs: SharedPreferences): ConfigValidation {
        val warehouseId = prefs.getString(KEY_WAREHOUSE_ID, "")
        val deviceId = prefs.getLong(KEY_DEVICE_ID, 0L)
        val mobileNumber = prefs.getString(KEY_MOBILE_NUMBER, "")

        return when {
            warehouseId.isNullOrEmpty() -> ConfigValidation(false, "Warehouse ID is missing")
            deviceId == 0L -> ConfigValidation(false, "Device ID is missing or invalid")
            mobileNumber.isNullOrEmpty() -> ConfigValidation(false, "Mobile number is missing")
            else -> ConfigValidation(true, "Configuration is valid")
        }
    }

    private fun logConfigurationStatus(prefs: SharedPreferences) {
        Log.i(TAG, "=== Configuration Status ===")
        Log.i(TAG, "Warehouse ID: ${if (prefs.getString(KEY_WAREHOUSE_ID, "").isNullOrEmpty()) "MISSING" else "PRESENT"}")
        Log.i(TAG, "Device ID: ${prefs.getLong(KEY_DEVICE_ID, 0L)}")
        Log.i(TAG, "Mobile Number: ${if (prefs.getString(KEY_MOBILE_NUMBER, "").isNullOrEmpty()) "MISSING" else "PRESENT"}")
        Log.i(TAG, "Auto Start: ${prefs.getBoolean(KEY_AUTO_START_ENABLED, true)}")
    }

    private fun startServiceWithRetry(context: Context, prefs: SharedPreferences, eventType: String) {
        prefs.edit().putInt(KEY_SERVICE_START_ATTEMPTS, 0).apply()

        CoroutineScope(Dispatchers.IO).launch {
            var attempts = 0
            var success = false

            while (attempts < MAX_START_ATTEMPTS && !success) {
                attempts++

                try {
                    Log.i(TAG, "Starting CallLogSyncService (attempt $attempts/$MAX_START_ATTEMPTS)")
                    prefs.edit().putInt(KEY_SERVICE_START_ATTEMPTS, attempts).apply()

                    CallLogSyncService.startService(context)

                    success = true
                    Log.i(TAG, "✅ CallLogSyncService started successfully on attempt $attempts")

                    prefs.edit()
                        .putLong("flutter.last_service_start_time", System.currentTimeMillis())
                        .putString("flutter.last_service_start_event", eventType)
                        .putBoolean("flutter.last_service_start_success", true)
                        .apply()

                } catch (e: Exception) {
                    Log.e(TAG, "❌ Failed to start service on attempt $attempts", e)

                    if (attempts < MAX_START_ATTEMPTS) {
                        Log.i(TAG, "Retrying in ${RETRY_DELAY_MS / 1000} seconds...")
                        delay(RETRY_DELAY_MS)
                    } else {
                        Log.e(TAG, "❌ All service start attempts failed")

                        prefs.edit()
                            .putLong("flutter.last_service_start_time", System.currentTimeMillis())
                            .putString("flutter.last_service_start_event", eventType)
                            .putBoolean("flutter.last_service_start_success", false)
                            .putString("flutter.last_service_start_error", e.message ?: "Unknown error")
                            .apply()
                    }
                }
            }
        }
    }

    private data class ConfigValidation(
        val isValid: Boolean,
        val reason: String
    )
}