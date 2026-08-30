package com.localecosystem.local_ecosystem

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import org.json.JSONObject
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.NetworkInterface
import java.util.Collections

class ClipboardForegroundService : Service() {

    companion object {
        private const val NOTIF_CHANNEL_ID = "ecosystem_foreground_service"
        private const val NOTIF_ID = 1001
        private const val UDP_PORT = 42421
        private const val POLL_INTERVAL_MS = 1500L

        @Volatile
        var isRunning = false
            private set

        // Shared state: the last clipboard text we sent out (avoid echo loops)
        @Volatile
        var lastSentText: String? = null

        // Shared state: the last clipboard text we received (avoid echo loops)
        @Volatile
        var lastReceivedText: String? = null

        // Our device info (set by MainActivity before starting service)
        @Volatile
        var deviceId: String = ""
        @Volatile
        var deviceName: String = "Android Device"
        @Volatile
        var ecosystemId: String = ""
    }

    private var clipboardManager: ClipboardManager? = null
    private var clipboardListener: ClipboardManager.OnPrimaryClipChangedListener? = null
    private val handler = Handler(Looper.getMainLooper())
    private var udpReceiveThread: Thread? = null
    private var lastClipText: String? = null
    private var running = true

    // Polling runnable: backup for clipboard listener
    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!running) return
            checkAndBroadcastClipboard()
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true

        try {
            // Create notification channel
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    NOTIF_CHANNEL_ID,
                    "Ecosystem Connection Status",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Keeps clipboard sync active in the background"
                    setShowBadge(false)
                }
                val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                manager?.createNotificationChannel(channel)
            }

            // Start foreground with notification
            val notification = buildNotification("Connected to Ecosystem")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    startForeground(NOTIF_ID, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
                } catch (e: Throwable) {
                    startForeground(NOTIF_ID, notification)
                }
            } else {
                startForeground(NOTIF_ID, notification)
            }
        } catch (e: Throwable) {
            e.printStackTrace()
        }

        try {
            // Setup clipboard listener
            clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            clipboardListener = ClipboardManager.OnPrimaryClipChangedListener {
                checkAndBroadcastClipboard()
            }
            clipboardManager?.addPrimaryClipChangedListener(clipboardListener)

            // Start polling as backup
            handler.postDelayed(pollRunnable, POLL_INTERVAL_MS)

            // Start UDP receive thread safely
            startUdpReceiver()
        } catch (e: Throwable) {
            e.printStackTrace()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Update notification if requested
        val title = intent?.getStringExtra("title")
        val content = intent?.getStringExtra("content")
        if (content != null) {
            val notification = buildNotification(content)
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.notify(NOTIF_ID, notification)
        }
        return START_STICKY
    }

    private fun buildNotification(content: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIF_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("Local Ecosystem")
            .setContentText(content)
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun checkAndBroadcastClipboard() {
        try {
            val clip = clipboardManager?.primaryClip
            if (clip != null && clip.itemCount > 0) {
                val text = clip.getItemAt(0).coerceToText(this).toString()
                if (text.isNotEmpty() && text != lastClipText && text != lastReceivedText) {
                    lastClipText = text
                    lastSentText = text
                    broadcastClipboardViaUdp(text)
                    broadcastClipboardViaTcp(text)
                }
            }
        } catch (e: Exception) {
            // Clipboard access may fail in some edge cases
        }
    }

    private fun broadcastClipboardViaUdp(text: String) {
        Thread {
            try {
                val json = JSONObject().apply {
                    put("type", "CLIPBOARD_SYNC")
                    put("deviceId", deviceId)
                    put("deviceName", deviceName)
                    put("ecosystemId", ecosystemId)
                    put("timestamp", System.currentTimeMillis())
                    put("text", text)
                }
                val data = json.toString().toByteArray(Charsets.UTF_8)

                val socket = DatagramSocket()
                socket.broadcast = true

                // Send to known peer IPs
                val prefs = getSharedPreferences("ecosystem_peers", Context.MODE_PRIVATE)
                val knownIps = prefs.getStringSet("known_ips", emptySet()) ?: emptySet()
                for (ip in knownIps) {
                    try {
                        val addr = InetAddress.getByName(ip)
                        val packet = DatagramPacket(data, data.size, addr, UDP_PORT)
                        socket.send(packet)
                    } catch (_: Exception) {}
                }

                // Broadcast to 255.255.255.255
                try {
                    val broadcastAddr = InetAddress.getByName("255.255.255.255")
                    val packet = DatagramPacket(data, data.size, broadcastAddr, UDP_PORT)
                    socket.send(packet)
                } catch (_: Exception) {}

                // Subnet broadcasts
                try {
                    val interfaces = Collections.list(NetworkInterface.getNetworkInterfaces())
                    for (iface in interfaces) {
                        if (iface.isLoopback || !iface.isUp) continue
                        for (addr in Collections.list(iface.inetAddresses)) {
                            val ip = addr.hostAddress ?: continue
                            if (ip.contains(':')) continue // skip IPv6
                            val parts = ip.split('.')
                            if (parts.size == 4) {
                                val bcastIp = "${parts[0]}.${parts[1]}.${parts[2]}.255"
                                try {
                                    val bcastAddr = InetAddress.getByName(bcastIp)
                                    val packet = DatagramPacket(data, data.size, bcastAddr, UDP_PORT)
                                    socket.send(packet)
                                } catch (_: Exception) {}
                            }
                        }
                    }
                } catch (_: Exception) {}

                socket.close()
            } catch (_: Exception) {}
        }.start()
    }

    private fun broadcastClipboardViaTcp(text: String) {
        Thread {
            try {
                val json = JSONObject().apply {
                    put("version", 1)
                    put("type", "text_clipboard")
                    put("messageId", java.util.UUID.randomUUID().toString())
                    put("sourceDeviceId", deviceId)
                    put("timestamp", System.currentTimeMillis())
                    val payload = JSONObject().apply {
                        put("text", text)
                        put("deviceName", deviceName)
                    }
                    put("payload", payload)
                }
                val payload = json.toString() + "\n"

                val prefs = getSharedPreferences("ecosystem_peers", Context.MODE_PRIVATE)
                val knownIps = prefs.getStringSet("known_ips", emptySet()) ?: emptySet()

                for (ip in knownIps) {
                    try {
                        val socket = java.net.Socket()
                        socket.connect(java.net.InetSocketAddress(ip, 51413), 2000)
                        socket.getOutputStream().write(payload.toByteArray(Charsets.UTF_8))
                        socket.getOutputStream().flush()
                        socket.close()
                    } catch (_: Exception) {}
                }
            } catch (_: Exception) {}
        }.start()
    }

    private fun startUdpReceiver() {
        udpReceiveThread = Thread {
            try {
                val socket = DatagramSocket(null)
                socket.reuseAddress = true
                socket.bind(java.net.InetSocketAddress(InetAddress.getByName("0.0.0.0"), UDP_PORT))
                socket.broadcast = true

                val buffer = ByteArray(65535)
                while (running) {
                    try {
                        val packet = DatagramPacket(buffer, buffer.size)
                        socket.receive(packet)

                        val data = String(packet.data, 0, packet.length, Charsets.UTF_8)
                        val senderIp = packet.address.hostAddress ?: continue

                        // Record this peer IP
                        if (senderIp != "127.0.0.1") {
                            val prefs = getSharedPreferences("ecosystem_peers", Context.MODE_PRIVATE)
                            val set = prefs.getStringSet("known_ips", emptySet())?.toMutableSet() ?: mutableSetOf()
                            set.add(senderIp)
                            prefs.edit().putStringSet("known_ips", set).apply()
                        }

                        val json = JSONObject(data)
                        val type: String = json.optString("type", "")
                        val senderId: String = json.optString("deviceId", "")

                        if (senderId.equals(deviceId) || senderId.isEmpty()) continue

                        when (type) {
                            "CLIPBOARD_SYNC" -> {
                                val text = json.optString("text", "")
                                val senderName = json.optString("deviceName", "Device")
                                if (text.isNotEmpty() && text != lastClipText && text != lastSentText) {
                                    lastReceivedText = text
                                    lastClipText = text
                                    // Set system clipboard on main thread
                                    handler.post {
                                        try {
                                            val clip = ClipData.newPlainText("Local Ecosystem", text)
                                            clipboardManager?.setPrimaryClip(clip)
                                            // Show toast
                                            android.widget.Toast.makeText(
                                                applicationContext,
                                                "Copied: $senderName",
                                                android.widget.Toast.LENGTH_SHORT
                                            ).show()
                                        } catch (_: Exception) {}
                                    }
                                }
                            }
                        }
                    } catch (_: Exception) {
                        if (!running) break
                    }
                }
                socket.close()
            } catch (_: Exception) {}
        }
        udpReceiveThread?.isDaemon = true
        udpReceiveThread?.start()
    }

    fun updateNotification(content: String) {
        val notification = buildNotification(content)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(NOTIF_ID, notification)
    }

    override fun onDestroy() {
        running = false
        isRunning = false
        handler.removeCallbacks(pollRunnable)
        clipboardListener?.let {
            clipboardManager?.removePrimaryClipChangedListener(it)
        }
        udpReceiveThread?.interrupt()
        super.onDestroy()
    }
}
