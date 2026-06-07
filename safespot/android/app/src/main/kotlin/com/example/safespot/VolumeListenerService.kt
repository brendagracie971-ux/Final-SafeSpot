package com.example.safespot

import android.app.*
import android.content.*
import android.content.pm.ServiceInfo
import android.database.ContentObserver
import android.location.LocationManager
import android.media.*
import android.media.session.*
import android.net.Uri
import android.os.*
import android.provider.Settings
import android.telephony.SmsManager
import android.util.Log
import android.view.KeyEvent
import androidx.core.app.NotificationCompat

class VolumeListenerService : Service() {

    private var volumePressCount = 0
    private var lastPressTime = 0L
    private lateinit var mediaSession: MediaSession
    private lateinit var sosReceiver: BroadcastReceiver
    private lateinit var audioManager: AudioManager
    private lateinit var contentObserver: ContentObserver
    private var lastVolume = 0
    private val handler = Handler(Looper.getMainLooper())

    companion object {
        const val TAG = "SafeSpotSOS"
        const val CHANNEL_ID = "sos_service_channel"
        const val NOTIF_ID = 101
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate")
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        lastVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        createNotificationChannel()
        startForegroundWithNotification("SOS trigger is monitoring 🟢")
        setupMediaSession()
        registerVolumeObserver()
        registerSosReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand")
        createNotificationChannel()
        startForegroundWithNotification("SOS trigger is monitoring 🟢")
        return START_STICKY
    }

