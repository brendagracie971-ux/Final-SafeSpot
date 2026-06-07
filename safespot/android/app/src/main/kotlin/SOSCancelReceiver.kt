package com.example.safespot

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class SOSCancelReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == MainActivity.ACTION_CANCEL_SOS) {
            Log.d("SafeSpotSOS", "Cancel SOS received!")
            // We use a static flag to communicate with MainActivity
            SOSState.cancelled = true
        }
    }
}