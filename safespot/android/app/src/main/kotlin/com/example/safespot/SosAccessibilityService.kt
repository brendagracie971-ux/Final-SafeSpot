package com.example.safespot

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.telephony.SmsManager
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import android.location.LocationManager
import android.net.Uri
import android.os.Build

class SosAccessibilityService : AccessibilityService() {

    private var volumePressCount = 0
    private var lastPressTime = 0L
    private var isSosSending = false
    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        const val TAG = "SafeSpotSOS"
        var isRunning = false
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isRunning = true
        Log.d(TAG, "✅ Accessibility Service connected")

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS
            notificationTimeout = 100
        }
        serviceInfo = info

        // Acquire wake lock to keep CPU alive when screen is off
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "SafeSpot::SOSWakeLock"
        )
        wakeLock?.acquire(10 * 60 * 1000L) // 10 minutes max
        Log.d(TAG, "✅ WakeLock acquired")
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP &&
            event.action == KeyEvent.ACTION_DOWN) {

            val now = System.currentTimeMillis()
            if (now - lastPressTime > 2000) {
                volumePressCount = 0
            }
            volumePressCount++
            lastPressTime = now

            Log.d(TAG, "🔊 Volume UP (screen off)! Count: $volumePressCount/3")

            if (volumePressCount >= 3) {
                volumePressCount = 0
                if (!isSosSending) {
                    Log.d(TAG, "🚨 SOS TRIGGERED from Accessibility Service!")

                    // Re-acquire wake lock before sending
                    if (wakeLock?.isHeld == false) {
                        wakeLock?.acquire(5 * 60 * 1000L)
                    }

                    // Launch cancel screen
                    val cancelIntent = Intent(
                        applicationContext,
                        SOSCancelActivity::class.java
                    ).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(cancelIntent)

                    // Send SOS after 5 second countdown
                    handler.postDelayed({
                        if (!SOSState.cancelled) {
                            Thread { sendSOSFromService() }.start()
                        } else {
                            SOSState.cancelled = false
                            isSosSending = false
                        }
                    }, 5000)
                }
            }

            // Return false to allow volume to still change normally
            return false
        }
        return false
    }

    private fun sendSOSFromService() {
        isSosSending = true
        Log.d(TAG, "sendSOSFromService() called")

        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val contactsJson = prefs.getString("flutter.sos_contacts", "")

            if (contactsJson.isNullOrBlank()) {
                Log.e(TAG, "❌ No contacts found!")
                isSosSending = false
                return
            }

            val numbers = contactsJson.split(",").filter { it.isNotBlank() }
            val name = prefs.getString("flutter.sos_user_name", "Unknown") ?: "Unknown"
            val phone = prefs.getString("flutter.sos_user_phone", "Unknown") ?: "Unknown"
            val blood = prefs.getString("flutter.sos_user_blood", "Unknown") ?: "Unknown"
            val age = prefs.getString("flutter.sos_user_age", "Unknown") ?: "Unknown"
            val medical = prefs.getString("flutter.sos_user_medical", "None") ?: "None"
            val photoUrl = prefs.getString("flutter.sos_user_photo", "") ?: ""

            val locationText = getLocationText()

            val message =
                "🚨 SOS ALERT - EMERGENCY!\n" +
                "━━━━━━━━━━━━━━━━━━━━\n" +
                "👤 Name: $name\n" +
                "🎂 Age: $age\n" +
                "📞 Phone: $phone\n" +
                "🩸 Blood Group: $blood\n" +
                "🏥 Medical Notes: $medical\n" +
                "━━━━━━━━━━━━━━━━━━━━\n" +
                "📍 Live Location:\n$locationText\n" +
                "━━━━━━━━━━━━━━━━━━━━\n" +
                "⚠️ Please help immediately!"

            Log.d(TAG, "Sending to: $numbers")

            // Send SMS to all
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

            // Send WhatsApp if online
            if (isOnline()) {
                handler.post {
                    for (number in numbers) {
                        try {
                            val cleaned = cleanNumber(number)
                            val fullMessage = if (photoUrl.isNotEmpty()) {
                                "📸 Photo: $photoUrl\n\n$message"
                            } else message

                            val uri = Uri.parse(
                                "whatsapp://send?phone=$cleaned&text=${Uri.encode(fullMessage)}"
                            )
                            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            applicationContext.startActivity(intent)
                            Log.d(TAG, "✅ WhatsApp sent to: $number")
                            Thread.sleep(2000)
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ WhatsApp failed: ${e.message}")
                        }
                    }
                }
            }

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error: ${e.message}")
        }

        handler.postDelayed({
            isSosSending = false
            Log.d(TAG, "SOS ready to send again")
        }, 5000)
    }

    private fun getLocationText(): String {
        return try {
            val lm = getSystemService(LOCATION_SERVICE) as LocationManager
            val providers = lm.getProviders(true)
            var best: android.location.Location? = null
            for (p in providers) {
                val loc = lm.getLastKnownLocation(p) ?: continue
                if (best == null || loc.accuracy < best.accuracy) best = loc
            }
            if (best != null) {
                "https://maps.google.com/?q=${best.latitude},${best.longitude}"
            } else {
                "Location unavailable - please call me!"
            }
        } catch (e: Exception) {
            "Location unavailable - please call me!"
        }
    }

    private fun cleanNumber(number: String): String {
        var cleaned = number.replace(Regex("[\\s\\-\\(\\)]"), "")
        if (cleaned.startsWith("0")) cleaned = "237${cleaned.substring(1)}"
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

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {
        Log.d(TAG, "Accessibility service interrupted")
    }

    override fun onDestroy() {
        isRunning = false
        wakeLock?.release()
        super.onDestroy()
    }
}