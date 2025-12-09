package com.example.calllogmonitor

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.net.Uri
import android.os.*
import android.provider.CallLog
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

class CallLogSyncService : Service() {

    companion object {
        private const val TAG = "CallLogSyncService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "call_log_sync"
        private const val SYNC_INTERVAL_MS = 10 * 60 * 1000L // 10 minutes
        private const val HEARTBEAT_INTERVAL_MS = 60_000L    // 1 minute
        private const val BASE_URL = "https://trackship.in"
        private const val ENDPOINT = "/api/lms/calls.php"

        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_LAST_SYNC_TIME = "flutter.last_sync_time"
        private const val KEY_WAREHOUSE_ID = "flutter.warehouse_id"
        private const val KEY_DEVICE_ID = "flutter.user_id"
        private const val KEY_MOBILE_NUMBER = "flutter.mobile_number"
        private const val KEY_SELECTED_SIM = "flutter.selected_sim"
        private const val KEY_TOTAL_SYNCED_CALLS = "flutter.total_synced_calls"
        private const val KEY_SERVICE_START_COUNT = "flutter.service_start_count"

        private const val ACTION_SYNC_NOW = "SYNC_NOW"

        fun startService(context: Context) {
            val intent = Intent(context, CallLogSyncService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var syncJob: Job? = null
    private var debounceJob: Job? = null
    private var heartbeatJob: Job? = null

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private var totalSyncedCalls = 0
    private var lastSyncStatus = "Starting..."
    @Volatile private var isCurrentlySyncing = false
    private var lastSuccessfulSyncTime = 0L
    private var serviceStartCount = 0

    private var wakeLock: PowerManager.WakeLock? = null
    private val WAKE_LOCK_TAG = "CallLogSyncService::WakeLock"

    private var callLogObserver: ContentObserver? = null
    private val processedIds = Collections.synchronizedSet(HashSet<String>())

    // region Lifecycle
    override fun onCreate() {
        super.onCreate()

        incrementServiceStartCount()
        Log.d(TAG, "🚀 Service Created (Start #$serviceStartCount)")

        createNotificationChannel()
        loadTotalSyncedCalls()
        loadLastSyncTime()

        logPermissionState("onCreate")

        // Register observer (will no-op if permission not granted)
        registerCallLogObserver()

        val initialNotification = createHighPriorityNotification(
            "📡 Monitoring Active (Start #$serviceStartCount)"
        )
        startForeground(NOTIFICATION_ID, initialNotification)

        startSyncLoop()
        startHeartbeat()

        // Initial sync after small delay
        serviceScope.launch {
            delay(2000)
            Log.d(TAG, "🔄 Initial sync after service start")
            performImmediateSync()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: action=${intent?.action}")

        // Ensure observer is valid
        if (callLogObserver == null) {
            Log.w(TAG, "⚠️ Observer was null in onStartCommand, re-registering")
            registerCallLogObserver()
        }

        val notification = createHighPriorityNotification(
            "📡 Service Active - ${getCurrentTime()}"
        )
        startForeground(NOTIFICATION_ID, notification)

        when (intent?.action) {
            ACTION_SYNC_NOW -> {
                debounceJob?.cancel()
                serviceScope.launch { performImmediateSync() }
            }
            else -> {
                startSyncLoop()
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        Log.w(TAG, "⚠️ Service Destroyed - Restart Count: $serviceStartCount")
        unregisterCallLogObserver()
        syncJob?.cancel()
        debounceJob?.cancel()
        heartbeatJob?.cancel()
        serviceScope.cancel()
        releaseWakeLock()

        // Try to restart (may still be killed by OEM)
        restartService()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
    // endregion

    // region Service start count / prefs
    private fun incrementServiceStartCount() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        serviceStartCount = prefs.getInt(KEY_SERVICE_START_COUNT, 0) + 1
        prefs.edit().putInt(KEY_SERVICE_START_COUNT, serviceStartCount).apply()
    }

    private fun loadTotalSyncedCalls() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        totalSyncedCalls = prefs.getInt(KEY_TOTAL_SYNCED_CALLS, 0)
        Log.d(TAG, "Total synced so far: $totalSyncedCalls")
    }

    private fun loadLastSyncTime() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        lastSuccessfulSyncTime = prefs.getLong(KEY_LAST_SYNC_TIME, 0L)

        if (lastSuccessfulSyncTime > 0) {
            val date = SimpleDateFormat("dd-MM-yyyy HH:mm:ss", Locale.getDefault())
                .format(Date(lastSuccessfulSyncTime))
            Log.d(TAG, "Last sync time: $date")
        } else {
            Log.d(TAG, "No previous sync found (First install)")
        }
    }
    // endregion

    // region Heartbeat
    private fun startHeartbeat() {
        heartbeatJob?.cancel()
        heartbeatJob = serviceScope.launch {
            while (isActive) {
                delay(HEARTBEAT_INTERVAL_MS)
                Log.d(TAG, "💓 Heartbeat #$serviceStartCount - Synced: $totalSyncedCalls")

                // Ensure observer is alive
                if (callLogObserver == null) {
                    Log.e(TAG, "❌ Observer was null in heartbeat! Re-registering...")
                    registerCallLogObserver()
                }

                updateNotification("💓 Active - ${getCurrentTime()}")

                if (wakeLock?.isHeld != true) {
                    acquireWakeLock()
                }
            }
        }
    }

    private fun restartService() {
        try {
            val intent = Intent(applicationContext, CallLogSyncService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                applicationContext.startForegroundService(intent)
            } else {
                applicationContext.startService(intent)
            }
            Log.d(TAG, "🔄 Restart request sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart service", e)
        }
    }
    // endregion

    // region ContentObserver
    private fun hasCallLogPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_CALL_LOG
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun logPermissionState(source: String) {
        val readCallLog =
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) == PackageManager.PERMISSION_GRANTED
        val readPhoneState =
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
        val readContacts =
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED

        Log.d(
            TAG,
            "🔐 Permission state @ $source -> READ_CALL_LOG=$readCallLog, READ_PHONE_STATE=$readPhoneState, READ_CONTACTS=$readContacts"
        )
    }

    private fun registerCallLogObserver() {
        try {
            if (!hasCallLogPermission()) {
                logPermissionState("registerCallLogObserver")
                Log.e(TAG, "❌ READ_CALL_LOG permission not granted, cannot register observer")
                return
            }

            // Unregister if already present
            unregisterCallLogObserver()

            callLogObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    super.onChange(selfChange, uri)
                    Log.d(
                        TAG,
                        "📞 Call Log Changed - selfChange=$selfChange, URI=$uri, time=${getCurrentTime()}"
                    )
                    triggerRealTimeSync()
                }
            }

            contentResolver.registerContentObserver(
                CallLog.Calls.CONTENT_URI,
                true,
                callLogObserver!!
            )

            Log.d(TAG, "✅ ContentObserver registered successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Observer registration failed", e)
        }
    }

    private fun unregisterCallLogObserver() {
        try {
            callLogObserver?.let {
                contentResolver.unregisterContentObserver(it)
                Log.d(TAG, "Observer unregistered")
            }
            callLogObserver = null
        } catch (e: Exception) {
            Log.e(TAG, "Observer unregister failed", e)
        }
    }

    private fun triggerRealTimeSync() {
        if (isCurrentlySyncing) {
            Log.d(TAG, "Sync in progress, will retry after current sync")
            return
        }

        debounceJob?.cancel()
        debounceJob = serviceScope.launch {
            Log.d(TAG, "⏳ Waiting 3s for DB to settle after change...")
            delay(3000)
            Log.d(TAG, "🔄 Starting real-time sync now")
            performImmediateSync()
        }
    }
    // endregion

    // region WakeLock
    private fun acquireWakeLock() {
        try {
            if (wakeLock?.isHeld != true) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    WAKE_LOCK_TAG
                ).apply {
                    setReferenceCounted(false)
                    acquire(10 * 60 * 1000L)
                }
                Log.d(TAG, "🔋 WakeLock Acquired")
            }
        } catch (e: Exception) {
            Log.e(TAG, "WakeLock acquire failed", e)
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                Log.d(TAG, "🔋 WakeLock Released")
            }
        } catch (e: Exception) {
            Log.e(TAG, "WakeLock release failed", e)
        }
    }
    // endregion

    // region Notification
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Call Log Sync Service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Monitors and syncs call logs in real-time"
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(false)
                enableLights(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createHighPriorityNotification(message: String): Notification {
        val mainIntent = packageManager.getLaunchIntentForPackage(packageName)
        val mainPendingIntent = PendingIntent.getActivity(
            this, 0, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Call Monitor Service")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(mainPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        if (totalSyncedCalls > 0) {
            builder.setSubText("Total: $totalSyncedCalls calls")
        }

        return builder.build()
    }

    private fun updateNotification(message: String) {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, createHighPriorityNotification(message))
        } catch (e: Exception) {
            Log.e(TAG, "Notification update failed", e)
        }
    }
    // endregion

    // region Sync Logic
    private fun startSyncLoop() {
        if (syncJob?.isActive == true) {
            Log.d(TAG, "Sync loop already running")
            return
        }

        syncJob = serviceScope.launch {
            Log.d(TAG, "🔁 Periodic sync loop started")
            while (isActive) {
                delay(SYNC_INTERVAL_MS)
                Log.d(TAG, "⏰ Periodic sync trigger")
                performSyncSafe()
            }
        }
    }

    private suspend fun performImmediateSync() {
        performSyncSafe()
    }

    private suspend fun performSyncSafe() {
        if (isCurrentlySyncing) {
            Log.d(TAG, "Already syncing, skipping")
            return
        }

        try {
            isCurrentlySyncing = true
            acquireWakeLock()
            updateNotification("🔄 Syncing...")

            val result = performSync()

            if (result.success) {
                lastSyncStatus = result.message
                val notification = if (result.message.contains("No new calls")) {
                    "✅ Up to date - ${getCurrentTime()}"
                } else {
                    "✅ ${getCurrentTime()} - ${result.message}"
                }
                updateNotification(notification)
                Log.d(TAG, "✅ Sync success: ${result.message}")
            } else {
                lastSyncStatus = "Failed: ${result.message}"
                updateNotification("⚠️ ${result.message}")
                Log.e(TAG, "❌ Sync failed: ${result.message}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Sync error", e)
            updateNotification("❌ Error: ${e.message}")
        } finally {
            isCurrentlySyncing = false
            releaseWakeLock()
        }
    }

    private suspend fun performSync(): SyncResult {
        return withContext(Dispatchers.IO) {
            try {
                if (!hasCallLogPermission()) {
                    logPermissionState("performSync")
                    return@withContext SyncResult(false, "READ_CALL_LOG permission missing")
                }

                val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val warehouseId = prefs.getString(KEY_WAREHOUSE_ID, "") ?: ""
                val deviceIdRaw = prefs.getLong(KEY_DEVICE_ID, 0L)
                val deviceId = deviceIdRaw.toString()
                val mobileNumber = prefs.getString(KEY_MOBILE_NUMBER, "") ?: ""
                // DEFAULT: ALL sim
                val selectedSim = prefs.getString(KEY_SELECTED_SIM, "ALL") ?: "ALL"
                val lastSyncTime = prefs.getLong(KEY_LAST_SYNC_TIME, 0L)

                Log.d(
                    TAG,
                    "Config -> whId=$warehouseId, deviceIdRaw=$deviceIdRaw, mobile=$mobileNumber, selectedSim=$selectedSim, lastSyncTime=$lastSyncTime"
                )

                if (warehouseId.isEmpty() || deviceIdRaw == 0L) {
                    Log.e(TAG, "❌ Config missing: warehouseId or deviceId")
                    return@withContext SyncResult(false, "Config missing")
                }

                Log.d(
                    TAG,
                    "Fetching calls after: ${
                        if (lastSyncTime > 0)
                            SimpleDateFormat("dd-MM HH:mm", Locale.getDefault()).format(Date(lastSyncTime))
                        else
                            "First Install (last 24h)"
                    }, selectedSim=$selectedSim"
                )

                val newCallLogs = getNewCallLogs(lastSyncTime, selectedSim)
                Log.d(TAG, "Found ${newCallLogs.size} new calls")

                if (newCallLogs.isEmpty()) {
                    return@withContext SyncResult(true, "No new calls")
                }

                val callDataJson = convertCallLogsToJson(newCallLogs, mobileNumber)
                if (callDataJson.length() == 0) {
                    Log.w(TAG, "No JSON data to sync even though call list non-empty")
                    return@withContext SyncResult(true, "No new calls (empty JSON)")
                }

                val apiResult = syncToAPI(warehouseId, deviceId, mobileNumber, callDataJson)

                if (apiResult.success) {
                    totalSyncedCalls += newCallLogs.size
                    val maxCallDate = newCallLogs.maxOf { it.date.coerceAtLeast(0L) }
                    lastSuccessfulSyncTime = maxCallDate

                    prefs.edit()
                        .putLong(KEY_LAST_SYNC_TIME, lastSuccessfulSyncTime)
                        .putInt(KEY_TOTAL_SYNCED_CALLS, totalSyncedCalls)
                        .apply()

                    if (processedIds.size > 1000) processedIds.clear()
                    newCallLogs.forEach { processedIds.add(it.id) }

                    Log.d(TAG, "✅ Synced ${newCallLogs.size} calls. Total: $totalSyncedCalls")
                    return@withContext SyncResult(true, "Synced ${newCallLogs.size} calls")
                } else {
                    return@withContext SyncResult(false, apiResult.message)
                }

            } catch (e: Exception) {
                Log.e(TAG, "performSync exception", e)
                return@withContext SyncResult(false, "Error: ${e.message}")
            }
        }
    }

    private fun getNewCallLogs(lastSyncTime: Long, selectedSim: String): List<CallLogData> {
        val callLogs = mutableListOf<CallLogData>()

        val selection: String
        val selectionArgs: Array<String>

        if (lastSyncTime > 0) {
            selection = "${CallLog.Calls.DATE} > ?"
            selectionArgs = arrayOf(lastSyncTime.toString())
        } else {
            val twentyFourHoursAgo = System.currentTimeMillis() - (24 * 60 * 60 * 1000)
            selection = "${CallLog.Calls.DATE} > ?"
            selectionArgs = arrayOf(twentyFourHoursAgo.toString())
            Log.d(TAG, "First install - fetching last 24h calls only")
        }

        val cursor = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            arrayOf(
                CallLog.Calls._ID,
                CallLog.Calls.NUMBER,
                CallLog.Calls.CACHED_NAME,
                CallLog.Calls.TYPE,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1)
                    CallLog.Calls.PHONE_ACCOUNT_ID
                else
                    CallLog.Calls.NUMBER
            ),
            selection,
            selectionArgs,
            "${CallLog.Calls.DATE} ASC"
        )

        cursor?.use { c ->
            val idIndex = c.getColumnIndex(CallLog.Calls._ID)
            val numberIndex = c.getColumnIndex(CallLog.Calls.NUMBER)
            val nameIndex = c.getColumnIndex(CallLog.Calls.CACHED_NAME)
            val typeIndex = c.getColumnIndex(CallLog.Calls.TYPE)
            val dateIndex = c.getColumnIndex(CallLog.Calls.DATE)
            val durationIndex = c.getColumnIndex(CallLog.Calls.DURATION)
            val accountIndex = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1)
                c.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_ID)
            else -1

            while (c.moveToNext()) {
                val id = c.getString(idIndex)

                if (processedIds.contains(id)) {
                    Log.d(TAG, "Skipping duplicate ID: $id")
                    continue
                }

                val number = c.getString(numberIndex) ?: ""
                val name = c.getString(nameIndex) ?: ""
                val type = c.getInt(typeIndex)
                val date = c.getLong(dateIndex)
                val duration = c.getLong(durationIndex)
                val accountId =
                    if (accountIndex >= 0) c.getString(accountIndex) ?: "" else ""

                val simSlot = getSimSlotFromAccountId(accountId)

                val simName = when (selectedSim) {
                    "SIM1" -> "SIM 1"
                    "SIM2" -> "SIM 2"
                    else -> "ALL"
                }

                if (simName == "ALL" || simSlot == simName) {
                    callLogs.add(
                        CallLogData(
                            id = id,
                            number = number,
                            name = name,
                            type = getCallTypeString(type),
                            date = date,
                            duration = duration,
                            simSlot = simSlot
                        )
                    )
                } else {
                    Log.d(
                        TAG,
                        "Filtered out by SIM: id=$id simSlot=$simSlot selectedSim=$selectedSim"
                    )
                }
            }
        }

        Log.d(TAG, "Query returned ${callLogs.size} calls after SIM filter")
        return callLogs
    }

    private fun getSimSlotFromAccountId(accountId: String?): String {
        if (accountId == null) return "SIM 1"
        val idLower = accountId.lowercase(Locale.getDefault())
        return when {
            idLower.contains("sim2") || idLower.contains("sub1") ||
                    (idLower.contains("2") && !idLower.contains("sim1")) -> "SIM 2"
            else -> "SIM 1"
        }
    }

    private fun getCallTypeString(type: Int): String {
        return when (type) {
            CallLog.Calls.INCOMING_TYPE -> "INCOMING"
            CallLog.Calls.OUTGOING_TYPE -> "OUTGOING"
            CallLog.Calls.MISSED_TYPE -> "MISSED"
            CallLog.Calls.REJECTED_TYPE -> "REJECTED"
            CallLog.Calls.BLOCKED_TYPE -> "BLOCKED"
            CallLog.Calls.VOICEMAIL_TYPE -> "VOICEMAIL"
            else -> "UNKNOWN"
        }
    }

    private fun convertCallLogsToJson(callLogs: List<CallLogData>, deviceNumber: String): JSONArray {
        val jsonArray = JSONArray()
        val safeDeviceNumber = if (deviceNumber.isBlank()) "UNKNOWN_DEVICE_NUMBER" else deviceNumber

        for (call in callLogs) {
            val jsonObject = JSONObject().apply {
                put("device_number", safeDeviceNumber)
                put("call_type", call.type)
                put("caller_number", if (call.number.isEmpty()) "UNKNOWN" else call.number)
                put("caller_name", if (call.name.isEmpty()) "UNKNOWN" else call.name)
                put("duration", call.duration.toString())
                put("time", formatDateForJson(call.date))
            }
            jsonArray.put(jsonObject)
        }
        return jsonArray
    }

    private suspend fun syncToAPI(
        whId: String,
        devId: String,
        regNum: String,
        data: JSONArray
    ): ApiResult {
        return withContext(Dispatchers.IO) {
            try {
                if (data.length() == 0) {
                    Log.w(TAG, "syncToAPI called with empty data")
                    return@withContext ApiResult(true, "No data")
                }

                val url = "$BASE_URL$ENDPOINT"
                val formBody = FormBody.Builder()
                    .add("action", "sync_data")
                    .add("wh_id", whId)
                    .add("device_id", devId)
                    .add("register_device_number", regNum)
                    .add("data", data.toString())
                    .add("page_number", "1")
                    .add("total_pages", "1")
                    .add("records_per_page", data.length().toString())
                    .build()

                val request = Request.Builder().url(url).post(formBody).build()

                Log.d(TAG, "Sending ${data.length()} calls to API")

                client.newCall(request).execute().use { response ->
                    if (response.isSuccessful) {
                        Log.d(TAG, "API Success: ${response.code}")
                        ApiResult(true, "Success")
                    } else {
                        Log.e(TAG, "API Error: ${response.code}")
                        ApiResult(false, "Server Error ${response.code}")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "API Exception", e)
                ApiResult(false, "Network: ${e.message}")
            }
        }
    }

    private fun formatDateForJson(timestamp: Long): String {
        val safeTs = timestamp.coerceAtLeast(0L)
        val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        return dateFormat.format(Date(safeTs))
    }

    private fun getCurrentTime(): String {
        return SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
    }
    // endregion

    // region Data classes
    data class CallLogData(
        val id: String,
        val number: String,
        val name: String,
        val type: String,
        val date: Long,
        val duration: Long,
        val simSlot: String
    )

    data class SyncResult(val success: Boolean, val message: String)
    data class ApiResult(val success: Boolean, val message: String)
    // endregion
}
