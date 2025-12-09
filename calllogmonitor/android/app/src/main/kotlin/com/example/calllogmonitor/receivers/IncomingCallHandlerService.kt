package com.example.calllogmonitor.receivers

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.database.Cursor
import android.os.Build
import android.os.IBinder
import android.provider.ContactsContract
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit
import android.content.ContentProviderOperation

class IncomingCallHandlerService : Service() {

    companion object {
        private const val TAG = "IncomingCallHandler"
        private const val BASE_URL = "https://trackship.in"
        private const val NOTIFICATION_ID = 9999
        private const val CHANNEL_ID = "incoming_call_save"

        // ===== SharedPreferences (Flutter keys) =====
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_WH_ID = "flutter.executive_warehouse_id"  // String
        private const val KEY_SALES_ID = "flutter.executive_id"         // Int/String
        private const val KEY_AUTH = "flutter.executive_auth_key"       // String

        // Optional overrides (comma-separated). If missing, we auto-discover.
        private const val KEY_SOURCE_IDS = "flutter.lms_source_ids"     // e.g. "4,6,8"
        private const val KEY_STATUS_IDS = "flutter.lms_status_ids"     // e.g. "4,5,7"

        // Duplicate guard
        private const val KEY_LAST_HASH = "last_processed_call_hash"
    }

    // ===== Tunables for search performance =====
    private val SEARCH_TIMEOUT_SEC = 25L
    private val PER_STATUS_PAGE_LIMIT = 30  // safety cap; we'll still respect API total_page if smaller

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val client by lazy {
        OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(SEARCH_TIMEOUT_SEC, TimeUnit.SECONDS)
            .writeTimeout(15, TimeUnit.SECONDS)
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val phoneNumber = intent?.getStringExtra("PHONE_NUMBER").orEmpty()
        val timestamp = intent?.getLongExtra("TIMESTAMP", System.currentTimeMillis())
            ?: System.currentTimeMillis()

        showNotification("Processing call...")

        if (isDuplicate(phoneNumber, timestamp)) {
            Log.d(TAG, "⏭️ Duplicate in same minute — skipped")
            stopServiceSafely(startId)
            return START_STICKY
        }

        if (phoneNumber.isBlank()) {
            updateNotification("❌ No phone number")
            stopServiceSafely(startId)
            return START_STICKY
        }

        scope.launch {
            try {
                handleIncomingCall(phoneNumber)
            } catch (e: Exception) {
                Log.e(TAG, "Service error", e)
                updateNotification("❌ Error: ${e.message}")
            } finally {
                stopServiceSafely(startId)
            }
        }

        return START_REDELIVER_INTENT
    }

