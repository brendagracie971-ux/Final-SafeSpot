package com.example.safespot

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Button
import android.widget.TextView
import android.view.WindowManager
import android.graphics.Color
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ProgressBar

class SOSCancelActivity : Activity() {

    private var secondsLeft = 5
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var countdownText: TextView
    private lateinit var runnable: Runnable

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Show over lock screen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        // Build full screen UI programmatically
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#B00020"))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT
            )
        }

        val sosIcon = TextView(this).apply {
            text = "🚨"
            textSize = 80f
            gravity = Gravity.CENTER
        }

        val titleText = TextView(this).apply {
            text = "SOS ALERT!"
            textSize = 36f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 40, 0, 20)
        }

        val subtitleText = TextView(this).apply {
            text = "Emergency alert will be sent in:"
            textSize = 18f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 20)
        }

        countdownText = TextView(this).apply {
            text = "$secondsLeft"
            textSize = 80f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 40)
        }

        val cancelButton = Button(this).apply {
            text = "❌ CANCEL SOS"
            textSize = 22f
            setTextColor(Color.parseColor("#B00020"))
            setBackgroundColor(Color.WHITE)
            setPadding(60, 30, 60, 30)
            setOnClickListener {
                SOSState.cancelled = true
                handler.removeCallbacks(runnable)
                finish()
            }
        }

        val helpText = TextView(this).apply {
            text = "Press CANCEL if this was accidental"
            textSize = 14f
            setTextColor(Color.parseColor("#FFCCCC"))
            gravity = Gravity.CENTER
            setPadding(0, 30, 0, 0)
        }

        root.addView(sosIcon)
        root.addView(titleText)
        root.addView(subtitleText)
        root.addView(countdownText)
        root.addView(cancelButton)
        root.addView(helpText)
        setContentView(root)

        startCountdown()
    }

    private fun startCountdown() {
        runnable = object : Runnable {
            override fun run() {
                secondsLeft--
                countdownText.text = "$secondsLeft"
                if (secondsLeft <= 0) {
                    finish()
                } else {
                    handler.postDelayed(this, 1000)
                }
            }
        }
        handler.postDelayed(runnable, 1000)
    }

    override fun onDestroy() {
        handler.removeCallbacks(runnable)
        super.onDestroy()
    }
}