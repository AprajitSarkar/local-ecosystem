package com.localecosystem.local_ecosystem

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

import android.app.PendingIntent

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var methodChannel: MethodChannel? = null
    private var clipboardListener: ClipboardManager.OnPrimaryClipChangedListener? = null
    private var screenshotObserver: ScreenshotObserver? = null

    companion object {
        private const val CHANNEL = "com.localecosystem/clipboard"
        private const val NOTIF_CHANNEL_ID = "ecosystem_foreground_service"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showPersistentNotification" -> {
                    val title = call.argument<String>("title") ?: "Local Ecosystem"
                    val content = call.argument<String>("content") ?: "Connected to Ecosystem"
                    showNotification(title, content)
                    // Update foreground service notification too
                    startClipboardService(content)
                    result.success(true)
                }
                "getClipboard" -> {
                    val clip = getSystemClipboard()
                    result.success(clip)
                }
                "setClipboard" -> {
                    val text = call.argument<String>("text") ?: ""
                    setSystemClipboard(text)
                    result.success(true)
                }
                "setImageClipboard" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes != null) {
                        try {
                            val file = File(cacheDir, "ecosystem_clip.png")
                            file.writeBytes(bytes)
                            val uri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )
                            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
                            val clip = ClipData.newUri(contentResolver, "Image", uri)
                            clipboard?.setPrimaryClip(clip)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                        result.success(true)
                    } else {
                        result.error("NO_BYTES", "Empty byte array", null)
                    }
                }
                "openFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    if (path.isNotEmpty()) {
                        val file = File(path)
                        if (file.exists()) {
                            try {
                                val uri = FileProvider.getUriForFile(
                                    this,
                                    "$packageName.fileprovider",
                                    file
                                )
                                val extension = file.extension.lowercase()
                                val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: "*/*"
                                
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(uri, mime)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                // Fallback with general mime
                                try {
                                    val uri = FileProvider.getUriForFile(
                                        this,
                                        "$packageName.fileprovider",
                                        file
                                    )
                                    val fallbackIntent = Intent(Intent.ACTION_VIEW).apply {
                                        setDataAndType(uri, "*/*")
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(fallbackIntent)
                                    result.success(true)
                                } catch (e2: Exception) {
                                    result.error("NO_APP", "Could not open file: ${e2.message}", null)
                                }
                            }
                        } else {
                            result.error("FILE_NOT_FOUND", "File does not exist: $path", null)
                        }
                    } else {
                        result.error("INVALID_PATH", "Path is empty", null)
                    }
                }
                "openUrl" -> {
                    val url = call.argument<String>("url") ?: ""
                    if (url.isNotEmpty()) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_URL_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL is empty", null)
                    }
                }
                "getWifiCapabilities" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                        val info = wifiManager?.connectionInfo
                        val freq = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) info?.frequency ?: 5200 else 5200
                        val linkSpeed = info?.linkSpeed ?: 866
                        val standard = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            when (info?.wifiStandard) {
                                6 -> "Wi-Fi 6 (802.11ax)"
                                5 -> "Wi-Fi 5 (802.11ac)"
                                4 -> "Wi-Fi 4 (802.11n)"
                                7 -> "Wi-Fi 6E"
                                8 -> "Wi-Fi 7 (802.11be)"
                                else -> "Wi-Fi High-Speed"
                            }
                        } else {
                            if (freq >= 4900) "Wi-Fi 5 (802.11ac)" else "Wi-Fi 4 (802.11n)"
                        }

                        val p2pSupported = packageManager.hasSystemFeature(android.content.pm.PackageManager.FEATURE_WIFI_DIRECT)

                        result.success(mapOf(
                            "frequency" to freq,
                            "linkSpeed" to linkSpeed,
                            "standard" to standard,
                            "isP2pSupported" to p2pSupported
                        ))
                    } catch (e: Exception) {
                        result.success(mapOf(
                            "frequency" to 5200,
                            "linkSpeed" to 866,
                            "standard" to "802.11ac",
                            "isP2pSupported" to true
                        ))
                    }
                }
                "showToast" -> {
                    val message = call.argument<String>("message") ?: "Copied"
                    runOnUiThread {
                        android.widget.Toast.makeText(applicationContext, message, android.widget.Toast.LENGTH_SHORT).show()
                    }
                    result.success(true)
                }
                "recordPeerIp" -> {
                    val ip = call.argument<String>("ip")
                    val name = call.argument<String>("name")
                    if (ip != null && ip.isNotEmpty() && ip != "127.0.0.1") {
                        val prefs = getSharedPreferences("ecosystem_peers", Context.MODE_PRIVATE)
                        val set = prefs.getStringSet("known_ips", emptySet())?.toMutableSet() ?: mutableSetOf()
                        set.add(ip)
                        val editor = prefs.edit().putStringSet("known_ips", set)
                        if (name != null && name.isNotEmpty()) {
                            editor.putString("name_$ip", name)
                        }
                        editor.apply()
                    }
                    result.success(true)
                }
                "storeDeviceInfo" -> {
                    val dId = call.argument<String>("deviceId") ?: ""
                    val dName = call.argument<String>("deviceName") ?: ""
                    val ecoId = call.argument<String>("ecosystemId") ?: ""
                    val prefs = getSharedPreferences("flutter_settings", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("device_id", dId)
                        .putString("device_name", dName)
                        .putString("ecosystem_id", ecoId)
                        .apply()
                    ClipboardForegroundService.deviceId = dId
                    ClipboardForegroundService.deviceName = dName
                    ClipboardForegroundService.ecosystemId = ecoId
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        val mediaChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.localecosystem/media")
        mediaChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "executeMediaCommand" -> {
                    val action = call.argument<String>("action") ?: ""
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as? android.media.AudioManager
                    val keyCode = when (action) {
                        "PLAY_PAUSE", "PLAY", "PAUSE" -> android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
                        "NEXT" -> android.view.KeyEvent.KEYCODE_MEDIA_NEXT
                        "PREVIOUS" -> android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS
                        "VOLUME_UP" -> android.view.KeyEvent.KEYCODE_VOLUME_UP
                        "VOLUME_DOWN" -> android.view.KeyEvent.KEYCODE_VOLUME_DOWN
                        else -> 0
                    }
                    if (keyCode != 0 && audioManager != null) {
                        audioManager.dispatchMediaKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, keyCode))
                        audioManager.dispatchMediaKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, keyCode))
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        val soundEffectsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.localecosystem.local_ecosystem/sound_effects")
        soundEffectsChannel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "playRequest" -> {
                        val toneGen = android.media.ToneGenerator(android.media.AudioManager.STREAM_NOTIFICATION, 95)
                        toneGen.startTone(android.media.ToneGenerator.TONE_PROP_BEEP, 280)
                        result.success(true)
                    }
                    "playIncoming" -> {
                        val toneGen = android.media.ToneGenerator(android.media.AudioManager.STREAM_NOTIFICATION, 95)
                        toneGen.startTone(android.media.ToneGenerator.TONE_PROP_BEEP2, 220)
                        result.success(true)
                    }
                    "playComplete" -> {
                        val toneGen = android.media.ToneGenerator(android.media.AudioManager.STREAM_NOTIFICATION, 95)
                        toneGen.startTone(android.media.ToneGenerator.TONE_PROP_ACK, 260)
                        result.success(true)
                    }
                    "playError" -> {
                        val toneGen = android.media.ToneGenerator(android.media.AudioManager.STREAM_NOTIFICATION, 95)
                        toneGen.startTone(android.media.ToneGenerator.TONE_PROP_NACK, 300)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.success(false)
            }
        }

        setupClipboardListener()
        setupScreenshotObserver()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            multicastLock = wifi?.createMulticastLock("LocalEcosystemMulticastLock")?.apply {
                setReferenceCounted(true)
                acquire()
            }

            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                WifiManager.WIFI_MODE_FULL_LOW_LATENCY
            } else {
                WifiManager.WIFI_MODE_FULL_HIGH_PERF
            }
            wifiLock = wifi?.createWifiLock(mode, "LocalEcosystem:HighPerfWifiLock")?.apply {
                setReferenceCounted(false)
                acquire()
            }

            val powerManager = applicationContext.getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "LocalEcosystem:TransferWakeLock")?.apply {
                setReferenceCounted(false)
                acquire(24 * 60 * 60 * 1000L /* 24 hours */)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Clipboard service will start when permissions are established or app is ready
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                startClipboardService("Connected to Ecosystem")
            } catch (_: Throwable) {}
        }, 1500)
    }

    private fun startClipboardService(notificationContent: String) {
        try {
            val prefs = getSharedPreferences("flutter_settings", Context.MODE_PRIVATE)
            val storedDeviceId = prefs.getString("device_id", null)
            val storedDeviceName = prefs.getString("device_name", null)
            val storedEcosystemId = prefs.getString("ecosystem_id", null)

            if (storedDeviceId != null) ClipboardForegroundService.deviceId = storedDeviceId
            if (storedDeviceName != null) ClipboardForegroundService.deviceName = storedDeviceName
            if (storedEcosystemId != null) ClipboardForegroundService.ecosystemId = storedEcosystemId

            val serviceIntent = Intent(this, ClipboardForegroundService::class.java).apply {
                putExtra("content", notificationContent)
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
            } catch (_: Throwable) {}
        } catch (_: Throwable) {}
    }

    override fun onResume() {
        super.onResume()
        checkAndDispatchClipboard()
        screenshotObserver?.checkLatestScreenshot()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            checkAndDispatchClipboard()
            screenshotObserver?.checkLatestScreenshot()
        }
    }

    private fun setupClipboardListener() {
        try {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager ?: return
            clipboardListener = ClipboardManager.OnPrimaryClipChangedListener {
                checkAndDispatchClipboard()
            }
            clipboard.addPrimaryClipChangedListener(clipboardListener)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setupScreenshotObserver() {
        try {
            screenshotObserver = ScreenshotObserver(applicationContext, Handler(Looper.getMainLooper())) { path, bytes ->
                runOnUiThread {
                    methodChannel?.invokeMethod("onScreenshotDetected", mapOf(
                        "path" to path,
                        "bytes" to bytes
                    ))
                }
            }
            contentResolver.registerContentObserver(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                true,
                screenshotObserver!!
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun checkAndDispatchClipboard() {
        try {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager ?: return
            val clip = clipboard.primaryClip
            if (clip != null && clip.itemCount > 0) {
                val text = clip.getItemAt(0).coerceToText(this).toString()
                if (text.isNotEmpty()) {
                    runOnUiThread {
                        methodChannel?.invokeMethod("onClipboardChanged", text)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getSystemClipboard(): String {
        return try {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            val clip = clipboard?.primaryClip
            if (clip != null && clip.itemCount > 0) {
                clip.getItemAt(0).coerceToText(this).toString()
            } else ""
        } catch (e: Exception) {
            ""
        }
    }

    private fun setSystemClipboard(text: String) {
        try {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            val clip = ClipData.newPlainText("Local Ecosystem", text)
            clipboard?.setPrimaryClip(clip)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private val clipboardHandler = Handler(Looper.getMainLooper())
    private val clipboardRunnable = object : Runnable {
        override fun run() {
            checkAndDispatchClipboard()
            clipboardHandler.postDelayed(this, 2000)
        }
    }

    private fun showNotification(title: String, content: String) {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    NOTIF_CHANNEL_ID,
                    "Ecosystem Connection Status",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Shows live connection status for Local Ecosystem"
                    setShowBadge(false)
                }
                manager.createNotificationChannel(channel)
            }

            val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = android.app.PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
            )

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, NOTIF_CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

            val notif = builder
                .setContentTitle(title)
                .setContentText(content)
                .setSmallIcon(android.R.drawable.stat_notify_sync)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()

            manager.notify(1001, notif)
            
            // Start background clipboard polling
            clipboardHandler.removeCallbacks(clipboardRunnable)
            clipboardHandler.post(clipboardRunnable)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            if (multicastLock?.isHeld == true) multicastLock?.release()
            if (wifiLock?.isHeld == true) wifiLock?.release()
            if (wakeLock?.isHeld == true) wakeLock?.release()
            clipboardListener?.let {
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
                clipboard?.removePrimaryClipChangedListener(it)
            }
            screenshotObserver?.let {
                contentResolver.unregisterContentObserver(it)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