   private fun isDuplicate(number: String, ts: Long): Boolean {
    val currentHash = "${normalize10(number)}|${ts / 30_000L}"  // Changed from 60s to 30s
    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val last = prefs.getString(KEY_LAST_HASH, null)
    return if (currentHash == last) {
        Log.d(TAG, "⏭️ Duplicate call detected (same number in 30s window)")
        true
    } else {
        prefs.edit().putString(KEY_LAST_HASH, currentHash).apply()
        false
    }
}
    private suspend fun handleIncomingCall(incomingRaw: String) {
        val incoming = normalize10(incomingRaw)
        Log.d(TAG, "📞 Incoming: $incomingRaw → normalized: $incoming")

        val creds = getCredentials() ?: run {
            updateNotification("⚠️ Missing credentials in SharedPreferences")
            return
        }
        val (whId, salesId, authKey) = creds

        // 1) Try local phonebook first
        updateNotification("🔎 Checking phone contacts…")
        findExistingContact(incoming)?.let { (_, display) ->
            updateNotification("✅ Already saved: $display")
            // still notify API so your dashboard gets the event
            saveToAPI(display, incoming, whId, salesId, authKey)
            return
        }

        // 2) Discover sources/statuses (or take overrides from prefs)
        updateNotification("📊 Loading lead sources…")
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val prefSources = prefs.getString(KEY_SOURCE_IDS, "")!!.trim()
        val prefStatuses = prefs.getString(KEY_STATUS_IDS, "")!!.trim()

        val sourceIds: List<Int>
        val statusIds: List<Int>

        if (prefSources.isNotEmpty() && prefStatuses.isNotEmpty()) {
            sourceIds = prefSources.split(",").mapNotNull { it.trim().toIntOrNull() }
            statusIds = prefStatuses.split(",").mapNotNull { it.trim().toIntOrNull() }
        } else {
            val discovered = discoverSourcesAndStatuses(whId, salesId, authKey)
            if (discovered.first.isEmpty() || discovered.second.isEmpty()) {
                updateNotification("⚠️ Couldn’t discover sources/statuses")
                return
            }
            sourceIds = discovered.first
            statusIds = discovered.second
        }

        Log.d(TAG, "🔁 Will scan sources=$sourceIds statuses=$statusIds")

        // 3) Live search via list_all (paginated)
        updateNotification("🔍 Searching leads…")
        val lead = findLeadByMobile(incoming, whId, salesId, authKey, sourceIds, statusIds)

        if (lead == null) {
            updateNotification("ℹ️ Number not found in LMS")
            return
        }

        val (leadName, leadMobile) = lead
        Log.d(TAG, "🎯 Found in LMS → name=$leadName, mobile=$leadMobile")

        // 4) Save to API (lead/call log) — non-blocking failure
        val apiOk = saveToAPI(leadName, leadMobile, whId, salesId, authKey)

        // 5) Save to phone contacts (retry once if needed)
        updateNotification("📱 Saving contact…")
        var phoneOk = saveToPhoneContacts(leadName, leadMobile)
        if (!phoneOk) {
            delay(450)
            phoneOk = saveToPhoneContacts(leadName, leadMobile)
        }

        when {
            apiOk && phoneOk -> showSuccessNotification("Saved to phone & API: $leadName", leadName)
            phoneOk && !apiOk -> showSuccessNotification("Saved to phone (API failed): $leadName", leadName)
            apiOk && !phoneOk -> updateNotification("Saved to API (contact save failed): $leadName")
            else -> updateNotification("❌ Failed to save: $leadName")
        }
    }

