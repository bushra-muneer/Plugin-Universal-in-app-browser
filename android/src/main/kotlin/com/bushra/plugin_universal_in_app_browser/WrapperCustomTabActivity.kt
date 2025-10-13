package com.bushra.plugin_universal_in_app_browser

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.SystemClock
import androidx.browser.customtabs.CustomTabsIntent

class WrapperCustomTabActivity : Activity() {
    private var launchedAt: Long = 0L
    private var didLaunch: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val url = intent?.getStringExtra(EXTRA_URL)
        val toolbarColor = intent?.getIntExtra(EXTRA_TOOLBAR_COLOR, 0)
        val showTitle = intent?.getBooleanExtra(EXTRA_SHOW_TITLE, true) ?: true

        if (url.isNullOrEmpty()) {
            setResult(RESULT_CANCELED)
            finish()
            return
        }

        try {
            val builder = CustomTabsIntent.Builder()
            builder.setShowTitle(showTitle)
            if (toolbarColor != null && toolbarColor != 0) {
                builder.setToolbarColor(toolbarColor)
            }
            val customTabsIntent = builder.build()
            customTabsIntent.intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            customTabsIntent.launchUrl(this, Uri.parse(url))
            didLaunch = true
            launchedAt = SystemClock.uptimeMillis()
        } catch (e: Throwable) {
            setResult(RESULT_CANCELED)
            finish()
        }
    }

    override fun onResume() {
        super.onResume()
        if (didLaunch) {
            val now = SystemClock.uptimeMillis()
            // If enough time has passed since launch, assume we're returning from the custom tab
            if (now - launchedAt > 300) {
                setResult(RESULT_OK)
                finish()
            }
        }
    }

    companion object {
        const val EXTRA_URL = "extra_url"
        const val EXTRA_TOOLBAR_COLOR = "extra_toolbar_color"
        const val EXTRA_SHOW_TITLE = "extra_show_title"
    }
}
