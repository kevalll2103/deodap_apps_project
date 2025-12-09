package com.example.calllogmonitor

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.CallLog
import android.provider.ContactsContract
import android.provider.Settings
import android.telephony.SubscriptionManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.calllogmonitor.receivers.IncomingCallHandlerService
import com.example.calllogmonitor.CallLogSyncService
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "CallLogMonitor"
        private const val REQUEST_CODE_NOTIFICATION_PERMISSION = 1002
        private const val REQUEST_CODE_IGNORE_BATTERY_OPTIMIZATION = 1003
    }

    private val CHANNEL = "com.example.calllogmonitor/permissions"
    private val SYNC_CHANNEL = "com.example.calllogmonitor/call_log_sync"
    private val PERMISSION_REQUEST_CODE = 123
    private lateinit var methodChannel: MethodChannel
    private lateinit var syncMethodChannel: MethodChannel
    private var pendingResult: MethodChannel.Result? = null

    private val PREFS_NAME = "CallLogPrefs"
    private val SELECTED_SIM_KEY = "selected_sim"
    private val CALL_LOGS_KEY = "stored_call_logs"
    private val LAST_SYNC_TIME_KEY = "last_sync_time"

    private val requiredPermissions = arrayOf(
        Manifest.permission.READ_CALL_LOG,
        Manifest.permission.READ_CONTACTS,
        Manifest.permission.READ_PHONE_STATE
    )

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "call_monitor_channel",
                "Call Monitor Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Channel for call monitor foreground service"
                setShowBadge(true)
                enableLights(false)
                enableVibration(false)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created: call_monitor_channel")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity created")
        autoStartSyncServiceIfReady()
    }

    private fun autoStartSyncServiceIfReady() {
        try {
            if (hasAllPermissions()) {
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val warehouseId = prefs.getString("flutter.warehouse_id", "")
                val deviceId = prefs.getLong("flutter.user_id", 0L)
                val mobileNumber = prefs.getString("flutter.mobile_number", "")

                if (!warehouseId.isNullOrEmpty() && deviceId != 0L && !mobileNumber.isNullOrEmpty()) {
                    Log.d(TAG, "Auto-starting sync service...")
                    CallLogSyncService.startService(this)
                } else {
                    Log.d(TAG, "Device not configured, sync service will start after registration")
                }
            } else {
                Log.d(TAG, "Permissions not granted, sync service will start after permissions are granted")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error auto-starting sync service", e)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            handleOriginalMethodCall(call, result)
        }

        syncMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYNC_CHANNEL)
        syncMethodChannel.setMethodCallHandler { call, result ->
            handleSyncMethodCall(call, result)
        }
    }

    private fun handleSyncMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startSyncService" -> {
                startSyncService(result)
            }
            "checkPermissions" -> {
                checkAllPermissionsDetailed(result)
            }
            "requestPermissions" -> {
                pendingResult = result
                requestAllPermissions()
            }
            "isSyncServiceRunning" -> {
                isSyncServiceRunning(result)
            }
            "requestIgnoreBatteryOptimization" -> {
                requestIgnoreBatteryOptimization(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleOriginalMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getTotalCallLogsCount" -> {
                try {
                    val contentResolver = applicationContext.contentResolver
                    val calendar = java.util.Calendar.getInstance()
                    calendar.add(java.util.Calendar.MONTH, -3)
                    val threeMonthsAgo = calendar.timeInMillis

                    val selection = "${CallLog.Calls.DATE} >= ?"
                    val selectionArgs = arrayOf(threeMonthsAgo.toString())

                    val cursor = contentResolver.query(
                        CallLog.Calls.CONTENT_URI,
                        null, selection, selectionArgs, null
                    )
                    val count = cursor?.count ?: 0
                    cursor?.close()
                    result.success(count)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get total call logs count: ${e.message}", null)
                }
            }
            "checkAllPermissions" -> {
                result.success(hasAllPermissions())
            }
            "requestAllPermissions" -> {
                pendingResult = result
                requestAllPermissions()
            }
            "checkPermission" -> {
                val hasPermission = checkCallLogPermission()
                result.success(hasPermission)
            }
            "requestPermission" -> {
                pendingResult = result
                requestCallLogPermission()
            }
            "openAppSettings" -> {
                openAppSettings()
                result.success(null)
            }
            "getCallLogsWithSim" -> {
                if (checkCallLogPermission()) {
                    try {
                        val offset = call.argument<Int>("offset") ?: 0
                        val limit = call.argument<Int>("limit") ?: 100
                        val callLogs = getCallLogsWithSimInfo(offset, limit)
                        result.success(callLogs)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching call logs", e)
                        result.error("CALL_LOG_ERROR", "Failed to fetch call logs: ${e.message}", null)
                    }
                } else {
                    result.error("PERMISSION_DENIED", "Call log permission not granted", null)
                }
            }
            "setSelectedSim" -> {
                val simId = call.argument<String>("simId")
                if (simId != null) {
                    setSelectedSim(simId)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "SIM ID is required", null)
                }
            }
            "getSelectedSim" -> {
                val selectedSim = getSelectedSim()
                result.success(selectedSim)
            }
            "syncCallLogsForSelectedSim" -> {
                try {
                    syncCallLogsForSelectedSim()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SYNC_ERROR", "Failed to sync call logs: ${e.message}", null)
                }
            }
            "getStoredCallLogsForSelectedSim" -> {
                try {
                    val callLogs = getStoredCallLogsForSelectedSim()
                    result.success(callLogs)
                } catch (e: Exception) {
                    result.error("STORAGE_ERROR", "Failed to get stored call logs: ${e.message}", null)
                }
            }
            "clearStoredCallLogs" -> {
                try {
                    clearStoredCallLogs()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("CLEAR_ERROR", "Failed to clear stored call logs: ${e.message}", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startSyncService(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Starting sync service...")

            if (!hasAllPermissions()) {
                result.error("PERMISSION_DENIED", "Required permissions not granted", null)
                return
            }

            CallLogSyncService.startService(this)
            result.success(true)
            Log.d(TAG, "Sync service started successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error starting sync service", e)
            result.error("START_ERROR", "Failed to start sync service: ${e.message}", null)
        }
    }

    private fun checkAllPermissionsDetailed(result: MethodChannel.Result) {
        val hasPermissions = hasAllPermissions()
        val hasBatteryOptimization = isIgnoringBatteryOptimizations()

        val permissionStatus = mapOf(
            "hasCallLogPermission" to hasPermissions,
            "hasBatteryOptimization" to hasBatteryOptimization,
            "hasNotificationPermission" to hasNotificationPermission()
        )

        result.success(permissionStatus)
    }

    private fun requestIgnoreBatteryOptimization(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = Uri.parse("package:$packageName")
                startActivityForResult(intent, REQUEST_CODE_IGNORE_BATTERY_OPTIMIZATION)
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "Error requesting battery optimization", e)
                result.error("BATTERY_ERROR", "Failed to request battery optimization: ${e.message}", null)
            }
        } else {
            result.success(true)
        }
    }

    private fun isSyncServiceRunning(result: MethodChannel.Result) {
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val services = activityManager.getRunningServices(Integer.MAX_VALUE)

            val isRunning = services.any { serviceInfo ->
                serviceInfo.service.className == "com.example.calllogmonitor.CallLogSyncService"
            }

            result.success(isRunning)
        } catch (e: Exception) {
            Log.e(TAG, "Error checking service status", e)
            result.success(false)
        }
    }

    private fun hasAllPermissions(): Boolean {
        return requiredPermissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    private fun requestAllPermissions() {
        val missing = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            pendingResult?.success(true)
            pendingResult = null
            return
        }
        ActivityCompat.requestPermissions(
            this,
            missing.toTypedArray(),
            PERMISSION_REQUEST_CODE
        )
    }

    private fun checkCallLogPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_CALL_LOG
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestCallLogPermission() {
        if (!checkCallLogPermission()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.READ_CALL_LOG),
                PERMISSION_REQUEST_CODE
            )
        } else {
            pendingResult?.success(true)
            pendingResult = null
        }
    }

    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            val uri = Uri.fromParts("package", packageName, null)
            intent.data = uri
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening app settings", e)
            val intent = Intent(Settings.ACTION_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        when (requestCode) {
            PERMISSION_REQUEST_CODE -> {
                val granted = grantResults.isNotEmpty() &&
                        grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                pendingResult?.success(granted)
                pendingResult = null

                if (!granted) {
                    methodChannel.invokeMethod("showForcedExitDialog", null)
                    finish()
                }

                syncMethodChannel.invokeMethod("onPermissionResult", granted)
            }
            REQUEST_CODE_NOTIFICATION_PERMISSION -> {
                val granted = grantResults.isNotEmpty() &&
                        grantResults[0] == PackageManager.PERMISSION_GRANTED
                Log.d(TAG, "Notification permission result: $granted")
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            REQUEST_CODE_IGNORE_BATTERY_OPTIMIZATION -> {
                val isIgnoring = isIgnoringBatteryOptimizations()
                Log.d(TAG, "Battery optimization result: $isIgnoring")
                syncMethodChannel.invokeMethod("onBatteryOptimizationResult", isIgnoring)
            }
        }
    }

    private fun getCallLogsWithSimInfo(offset: Int = 0, limit: Int = Int.MAX_VALUE): List<Map<String, Any>> {
        val callLogs = mutableListOf<Map<String, Any>>()
        if (!checkCallLogPermission()) return callLogs

        val projection = arrayOf(
            CallLog.Calls.NUMBER,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
            CallLog.Calls.PHONE_ACCOUNT_ID
        )

        val calendar = java.util.Calendar.getInstance()
        calendar.add(java.util.Calendar.MONTH, -3)
        val threeMonthsAgo = calendar.timeInMillis

        val selection = "${CallLog.Calls.DATE} >= ?"
        val selectionArgs = arrayOf(threeMonthsAgo.toString())

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                "${CallLog.Calls.DATE} DESC"
            )

            cursor?.let { c ->
                val numberIndex = c.getColumnIndex(CallLog.Calls.NUMBER)
                val typeIndex = c.getColumnIndex(CallLog.Calls.TYPE)
                val dateIndex = c.getColumnIndex(CallLog.Calls.DATE)
                val durationIndex = c.getColumnIndex(CallLog.Calls.DURATION)
                val phoneAccountIndex = c.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_ID)

                if (offset > 0) {
                    if (!c.move(offset)) {
                        return callLogs
                    }
                }
                var count = 0
                do {
                    if (c.position < offset) continue
                    if (count >= limit) break

                    val number = if (numberIndex >= 0) c.getString(numberIndex) ?: "" else ""
                    val type = if (typeIndex >= 0) c.getInt(typeIndex) else 0
                    val date = if (dateIndex >= 0) c.getLong(dateIndex) else 0L
                    val duration = if (durationIndex >= 0) c.getInt(durationIndex) else 0
                    val phoneAccountId = if (phoneAccountIndex >= 0) c.getString(phoneAccountIndex) else null

                    val simId = getSimSlotFromPhoneAccountId(phoneAccountId)
                    val name = getContactName(number)

                    val callLog = mapOf(
                        "number" to number,
                        "name" to name,
                        "type" to type,
                        "date" to date.toString(),
                        "duration" to duration.toString(),
                        "sim_id" to simId
                    )

                    callLogs.add(callLog)
                    count++
                } while (c.moveToNext())
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading call logs", e)
            throw e
        } finally {
            cursor?.close()
        }

        return callLogs
    }

    private fun getContactName(phoneNumber: String): String {
        try {
            val uri = Uri.withAppendedPath(
                ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                Uri.encode(phoneNumber)
            )
            val cursor = contentResolver.query(
                uri,
                arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME),
                null,
                null,
                null
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    return it.getString(0) ?: ""
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error looking up contact name", e)
        }
        return ""
    }

    private fun getSimSlotFromPhoneAccountId(phoneAccountId: String?): String {
        if (phoneAccountId == null) return "unknown"

        try {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE)
                != PackageManager.PERMISSION_GRANTED) {
                return "unknown"
            }

            val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as? SubscriptionManager
            subscriptionManager?.let { sm ->
                val activeSubscriptions = sm.activeSubscriptionInfoList
                activeSubscriptions?.forEach { subscription ->
                    if (phoneAccountId.contains(subscription.subscriptionId.toString()) ||
                        phoneAccountId.contains(subscription.simSlotIndex.toString())) {
                        return (subscription.simSlotIndex + 1).toString()
                    }
                }
            }

            return when {
                phoneAccountId.contains("0") || phoneAccountId.contains("sim1") -> "1"
                phoneAccountId.contains("1") || phoneAccountId.contains("sim2") -> "2"
                phoneAccountId.contains("2") -> "1"
                phoneAccountId.contains("3") -> "2"
                else -> "unknown"
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error getting SIM info", e)
            return "unknown"
        }
    }

    private fun setSelectedSim(simId: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(SELECTED_SIM_KEY, simId).apply()
        Log.d(TAG, "Selected SIM set to: $simId")
    }

    private fun getSelectedSim(): String {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(SELECTED_SIM_KEY, "1") ?: "1"
    }

    private fun syncCallLogsForSelectedSim() {
        if (!checkCallLogPermission()) {
            throw SecurityException("Call log permission not granted")
        }

        val selectedSim = getSelectedSim()
        val callLogs = getCallLogsForSpecificSim(selectedSim)

        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val gson = Gson()
        val callLogsJson = gson.toJson(callLogs)

        prefs.edit()
            .putString(CALL_LOGS_KEY, callLogsJson)
            .putLong(LAST_SYNC_TIME_KEY, System.currentTimeMillis())
            .apply()

        Log.d(TAG, "Synced ${callLogs.size} call logs for SIM $selectedSim")
    }

    private fun getCallLogsForSpecificSim(simId: String): List<Map<String, Any>> {
        val callLogs = mutableListOf<Map<String, Any>>()
        if (!checkCallLogPermission()) return callLogs

        val projection = arrayOf(
            CallLog.Calls.NUMBER,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
            CallLog.Calls.PHONE_ACCOUNT_ID
        )

        val calendar = java.util.Calendar.getInstance()
        calendar.add(java.util.Calendar.MONTH, -3)
        val threeMonthsAgo = calendar.timeInMillis

        val selection = "${CallLog.Calls.DATE} >= ?"
        val selectionArgs = arrayOf(threeMonthsAgo.toString())

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                "${CallLog.Calls.DATE} DESC"
            )

            cursor?.let { c ->
                val numberIndex = c.getColumnIndex(CallLog.Calls.NUMBER)
                val typeIndex = c.getColumnIndex(CallLog.Calls.TYPE)
                val dateIndex = c.getColumnIndex(CallLog.Calls.DATE)
                val durationIndex = c.getColumnIndex(CallLog.Calls.DURATION)
                val phoneAccountIndex = c.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_ID)

                while (c.moveToNext()) {
                    val number = if (numberIndex >= 0) c.getString(numberIndex) ?: "" else ""
                    val type = if (typeIndex >= 0) c.getInt(typeIndex) else 0
                    val date = if (dateIndex >= 0) c.getLong(dateIndex) else 0L
                    val duration = if (durationIndex >= 0) c.getInt(durationIndex) else 0
                    val phoneAccountId = if (phoneAccountIndex >= 0) c.getString(phoneAccountIndex) else null

                    val callSimId = getSimSlotFromPhoneAccountId(phoneAccountId)

                    if (callSimId == simId) {
                        val name = getContactName(number)

                        val callLog = mapOf(
                            "number" to number,
                            "name" to name,
                            "type" to type,
                            "date" to date.toString(),
                            "duration" to duration.toString(),
                            "sim_id" to callSimId
                        )

                        callLogs.add(callLog)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading call logs for SIM $simId", e)
            throw e
        } finally {
            cursor?.close()
        }

        return callLogs
    }

    private fun getStoredCallLogsForSelectedSim(): List<Map<String, Any>> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val callLogsJson = prefs.getString(CALL_LOGS_KEY, null)

        return if (callLogsJson != null) {
            try {
                val gson = Gson()
                val type = object : com.google.gson.reflect.TypeToken<List<Map<String, Any>>>() {}.type
                gson.fromJson(callLogsJson, type) ?: emptyList()
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing stored call logs", e)
                emptyList()
            }
        } else {
            emptyList()
        }
    }

    private fun clearStoredCallLogs() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .remove(CALL_LOGS_KEY)
            .remove(LAST_SYNC_TIME_KEY)
            .apply()
        Log.d(TAG, "Stored call logs cleared")
    }

    private fun hasRequiredPermissions(): Boolean {
        return requiredPermissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun checkAndRequestPermissions() {
        if (hasAllPermissions()) {
            // All permissions are granted
            methodChannel.invokeMethod("onPermissionChanged", true)
            
            // Start the call log sync service
            startService(Intent(this, CallLogSyncService::class.java))
        } else {
            val missingPermissions = requiredPermissions.filter {
                ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
            }
            
            if (missingPermissions.isNotEmpty()) {
                ActivityCompat.requestPermissions(
                    this,
                    missingPermissions.toTypedArray(),
                    PERMISSION_REQUEST_CODE
                )
            }
        }
    }

    override fun onResume() {
        super.onResume()
        checkAndRequestPermissions()
        
        // Process any missed call logs when the app is opened
        if (hasRequiredPermissions()) {
            processMissedCallLogs()
        }
    }
    
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    
    private fun processMissedCallLogs() {
        try {
            val intent = Intent(this, IncomingCallHandlerService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent) 
            }
            
            // Launch the coroutine in the IO dispatcher
            coroutineScope.launch(Dispatchers.IO) {
                try {
                    val service = IncomingCallHandlerService()
                    service.processRecentCallLogs(applicationContext)
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing missed call logs", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting call log processing", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "MainActivity destroyed")
    }
}