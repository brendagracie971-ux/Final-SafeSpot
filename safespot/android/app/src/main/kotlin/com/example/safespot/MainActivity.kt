package com.example.safespot

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.telephony.SmsManager
import android.util.Log
import android.view.KeyEvent
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var volumePressCount = 0
    private var lastPressTime = 0L
    private var isSosSending = false
    private val sosHandler = Handler(Looper.getMainLooper())
    private var sosRunnable: Runnable? = null

    companion object {
        const val TAG = "SafeSpotSOS"
        const val CANCEL_CHANNEL_ID = "sos_cancel_channel"
        const val CANCEL_NOTIF_ID = 202
        const val ACTION_CANCEL_SOS = "com.example.safespot.CANCEL_SOS"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.safespot/sos_service"
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "startService" -> {
                    try {
                        val intent = Intent(this, VolumeListenerService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }

                "sendSOS" -> {
                    val numbers = call.argument<List<String>>("numbers") ?: emptyList()
                    val message = call.argument<String>("message") ?: ""
                    Thread {
                        sendSMSToAll(numbers, message)
                        Handler(Looper.getMainLooper()).post {
                            sendWhatsAppToAll(numbers, message)
                            result.success(null)
                        }
                    }.start()
                }

                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            val now = System.currentTimeMillis()
            if (now - lastPressTime > 2000) {
                volumePressCount = 0
            }
            volumePressCount++
            lastPressTime = now
            Log.d(TAG, "Volume UP! Count: $volumePressCount/3")

            if (volumePressCount >= 3) {
                volumePressCount = 0
                if (!isSosSending) {
                    Log.d(TAG, "🚨 SOS countdown started!")
                    startSOSCountdown()
                }
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun startSOSCountdown() {
        SOSState.cancelled = false
        isSosSending = true

        val cancelIntent = Intent(this, SOSCancelActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(cancelIntent)

        sosRunnable = Runnable {
            if (!SOSState.cancelled) {
                Log.d(TAG, "🚨 SOS sending now!")
                Thread { sendSOSDirectly() }.start()
            } else {
                Log.d(TAG, "✅ SOS cancelled by user")
                isSosSending = false
            }
        }
        sosHandler.postDelayed(sosRunnable!!, 5000)
    }

    private fun showCancelNotification() {
        val channel = NotificationChannel(
            CANCEL_CHANNEL_ID,
            "SOS Cancel",
            NotificationManager.IMPORTANCE_HIGH
        )
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)

        val cancelIntent = Intent(ACTION_CANCEL_SOS).apply {
            setClass(this@MainActivity, SOSCancelReceiver::class.java)
        }
        val cancelPendingIntent = PendingIntent.getBroadcast(
            this, 0, cancelIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CANCEL_CHANNEL_ID)
            .setContentTitle("🚨 SOS Alert in 5 seconds!")
            .setContentText("Tap CANCEL if this was accidental")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setAutoCancel(false)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_delete,
                "❌ CANCEL SOS",
                cancelPendingIntent
            )
            .build()

        getSystemService(NotificationManager::class.java)
            .notify(CANCEL_NOTIF_ID, notification)
    }

    private fun dismissCancelNotification() {
        getSystemService(NotificationManager::class.java)
            .cancel(CANCEL_NOTIF_ID)
    }

    fun cancelSOS() {
        SOSState.cancelled = true
        sosRunnable?.let { sosHandler.removeCallbacks(it) }
        dismissCancelNotification()
        isSosSending = false
        Log.d(TAG, "✅ SOS cancelled!")

        val channel = NotificationChannel(
            CANCEL_CHANNEL_ID, "SOS Cancel",
            NotificationManager.IMPORTANCE_DEFAULT
        )
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(this, CANCEL_CHANNEL_ID)
            .setContentTitle("✅ SOS Cancelled")
            .setContentText("Your SOS alert was cancelled successfully")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        getSystemService(NotificationManager::class.java)
            .notify(CANCEL_NOTIF_ID, notification)

        Handler(Looper.getMainLooper()).postDelayed({
            getSystemService(NotificationManager::class.java)
                .cancel(CANCEL_NOTIF_ID)
        }, 3000)
    }

    private fun sendSOSDirectly() {
        Log.d(TAG, "sendSOSDirectly() called")
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val contactsJson = prefs.getString("flutter.sos_contacts", "")

            if (contactsJson.isNullOrBlank()) {
                Log.e(TAG, "❌ No contacts found!")
                isSosSending = false
                return
            }

            val numbers = contactsJson.split(",").filter { it.isNotBlank() }

            // Get all personal info
            val name = prefs.getString("flutter.sos_user_name", "Unknown") ?: "Unknown"
            val phone = prefs.getString("flutter.sos_user_phone", "Unknown") ?: "Unknown"
            val blood = prefs.getString("flutter.sos_user_blood", "Unknown") ?: "Unknown"
            val age = prefs.getString("flutter.sos_user_age", "Unknown") ?: "Unknown"
            val medical = prefs.getString("flutter.sos_user_medical", "None") ?: "None"
            val photoUrl = prefs.getString("flutter.sos_user_photo", "") ?: ""

            val location = getLocationFast()
            val locationText = if (location != null) {
                "https://maps.google.com/?q=${location.first},${location.second}"
            } else {
                "Location unavailable - please call me!"
            }

            val message =
                "🚨 SOS ALERT - EMERGENCY!\n" + 
                "👤 Name: $name\n" +
                "🎂 Age: $age\n" +
                "📞 Phone: $phone\n" +
                "🩸 Blood Group: $blood\n" +
                "🏥 Medical Notes: $medical\n" +
                "📍 Live Location:\n$locationText\n" +
                "⚠️ Please help immediately!"

            Log.d(TAG, "Sending to: $numbers")

            // Always send SMS to all
            sendSMSToAll(numbers, message)

            // Send WhatsApp to all if online
            if (isOnline()) {
                val fullMessage = if (photoUrl.isNotEmpty()) {
                    "📸 Photo: $photoUrl\n\n$message"
                } else {
                    message
                }
                Handler(Looper.getMainLooper()).post {
                    sendWhatsAppToAll(numbers, fullMessage)
                }
            }

            // Notify service to update notification
            Handler(Looper.getMainLooper()).post {
                val sosIntent = Intent("com.example.safespot.TRIGGER_SOS")
                sendBroadcast(sosIntent)
            }

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error: ${e.message}")
        }

        Handler(Looper.getMainLooper()).postDelayed({
            isSosSending = false
            Log.d(TAG, "SOS ready to send again")
        }, 5000)
    }

    private fun sendSMSToAll(numbers: List<String>, message: String) {
        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            applicationContext.getSystemService(SmsManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            SmsManager.getDefault()
        }
        for (number in numbers) {
            try {
                val parts = smsManager.divideMessage(message)
                smsManager.sendMultipartTextMessage(
                    number.trim(), null, parts, null, null
                )
                Log.d(TAG, "✅ SMS sent to: $number")
            } catch (e: Exception) {
                Log.e(TAG, "❌ SMS failed to $number: ${e.message}")
            }
        }
    }

    private fun sendWhatsAppToAll(numbers: List<String>, message: String) {
        for (number in numbers) {
            try {
                val cleaned = cleanNumber(number)
                val whatsappUri = Uri.parse(
                    "whatsapp://send?phone=$cleaned&text=${Uri.encode(message)}"
                )
                val whatsappIntent = Intent(Intent.ACTION_VIEW, whatsappUri).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                applicationContext.startActivity(whatsappIntent)
                Log.d(TAG, "✅ WhatsApp sent to: $number")
                Thread.sleep(2000)
            } catch (e: Exception) {
                try {
                    val cleaned = cleanNumber(number)
                    val uri = Uri.parse(
                        "https://wa.me/$cleaned?text=${Uri.encode(message)}"
                    )
                    val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        setPackage("com.whatsapp")
                    }
                    applicationContext.startActivity(intent)
                    Log.d(TAG, "✅ WhatsApp fallback sent to: $number")
                    Thread.sleep(2000)
                } catch (e2: Exception) {
                    Log.e(TAG, "❌ WhatsApp failed for $number: ${e2.message}")
                }
            }
        }
    }

    private fun cleanNumber(number: String): String {
        var cleaned = number.replace(Regex("[\\s\\-\\(\\)]"), "")
        if (cleaned.startsWith("0")) {
            cleaned = "237${cleaned.substring(1)}"
        }
        if (!cleaned.startsWith("+") && !cleaned.startsWith("237")) {
            cleaned = "237$cleaned"
        }
        cleaned = cleaned.replace("+", "")
        return cleaned
    }

    private fun isOnline(): Boolean {
        return try {
            val cm = getSystemService(android.net.ConnectivityManager::class.java)
            val network = cm.activeNetworkInfo
            network != null && network.isConnected
        } catch (e: Exception) {
            false
        }
    }

    private fun getLocationFast(): Pair<Double, Double>? {
        return try {
            val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
            val providers = locationManager.getProviders(true)
            var bestLat = 0.0
            var bestLng = 0.0
            var bestAccuracy = Float.MAX_VALUE
            var found = false
            for (provider in providers) {
                val loc = locationManager.getLastKnownLocation(provider) ?: continue
                if (loc.accuracy < bestAccuracy) {
                    bestAccuracy = loc.accuracy
                    bestLat = loc.latitude
                    bestLng = loc.longitude
                    found = true
                }
            }
            if (found) Pair(bestLat, bestLng) else null
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission denied")
            null
        }
    }
}