    private fun registerVolumeObserver() {
        contentObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) {
                checkVolumeChange()
            }
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                checkVolumeChange()
            }
        }
        contentResolver.registerContentObserver(
            Settings.System.CONTENT_URI, true, contentObserver
        )
        contentResolver.registerContentObserver(
            Uri.parse("content://settings/system/volume_music"),
            true, contentObserver
        )
        Log.d(TAG, "Volume observer registered")
    }

    private fun checkVolumeChange() {
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        if (currentVolume > lastVolume) {
            Log.d(TAG, "Volume UP detected in background!")
            handleVolumeUp()
        }
        lastVolume = currentVolume
    }

    private fun registerSosReceiver() {
        sosReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == "com.example.safespot.TRIGGER_SOS") {
                    Log.d(TAG, "SOS broadcast received!")
                    updateNotification("🚨 SOS ALERT SENT!")
                    Thread { triggerSOS() }.start()
                }
            }
        }
        val filter = IntentFilter("com.example.safespot.TRIGGER_SOS")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(sosReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(sosReceiver, filter)
        }
        Log.d(TAG, "SOS broadcast receiver registered")
    }

    private fun setupMediaSession() {
        mediaSession = MediaSession(this, "SafeSpotSOS")
        mediaSession.setCallback(object : MediaSession.Callback() {
            override fun onMediaButtonEvent(mediaButtonEvent: Intent): Boolean {
                val event = mediaButtonEvent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
                if (event?.action == KeyEvent.ACTION_DOWN) {
                    if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
                        Log.d(TAG, "VOLUME UP via MediaSession!")
                        handleVolumeUp()
                    }
                }
                return true
            }
        })
        mediaSession.setFlags(
            MediaSession.FLAG_HANDLES_MEDIA_BUTTONS or
            MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS
        )
        val stateBuilder = PlaybackState.Builder()
            .setActions(PlaybackState.ACTION_PLAY)
            .setState(PlaybackState.STATE_PLAYING, 0L, 1.0f)
        mediaSession.setPlaybackState(stateBuilder.build())
        mediaSession.isActive = true
        Log.d(TAG, "MediaSession activated")
    }

    private fun handleVolumeUp() {
        val now = System.currentTimeMillis()
        if (now - lastPressTime > 2000) {
            volumePressCount = 0
        }
        volumePressCount++
        lastPressTime = now
        Log.d(TAG, "Count: $volumePressCount/3")
        updateNotification("🔴 Press volume up ${3 - volumePressCount} more time(s)!")
        if (volumePressCount >= 3) {
            volumePressCount = 0
            updateNotification("🚨 SOS TRIGGERED!")

            // Launch cancel screen first
            val cancelIntent = Intent(applicationContext, SOSCancelActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            applicationContext.startActivity(cancelIntent)

            // Wait 5 seconds then send if not cancelled
            handler.postDelayed({
                if (!SOSState.cancelled) {
                    Thread { triggerSOS() }.start()
                } else {
                    updateNotification("✅ SOS Cancelled")
                    SOSState.cancelled = false
                }
            }, 5000)
        }
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID, "SafeSpot SOS",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            enableVibration(false)
            setSound(null, null)
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private fun buildNotification(text: String): Notification {
        val dismissIntent = Intent("com.example.safespot.NOTIFICATION_DISMISSED")
        val dismissPendingIntent = PendingIntent.getBroadcast(
            this, 0, dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SafeSpot Active 🛡️")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDeleteIntent(dismissPendingIntent)
            .build()
    }

    private fun startForegroundWithNotification(text: String) {
        val notification = buildNotification(text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIF_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun updateNotification(text: String) {
        getSystemService(NotificationManager::class.java)
            .notify(NOTIF_ID, buildNotification(text))
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

    private fun buildSOSMessage(
        name: String, age: String, phone: String,
        blood: String, medical: String, locationText: String
    ): String {
        return "🚨 SOS ALERT - EMERGENCY!\n" +
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
    }

    private fun triggerSOS() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)

        val contactsJson = prefs.getString("flutter.sos_contacts", "")
        Log.d(TAG, "Contacts: $contactsJson")
        if (contactsJson.isNullOrBlank()) {
            updateNotification("⚠️ SOS failed: No contacts saved!")
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

        // Get location
        val locationText = try {
            val locationManager = getSystemService(LocationManager::class.java)
            val providers = locationManager.getProviders(true)
            var bestLocation: android.location.Location? = null
            for (provider in providers) {
                val loc = locationManager.getLastKnownLocation(provider) ?: continue
                if (bestLocation == null || loc.accuracy < bestLocation.accuracy) {
                    bestLocation = loc
                }
            }
            if (bestLocation != null) {
                "https://maps.google.com/?q=${bestLocation.latitude},${bestLocation.longitude}"
            } else {
                "Location unavailable - please call me!"
            }
        } catch (e: Exception) {
            "Location unavailable - please call me!"
        }

        val message = buildSOSMessage(name, age, phone, blood, medical, locationText)

        Log.d(TAG, "SOS Message built")
        Log.d(TAG, "Sending to: $numbers")

        val online = isOnline()

        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            applicationContext.getSystemService(SmsManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            SmsManager.getDefault()
        }

        for (number in numbers) {
            // Always send SMS
            try {
                val parts = smsManager.divideMessage(message)
                smsManager.sendMultipartTextMessage(
                    number.trim(), null, parts, null, null
                )
                Log.d(TAG, "✅ SMS sent to: $number")
            } catch (e: Exception) {
                Log.e(TAG, "❌ SMS failed to $number: ${e.message}")
            }

            // Send WhatsApp if online
            if (online) {
                handler.post {
                    try {
                        val cleaned = cleanNumber(number)

                        // Send photo link first if available
                        if (photoUrl.isNotEmpty()) {
                            val photoMessage = "📸 Photo of person in emergency: $photoUrl\n\n$message"
                            val photoUri = Uri.parse(
                                "whatsapp://send?phone=$cleaned&text=${Uri.encode(photoMessage)}"
                            )
                            val photoIntent = Intent(Intent.ACTION_VIEW, photoUri).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            try {
                                applicationContext.startActivity(photoIntent)
                                Log.d(TAG, "✅ WhatsApp with photo sent to: $number")
                            } catch (e: Exception) {
                                // Fallback without photo
                                val uri = Uri.parse(
                                    "whatsapp://send?phone=$cleaned&text=${Uri.encode(message)}"
                                )
                                val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                applicationContext.startActivity(intent)
                                Log.d(TAG, "✅ WhatsApp sent to: $number")
                            }
                        } else {
                            val uri = Uri.parse(
                                "whatsapp://send?phone=$cleaned&text=${Uri.encode(message)}"
                            )
                            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            applicationContext.startActivity(intent)
                            Log.d(TAG, "✅ WhatsApp sent to: $number")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ WhatsApp failed for $number: ${e.message}")
                    }
                }
                // Small delay between contacts
                Thread.sleep(2000)
            }
        }

        val method = if (online) "SMS + WhatsApp" else "SMS"
        handler.post {
            updateNotification("✅ SOS sent via $method to ${numbers.size} contact(s)!")
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "Service destroyed — restarting")
        unregisterReceiver(sosReceiver)
        contentResolver.unregisterContentObserver(contentObserver)
        mediaSession.isActive = false
        mediaSession.release()
        val restartIntent = Intent(applicationContext, VolumeListenerService::class.java)
        applicationContext.startForegroundService(restartIntent)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?) = null
}