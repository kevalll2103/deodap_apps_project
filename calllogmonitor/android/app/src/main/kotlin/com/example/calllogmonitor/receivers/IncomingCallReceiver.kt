package com.example.calllogmonitor.receivers

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.CallLog
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.app.ActivityCompat
import java.util.concurrent.TimeUnit

class IncomingCallReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "IncomingCallReceiver"
        private const val MAX_RECENT_NUMBERS = 30L
        private const val RECENT_NUMBERS_EXPIRE_MINUTES = 15L
        private val MIN_CALL_INTERVAL_MS: Long = TimeUnit.SECONDS.toMillis(30)

        private val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.READ_CALL_LOG,
            Manifest.permission.FOREGROUND_SERVICE,
            Manifest.permission.READ_CONTACTS,
            Manifest.permission.WRITE_CONTACTS
        )

        @Volatile
        private var lastState: String? = null

        @Volatile
        private var lastIncomingNumber: String? = null

        @Volatile
        private var lastCallStartTime: Long = 0

        @Volatile
        private var serviceStartedForThisCall: Boolean = false

        // Thread-safe cache for recently processed numbers
        private val recentNumbers = LinkedHashMap<String, Long>()
        private val lock = Any()

        private fun cleanOldRecentNumbers() {
            val now = System.currentTimeMillis()
            val expirationTime = now - TimeUnit.MINUTES.toMillis(RECENT_NUMBERS_EXPIRE_MINUTES)
            
            synchronized(lock) {
                val iterator = recentNumbers.iterator()
                while (iterator.hasNext()) {
                    val (number, timestamp) = iterator.next()
                    if (timestamp < expirationTime) {
                        iterator.remove()
                        Log.d(TAG, "🧹 Removed expired number from cache: $number")
                    }
                }
            }
        }

        private fun isRecentlyProcessed(number: String): Boolean {
            cleanOldRecentNumbers()
            return synchronized(lock) {
                val lastProcessed = recentNumbers[number] ?: return@synchronized false
                val now = System.currentTimeMillis()
                val timeSinceLastProcessed = now - lastProcessed
                
                if (timeSinceLastProcessed < MIN_CALL_INTERVAL_MS) {
                    Log.d(TAG, "⏭️ Recently processed: $number (${timeSinceLastProcessed/1000}s ago)")
                    true
                } else {
                    false
                }
            }
        }

        private fun markAsProcessed(number: String) {
            synchronized(lock) {
                recentNumbers[number] = System.currentTimeMillis()
                // Maintain size limit
                if (recentNumbers.size > MAX_RECENT_NUMBERS) {
                    val oldest = recentNumbers.entries.minByOrNull { it.value }
                    oldest?.let { recentNumbers.remove(it.key) }
                }
            }
        }
    }

    private fun startHandlerService(context: Context, number: String, reason: String) {
        if (number.isBlank()) {
            Log.d(TAG, "⚠️ Empty number, cannot start service")
            return
        }

        if (isRecentlyProcessed(number)) {
            Log.d(TAG, "⏭️ Recently processed, skipping: $number")
            return
        }

        // Reset service flag if it's been a while since the last call
        if (serviceStartedForThisCall && 
            System.currentTimeMillis() - lastCallStartTime > TimeUnit.MINUTES.toMillis(5)) {
            serviceStartedForThisCall = false
        }

        if (serviceStartedForThisCall) {
            Log.d(TAG, "⏭️ Service already started; skipping ($reason)")
            return
        }

        Log.d(TAG, "🚀 Starting IncomingCallHandlerService ($reason) for: $number")

        try {
            val serviceIntent = Intent(context, IncomingCallHandlerService::class.java).apply {
                putExtra("PHONE_NUMBER", number)
                putExtra("TIMESTAMP", System.currentTimeMillis())
                action = "${context.packageName}.action.HANDLE_CALL"
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }

            markAsProcessed(number)
            serviceStartedForThisCall = true
            lastCallStartTime = System.currentTimeMillis()
            Log.d(TAG, "✅ IncomingCallHandlerService started successfully")
        } catch (e: SecurityException) {
            Log.e(TAG, "🔒 SecurityException: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start IncomingCallHandlerService", e)
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) {
            Log.e(TAG, "❌ Context or intent is null")
            return
        }

        val action = intent.action ?: return
        
        if (action != TelephonyManager.ACTION_PHONE_STATE_CHANGED && 
            action != "android.intent.action.NEW_OUTGOING_CALL") {
            return
        }
        
        Log.d(TAG, "════════════════════════════════════════")
        Log.d(TAG, "🔔 BROADCAST RECEIVED - Action: $action")

        val state = if (action == "android.intent.action.NEW_OUTGOING_CALL") {
            // Handle outgoing call
            val number = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
            if (!number.isNullOrBlank()) {
                lastIncomingNumber = number
                Log.d(TAG, "📤 OUTGOING CALL to: $number")
                TelephonyManager.EXTRA_STATE_OFFHOOK
            } else {
                return
            }
        } else {
            intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        }

        Log.d(TAG, "State: $state")
        Log.d(TAG, "Last state: $lastState, Last number: $lastIncomingNumber")

        // Check permissions
        val missingPermissions = REQUIRED_PERMISSIONS.filter {
            ActivityCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missingPermissions.isNotEmpty()) {
            Log.w(TAG, "⚠️ Missing permissions: $missingPermissions")
            return
        }

        var incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        Log.d(TAG, "Number from broadcast: ${incomingNumber ?: "(empty)"}")

        // Normalize the incoming number
        val normalizedNumber = (incomingNumber ?: lastIncomingNumber)?.trim() ?: ""

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                Log.d(TAG, "📞 RINGING state")
                if (normalizedNumber.isNotBlank()) {
                    lastIncomingNumber = normalizedNumber
                    startHandlerService(context, normalizedNumber, "RINGING")
                } else {
                    Log.w(TAG, "⚠️ RINGING but number is null or blank")
                }
                lastState = state
            }

            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                Log.d(TAG, "📞 CALL_OFFHOOK state")
                val numberToProcess = if (normalizedNumber.isNotBlank()) normalizedNumber else lastIncomingNumber
                if (numberToProcess != null) {
                    startHandlerService(context, numberToProcess, "OFFHOOK")
                }
                lastState = state
            }

            TelephonyManager.EXTRA_STATE_IDLE -> {
                Log.d(TAG, "📵 CALL_IDLE state")
                // Only process if coming from an OFFHOOK state (completed call)
                if (lastState == TelephonyManager.EXTRA_STATE_OFFHOOK || 
                    lastState == TelephonyManager.EXTRA_STATE_RINGING) {
                    
                    val numberToProcess = if (normalizedNumber.isNotBlank()) {
                        normalizedNumber
                    } else {
                        // Fallback to last known number if available
                        lastIncomingNumber.takeIf { it?.isNotBlank() == true } ?: return
                    }

                    // Check call log for the most recent call if we don't have a number
                    if (normalizedNumber.isBlank() && 
                        ActivityCompat.checkSelfPermission(
                            context,
                            Manifest.permission.READ_CALL_LOG
                        ) == PackageManager.PERMISSION_GRANTED) {

                        try {
                            val cursor = context.contentResolver.query(
                                CallLog.Calls.CONTENT_URI,
                                arrayOf(
                                    CallLog.Calls.NUMBER,
                                    CallLog.Calls.TYPE,
                                    CallLog.Calls.DATE
                                ),
                                "${CallLog.Calls.DATE} > ? AND ${CallLog.Calls.TYPE} IN (?, ?)",
                                arrayOf(
                                    (System.currentTimeMillis() - 60000).toString(),
                                    CallLog.Calls.INCOMING_TYPE.toString(),
                                    CallLog.Calls.MISSED_TYPE.toString()
                                ),
                                "${CallLog.Calls.DATE} DESC LIMIT 1"
                            )

                            cursor?.use {
                                if (it.moveToFirst()) {
                                    val number = it.getString(0) ?: ""
                                    if (number.isNotBlank()) {
                                        Log.d(TAG, "📒 Found in call log: $number")
                                        startHandlerService(context, number, "IDLE (call log fallback)")
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ CallLog query failed", e)
                        }
                    } else if (numberToProcess.isNotBlank()) {
                        startHandlerService(context, numberToProcess, "IDLE")
                    }
                }

                // Reset for next call
                lastState = state
                lastIncomingNumber = null
                serviceStartedForThisCall = false
            }
        }

        Log.d(TAG, "════════════════════════════════════════")
    }
}