    // --- Credentials ---
    private fun getCredentials(): Triple<String, String, String>? {
        return try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val wh = prefs.getString(KEY_WH_ID, "").orEmpty()
            val sales = prefs.getIntCompat(KEY_SALES_ID, 0).takeIf { it != 0 }?.toString()
                ?: prefs.getString(KEY_SALES_ID, "").orEmpty()
            val key = prefs.getString(KEY_AUTH, "").orEmpty()

            if (wh.isBlank() || sales.isBlank() || key.isBlank()) null
            else Triple(wh, sales, key)
        } catch (e: Exception) {
            Log.e(TAG, "Cred read error", e); null
        }
    }

    // --- Discover sources/statuses from dashboard ---
    private suspend fun discoverSourcesAndStatuses(
        whId: String,
        salesId: String,
        authKey: String
    ): Pair<List<Int>, List<Int>> = withContext(Dispatchers.IO) {
        try {
            val body = FormBody.Builder()
                .add("action", "executive_dashboard")
                .add("wh_id", whId)
                .add("sales_id", salesId)
                .add("api_auth_key", authKey)
                .build()

            val req = Request.Builder()
                .url("$BASE_URL/api/lms/leads.php")
                .post(body)
                .addHeader("Content-Type", "application/x-www-form-urlencoded")
                .build()

            client.newCall(req).execute().use { resp ->
                val text = resp.body?.string().orEmpty()
                if (!resp.isSuccessful) return@withContext Pair(emptyList(), emptyList())

                val js = JSONObject(text)
                val data = js.optJSONArray("data") ?: JSONArray()

                val src = mutableSetOf<Int>()
                val sts = mutableSetOf<Int>()

                for (i in 0 until data.length()) {
                    val obj = data.getJSONObject(i)
                    val sid = obj.optString("source_id").toIntOrNull()
                    if (sid != null) src += sid

                    val sl = obj.optJSONArray("status_list") ?: JSONArray()
                    for (j in 0 until sl.length()) {
                        sl.getJSONObject(j).optString("status_id").toIntOrNull()?.let { sts += it }
                    }
                }

                Log.d(TAG, "Discovered sources=$src statuses=$sts")
                Pair(src.toList().sorted(), sts.toList().sorted())
            }
        } catch (e: Exception) {
            Log.e(TAG, "discover error", e)
            Pair(emptyList(), emptyList())
        }
    }

    // --- Search LMS by iterating list_all across sources/statuses & pages ---
    private suspend fun findLeadByMobile(
        incoming10: String,
        whId: String,
        salesId: String,
        authKey: String,
        sourceIds: List<Int>,
        statusIds: List<Int>
    ): Pair<String, String>? = withContext(Dispatchers.IO) {

        for (source in sourceIds) {
            for (status in statusIds) {
                var page = 1
                var totalPages = 1
                var pageCount = 0

                do {
                    val body = FormBody.Builder()
                        .add("action", "list_all")
                        .add("wh_id", whId)
                        .add("sales_id", salesId)
                        .add("api_auth_key", authKey)
                        .add("source_id", source.toString())
                        .add("status_id", status.toString())
                        .add("page", page.toString())
                        .build()

                    val req = Request.Builder()
                        .url("$BASE_URL/api/lms/leads.php")
                        .post(body)
                        .addHeader("Content-Type", "application/x-www-form-urlencoded")
                        .build()

                    val res = client.newCall(req).execute()
                    val txt = res.body?.string().orEmpty()

                    if (!res.isSuccessful) {
                        Log.w(TAG, "list_all failed src=$source sts=$status page=$page: ${res.code}")
                        break
                    }

                    val js = JSONObject(txt)
                    totalPages = js.optInt("total_page", 1)
                    val arr = js.optJSONArray("data") ?: JSONArray()

                    // scan page
                    for (i in 0 until arr.length()) {
                        val item = arr.getJSONObject(i)
                        val name = item.optString("customer_name", "")
                        val mobile = item.optString("mobile", "")
                        if (normalize10(mobile) == incoming10) {
                            Log.d(TAG, "Hit at src=$source sts=$status page=$page idx=$i")
                            return@withContext Pair(name.ifBlank { "Lead" }, mobile)
                        }
                    }

                    page += 1
                    pageCount += 1

                    if (pageCount % 3 == 0) delay(150) // be gentle to API
                } while (page <= totalPages && pageCount < PER_STATUS_PAGE_LIMIT)
            }
        }

        null
    }

    // --- Save to API (call/lead) ---
    private suspend fun saveToAPI(
        name: String,
        mobile: String,
        whId: String,
        salesId: String,
        authKey: String
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val body = FormBody.Builder()
                .add("action", "save_as_lead")
                .add("wh_id", whId)
                .add("sales_id", salesId)
                .add("api_auth_key", authKey)
                .add("customer_name", name)
                .add("customer_mobile_no", mobile)
                .build()

            val req = Request.Builder()
                .url("$BASE_URL/api/lms/calls.php")
                .post(body)
                .addHeader("Content-Type", "application/x-www-form-urlencoded")
                .addHeader("Cache-Control", "no-cache")
                .build()

            client.newCall(req).execute().use { resp ->
                val bodyStr = resp.body?.string().orEmpty()
                val ok = resp.isSuccessful &&
                        runCatching { JSONObject(bodyStr).optString("status") == "ok" }
                            .getOrDefault(false)
                if (!ok) Log.w(TAG, "API save error: $bodyStr")
                ok
            }
        } catch (e: Exception) {
            Log.e(TAG, "API save exception", e)
            false
        }
    }

    // --- Phonebook utils ---
    private suspend fun saveToPhoneContacts(name: String, mobile: String): Boolean =
        withContext(Dispatchers.IO) {
            try {
                val ops = ArrayList<ContentProviderOperation>()

                ops.add(
                    ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                        .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
                        .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
                        .build()
                )

                ops.add(
                    ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                        .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                        .withValue(
                            ContactsContract.Data.MIMETYPE,
                            ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE
                        )
                        .withValue(
                            ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME,
                            name
                        )
                        .build()
                )

                ops.add(
                    ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                        .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                        .withValue(
                            ContactsContract.Data.MIMETYPE,
                            ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE
                        )
                        .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, mobile)
                        .withValue(
                            ContactsContract.CommonDataKinds.Phone.TYPE,
                            ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE
                        )
                        .build()
                )

                val results = contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
                results.isNotEmpty() && results[0].uri != null
            } catch (e: SecurityException) {
                Log.e(TAG, "WRITE_CONTACTS denied", e); false
            } catch (e: Exception) {
                Log.e(TAG, "Phone save error", e); false
            }
        }

    private fun findExistingContact(phone: String): Pair<String, String>? {
        val norm = normalize10(phone)
        var c: Cursor? = null
        return try {
            c = contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                arrayOf(
                    ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                    ContactsContract.CommonDataKinds.Phone.NUMBER,
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME
                ),
                null, null, null
            )
            c?.use {
                while (it.moveToNext()) {
                    val id = it.getString(0)
                    val num = it.getString(1) ?: continue
                    val name = it.getString(2) ?: "Unknown"
                    if (normalize10(num) == norm) return Pair(id, name)
                }
            }
            null
        } catch (e: SecurityException) {
            Log.e(TAG, "READ_CONTACTS denied", e); null
        } catch (e: Exception) {
            Log.e(TAG, "contact check error", e); null
        } finally {
            c?.close()
        }
    }

    // --- Misc helpers ---
    private fun normalize10(raw: String): String {
        val digits = raw.replace(Regex("[^0-9]"), "")
        return if (digits.length >= 10) digits.takeLast(10) else digits
    }

    private fun showNotification(message: String) {
        createNotificationChannel()
        val n = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Syncing Call Logs")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setSound(null)
            .setVibrate(null)
            .build()
        startForeground(NOTIFICATION_ID, n)
    }

    private fun updateNotification(message: String) {
        val n = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Call Auto-Save")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        (getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
            ?.notify(NOTIFICATION_ID, n)
    }

    private fun showSuccessNotification(message: String, contactName: String) {
        val n = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("✅ Contact Saved")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setDefaults(NotificationCompat.DEFAULT_SOUND or NotificationCompat.DEFAULT_VIBRATE)
            .build()
        (getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
            ?.notify(NOTIFICATION_ID, n)
        Log.d(TAG, "Success notification shown for $contactName")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID,
                "Call Log Sync",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Synchronizes call logs with the server"
                setShowBadge(false)
                enableVibration(false)
                enableLights(false)
                setSound(null, null)
            }
            (getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
                ?.createNotificationChannel(ch)
        }
    }

    private fun stopServiceSafely(startId: Int) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            stopSelf(startId)
        } catch (e: Exception) {
            Log.e(TAG, "stop error", e)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
        Log.d(TAG, "🛑 Service destroyed")
    }

    // Process recent call logs to handle missed calls
    suspend fun processRecentCallLogs(context: Context) = withContext(Dispatchers.IO) {
        Log.d(TAG, "Processing recent call logs...")

        try {
            val cursor = context.contentResolver.query(
                android.provider.CallLog.Calls.CONTENT_URI,
                arrayOf(
                    android.provider.CallLog.Calls.NUMBER,
                    android.provider.CallLog.Calls.DATE,
                    android.provider.CallLog.Calls.TYPE
                ),
                "${android.provider.CallLog.Calls.TYPE} = ? AND ${android.provider.CallLog.Calls.NEW} = ?",
                arrayOf(android.provider.CallLog.Calls.MISSED_TYPE.toString(), "1"),
                "${android.provider.CallLog.Calls.DATE} DESC"
            )

            cursor?.use { c ->
                val numberIdx = c.getColumnIndex(android.provider.CallLog.Calls.NUMBER)
                val dateIdx = c.getColumnIndex(android.provider.CallLog.Calls.DATE)

                while (c.moveToNext()) {
                    val number = c.getString(numberIdx)
                    val timestamp = c.getLong(dateIdx)

                    if (!isDuplicate(number, timestamp)) {
                        Log.d(TAG, "Processing missed call from: $number at $timestamp")
                        handleIncomingCall(number)
                    }
                }
            }

            // Mark all missed calls as processed
            val values = android.content.ContentValues().apply {
                put(android.provider.CallLog.Calls.NEW, 0)
            }

            context.contentResolver.update(
                android.provider.CallLog.Calls.CONTENT_URI,
                values,
                "${android.provider.CallLog.Calls.TYPE} = ? AND ${android.provider.CallLog.Calls.NEW} = ?",
                arrayOf(android.provider.CallLog.Calls.MISSED_TYPE.toString(), "1")
            )

            Log.d(TAG, "Finished processing recent call logs")
        } catch (e: SecurityException) {
            Log.e(TAG, "Permission denied to read call logs", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing call logs", e)
        }
    }
}

// ==================== Extensions ====================

private fun SharedPreferences.getIntCompat(key: String, def: Int): Int {
    val value = all[key] ?: return def
    return when (value) {
        is Int -> value
        is Long -> value.coerceIn(Int.MIN_VALUE.toLong(), Int.MAX_VALUE.toLong()).toInt()
        is String -> value.toIntOrNull() ?: def
        is Number -> value.toInt()
        else -> def
    }
}
