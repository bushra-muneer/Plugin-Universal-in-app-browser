package com.bushra.plugin_universal_in_app_browser

import android.app.Activity
import android.app.Application
import android.net.Uri
import android.os.SystemClock
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class PluginUniversalInAppBrowserPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var currentRequestId: Int = 0

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "openUrl" -> handleOpenUrl(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleOpenUrl(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
        if (url.isNullOrBlank()) {
            result.error("argument_error", "A non-empty url is required.", null)
            return
        }

        val options = call.argument<HashMap<String, Any?>>("options") ?: hashMapOf()
        val showTitle = options["showTitle"] as? Boolean ?: true
        val toolbarColorValue = (options["toolbarColor"] as? Number)?.toInt()

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("unavailable", "No foreground activity to present the browser.", null)
            return
        }

        // launch our wrapper activity for a reliable dismissal callback
        try {
            val intent = android.content.Intent(currentActivity, WrapperCustomTabActivity::class.java)
            intent.putExtra(WrapperCustomTabActivity.EXTRA_URL, url)
            toolbarColorValue?.let { intent.putExtra(WrapperCustomTabActivity.EXTRA_TOOLBAR_COLOR, it) }
            intent.putExtra(WrapperCustomTabActivity.EXTRA_SHOW_TITLE, showTitle)

            val binding = activityBinding
            if (binding == null) {
                result.error("unavailable", "No activity binding available to start wrapper activity.", null)
                return
            }

            channel.invokeMethod("onOpened", mapOf("url" to url))

            val requestId = ++currentRequestId
            binding.addActivityResultListener { requestCode, resultCode, data ->
                if (requestCode == requestId) {
                    if (resultCode == Activity.RESULT_OK) {
                        channel.invokeMethod("onDismissed", mapOf("url" to url))
                    } else {
                        // treated as dismissed or cancelled
                        channel.invokeMethod("onDismissed", mapOf("url" to url))
                    }
                    true
                } else {
                    false
                }
            }

            // Use the Activity API to start for result; ActivityPluginBinding's
            // startActivityForResult signatures differ between embedding versions.
            // Calling Activity.startActivityForResult keeps compatibility here.
            currentActivity.startActivityForResult(intent, requestId)
            result.success(null)
        } catch (error: Throwable) {
            channel.invokeMethod("onError", mapOf("message" to (error.message ?: "unknown")))
            result.error("launch_failed", error.message, null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        activityBinding = null
    }

    override fun onDetachedFromActivity() {
        activity = null
        activityBinding = null
    }

    companion object {
        private const val CHANNEL_NAME = "plugin_universal_in_app_browser"
    }
}
