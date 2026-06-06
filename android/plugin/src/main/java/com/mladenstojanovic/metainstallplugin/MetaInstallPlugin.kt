package com.mladenstojanovic.metainstallplugin

import android.app.Application
import android.os.Bundle
import android.util.Log
import com.facebook.FacebookSdk
import com.facebook.LoggingBehavior
import com.facebook.appevents.AppEventsLogger
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

class MetaInstallPlugin(godot: Godot) : GodotPlugin(godot) {

	private val logTag = "MetaInstallPlugin"
	private var initialized = false
	private var advertiserIdCollectionEnabled = true

	override fun getPluginName(): String = PLUGIN_NAME

	@UsedByGodot
	fun initialize(
		app_id: String,
		client_token: String,
		display_name: String,
		advertiser_id_collection: Boolean = true
	): Int {
		if (initialized) {
			Log.d(logTag, "initialize() called again; already initialized.")
			return OK
		}

		val application = activity?.application
		if (application == null) {
			Log.e(logTag, "initialize() failed: application was null.")
			return ERR_UNAVAILABLE
		}

		if (app_id.isBlank()) {
			Log.e(logTag, "initialize() failed: app_id was blank.")
			return ERR_INVALID_PARAMETER
		}

		if (client_token.isBlank()) {
			Log.e(logTag, "initialize() failed: client_token was blank.")
			return ERR_INVALID_PARAMETER
		}

		advertiserIdCollectionEnabled = advertiser_id_collection

		FacebookSdk.setApplicationId(app_id)
		FacebookSdk.setClientToken(client_token)
		FacebookSdk.setApplicationName(display_name)
		FacebookSdk.setAutoInitEnabled(false)
		FacebookSdk.sdkInitialize(application.applicationContext)
		FacebookSdk.fullyInitialize()
		FacebookSdk.setAutoLogAppEventsEnabled(true)
		FacebookSdk.setAdvertiserIDCollectionEnabled(advertiserIdCollectionEnabled)

		if (BuildConfig.META_DEBUG_LOGGING) {
			FacebookSdk.addLoggingBehavior(LoggingBehavior.APP_EVENTS)
			FacebookSdk.addLoggingBehavior(LoggingBehavior.REQUESTS)
			FacebookSdk.addLoggingBehavior(LoggingBehavior.DEVELOPER_ERRORS)
		}

		AppEventsLogger.activateApp(application)
		initialized = true
		Log.i(
			logTag,
			"Initialized Meta SDK for Android install attribution. " +
				"sdkVersion=${FacebookSdk.getSdkVersion()} " +
				"appId=$app_id " +
				"displayName=$display_name " +
				"advertiserIdCollectionEnabled=$advertiserIdCollectionEnabled"
		)
		return OK
	}

	@UsedByGodot
	fun is_initialized(): Boolean = initialized

	@UsedByGodot
	fun sync_advertiser_tracking_enabled(): Boolean {
		if (!FacebookSdk.isInitialized()) {
			Log.d(logTag, "sync_advertiser_tracking_enabled() before SDK init; returning configured value=$advertiserIdCollectionEnabled")
			return advertiserIdCollectionEnabled
		}

		FacebookSdk.setAdvertiserIDCollectionEnabled(advertiserIdCollectionEnabled)
		Log.d(logTag, "Applied advertiser ID collection enabled=$advertiserIdCollectionEnabled")
		return advertiserIdCollectionEnabled
	}

	@UsedByGodot
	fun flush() {
		if (!initialized) {
			Log.d(logTag, "flush() ignored because SDK is not initialized.")
			return
		}

		Log.i(logTag, "Flushing Meta App Events queue.")
		AppEventsLogger.newLogger(activity?.applicationContext ?: return).flush()
	}

	@UsedByGodot
	fun log_debug_test_event(): Boolean {
		if (!initialized) {
			Log.d(logTag, "log_debug_test_event() ignored because SDK is not initialized.")
			return false
		}

		val context = activity?.applicationContext ?: run {
			Log.d(logTag, "log_debug_test_event() ignored because applicationContext was null.")
			return false
		}

		val parameters = Bundle().apply {
			putString("source", "godot_meta_install_plugin")
			putString("platform", "android")
			putString("build_type", "debug")
			putString("sdk_version", FacebookSdk.getSdkVersion())
		}
		AppEventsLogger.newLogger(context).logEvent(DEBUG_TEST_EVENT_NAME, parameters)
		Log.i(logTag, "Logged Meta debug test event: $DEBUG_TEST_EVENT_NAME")
		return true
	}

	@UsedByGodot
	fun logDebugTestEvent(): Boolean = log_debug_test_event()

	@UsedByGodot
	fun get_sdk_version(): String = FacebookSdk.getSdkVersion()

	@UsedByGodot
	fun getSdkVersion(): String = FacebookSdk.getSdkVersion()

	companion object {
		private const val PLUGIN_NAME = "MetaInstallPlugin"
		private const val DEBUG_TEST_EVENT_NAME = "godot_meta_debug_test_event"

		private const val OK = 0
		private const val ERR_UNAVAILABLE = 49
		private const val ERR_INVALID_PARAMETER = 31
	}
}
