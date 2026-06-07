package com.example.safespot

import android.content.*
import android.os.Build

class NotificationDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.example.safespot.NOTIFICATION_DISMISSED") {
            // Restart the service immediately when notification is dismissed
            val serviceIntent = Intent(context, VolumeListenerService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}