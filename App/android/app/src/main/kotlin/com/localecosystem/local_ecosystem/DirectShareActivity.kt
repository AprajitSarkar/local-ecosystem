package com.localecosystem.local_ecosystem

import android.app.Activity
import android.app.AlertDialog
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Base64
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import java.io.InputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.Socket
import java.security.MessageDigest
import java.util.UUID
import org.json.JSONObject

data class DiscoveredTarget(
    val deviceId: String,
    val displayName: String,
    val address: String,
    val platform: String = "unknown",
    val port: Int = 51413
)

class DirectShareActivity : Activity() {
    private val TAG = "DirectShare"
    private val NOTIF_CHANNEL_ID = "ecosystem_direct_share"
    private val NOTIF_ID = 2002

    private val selectedUris = mutableListOf<Uri>()
    private var sharedText: String? = null
    private val localIps = mutableSetOf<String>("127.0.0.1")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        detectLocalIps()
        extractShareData(intent)

        if (selectedUris.isEmpty() && (sharedText == null || sharedText!!.isEmpty())) {
            Toast.makeText(this, "No content to share", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        // Quick discover online devices
        Thread {
            val targets = discoverActiveTargets()

            runOnUiThread {
                handleTargetsDiscovered(targets)
            }
        }.start()
    }

    private fun detectLocalIps() {
        try {
            val ifaces = NetworkInterface.getNetworkInterfaces()
            while (ifaces.hasMoreElements()) {
                val iface = ifaces.nextElement()
                val addrs = iface.inetAddresses
                while (addrs.hasMoreElements()) {
                    val addr = addrs.nextElement()
                    if (!addr.isLoopbackAddress && addr.hostAddress != null) {
                        val ip = addr.hostAddress ?: ""
                        if (ip.contains(".")) {
                            localIps.add(ip)
                        }
                    }
                }
            }
        } catch (_: Exception) {}
    }

    private fun extractShareData(intent: Intent) {
        val action = intent.action
        if (Intent.ACTION_SEND == action) {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
            }

            if (uri != null) {
                selectedUris.add(uri)
            } else if (text != null && text.isNotEmpty()) {
                sharedText = text
            }
        } else if (Intent.ACTION_SEND_MULTIPLE == action) {
            val streamUris = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
            }
            if (streamUris != null) {
                selectedUris.addAll(streamUris)
            }
        }
    }

    private fun handleTargetsDiscovered(targets: List<DiscoveredTarget>) {
        if (isFinishing) return

        if (targets.isEmpty()) {
            Toast.makeText(this, "No other ecosystem devices found on Wi-Fi", Toast.LENGTH_LONG).show()
            finish()
            return
        }

        // Single target online -> Direct send immediately
        if (targets.size == 1) {
            startStreamingToTargets(listOf(targets[0]))
            finish()
            return
        }

        // Multiple devices -> Show modern selection sheet
        showTargetSelectionPopup(targets)
    }

    private fun showTargetSelectionPopup(targets: List<DiscoveredTarget>) {
        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(40, 30, 40, 30)
            setBackgroundColor(Color.parseColor("#1E1E2E"))
        }

        val titleView = TextView(this).apply {
            text = "⚡ Send to Device"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding(0, 0, 0, 16)
        }
        rootLayout.addView(titleView)

        val scroll = ScrollView(this)
        val listLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        var dialog: AlertDialog? = null

        // "Send to All Devices" item
        val allDevicesCard = createDeviceRow("🌐 Send to All Devices (${targets.size})", "Broadcasts to all online devices", "#3B82F6") {
            dialog?.dismiss()
            startStreamingToTargets(targets)
            finish()
        }
        listLayout.addView(allDevicesCard)

        for (target in targets) {
            val icon = when (target.platform.lowercase()) {
                "linux" -> "💻"
                "windows" -> "🪟"
                "ios", "ipad" -> "🍎"
                "macos" -> "🖥️"
                else -> "📱"
            }
            val card = createDeviceRow("$icon ${target.displayName}", target.address, "#2A2A3E") {
                dialog?.dismiss()
                startStreamingToTargets(listOf(target))
                finish()
            }
            listLayout.addView(card)
        }

        scroll.addView(listLayout)
        rootLayout.addView(scroll)

        dialog = AlertDialog.Builder(this, android.R.style.Theme_DeviceDefault_Dialog_Alert)
            .setView(rootLayout)
            .setNegativeButton("Cancel") { _, _ -> finish() }
            .setOnCancelListener { finish() }
            .create()

        dialog.show()
    }

    private fun createDeviceRow(title: String, subtitle: String, bgColor: String, onClick: () -> Unit): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 24, 32, 24)
            isClickable = true
            isFocusable = true
            val shape = GradientDrawable().apply {
                setColor(Color.parseColor(bgColor))
                cornerRadius = 24f
            }
            background = shape
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 8, 0, 12)
            }
            layoutParams = params
            setOnClickListener { onClick() }
        }

        val titleTv = TextView(this).apply {
            text = title
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        val subTv = TextView(this).apply {
            text = subtitle
            setTextColor(Color.parseColor("#94A3B8"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setPadding(0, 4, 0, 0)
        }

        row.addView(titleTv)
        row.addView(subTv)
        return row
    }

    private fun startStreamingToTargets(targets: List<DiscoveredTarget>) {
        val targetNames = targets.joinToString(", ") { it.displayName }

        if (sharedText != null) {
            Toast.makeText(this, "Sending to $targetNames…", Toast.LENGTH_SHORT).show()
            Thread {
                sendTextOrLink(sharedText!!, targets)
            }.start()
        } else if (selectedUris.isNotEmpty()) {
            Toast.makeText(this, "Sending ${selectedUris.size} file(s) to $targetNames…", Toast.LENGTH_SHORT).show()
            Thread {
                sendFiles(selectedUris, targets)
            }.start()
        }
    }

    private fun sendTextOrLink(text: String, targets: List<DiscoveredTarget>) {
        try {
            val isUrl = text.startsWith("http://") || text.startsWith("https://")
            val myDeviceName = Build.MODEL ?: "Android Phone"

            // Direct Unicast TCP ProtocolMessage to selected targets only (NO BROADCAST to prevent local self-loopback)
            val tcpPayload = JSONObject().apply {
                put("version", 1)
                put("type", if (isUrl) "link_share" else "text_clipboard")
                put("messageId", UUID.randomUUID().toString())
                put("sourceDeviceId", "android-direct-share")
                put("timestamp", System.currentTimeMillis())
                put("payload", JSONObject().apply {
                    put("url", text)
                    put("text", text)
                    put("deviceName", myDeviceName)
                })
            }.toString()

            val udpPayload = JSONObject().apply {
                put("type", if (isUrl) "LINK_SHARE" else "CLIPBOARD_SYNC")
                put("url", text)
                put("text", text)
                put("deviceName", myDeviceName)
                put("deviceId", "android-direct-share")
                put("timestamp", System.currentTimeMillis())
            }.toString().toByteArray(Charsets.UTF_8)

            val udpSocket = DatagramSocket()

            for (t in targets) {
                // Send UDP Unicast
                try {
                    udpSocket.send(DatagramPacket(udpPayload, udpPayload.size, InetAddress.getByName(t.address), 42421))
                } catch (_: Exception) {}

                // Send TCP Stream
                try {
                    val tcp = Socket()
                    tcp.connect(InetSocketAddress(t.address, t.port), 4000)
                    val w = tcp.getOutputStream().bufferedWriter(Charsets.UTF_8)
                    w.write(tcpPayload + "\n")
                    w.flush()
                    Thread.sleep(100)
                    tcp.close()
                    Log.i(TAG, "Delivered link/text to ${t.displayName} @ ${t.address}")
                } catch (e: Exception) {
                    Log.w(TAG, "TCP send failed to ${t.address}: ${e.message}")
                }
            }

            udpSocket.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun sendFiles(uris: List<Uri>, targets: List<DiscoveredTarget>) {
        val myDeviceName = Build.MODEL ?: "Android Phone"

        for (uri in uris) {
            try {
                val (filename, size, stream) = resolveUri(uri) ?: continue
                val bytes = stream.readBytes()
                val sha = sha256(bytes)
                val transferId = UUID.randomUUID().toString()

                for (target in targets) {
                    try {
                        val socket = Socket()
                        socket.connect(InetSocketAddress(target.address, target.port), 5000)
                        socket.tcpNoDelay = true
                        val writer = socket.getOutputStream().bufferedWriter(Charsets.UTF_8)
                        val reader = socket.getInputStream().bufferedReader(Charsets.UTF_8)

                        // 1. Send Valid Transfer Offer
                        val offer = JSONObject().apply {
                            put("version", 1)
                            put("type", "transfer_offer")
                            put("messageId", UUID.randomUUID().toString())
                            put("sourceDeviceId", "android-direct-share")
                            put("timestamp", System.currentTimeMillis())
                            put("payload", JSONObject().apply {
                                put("transferId", transferId)
                                put("filename", filename)
                                put("mimeType", contentResolver.getType(uri) ?: "application/octet-stream")
                                put("totalBytes", bytes.size)
                                put("sha256Hash", sha)
                                put("senderDeviceName", myDeviceName)
                            })
                        }.toString()

                        writer.write(offer + "\n")
                        writer.flush()

                        // Wait for server to accept
                        val acceptLine = reader.readLine()
                        Log.i(TAG, "Server accepted transfer: $acceptLine")

                        // 2. Chunks (64 KB chunks)
                        val chunkSize = 64 * 1024
                        var offset = 0
                        while (offset < bytes.size) {
                            val end = minOf(offset + chunkSize, bytes.size)
                            val chunkBytes = bytes.copyOfRange(offset, end)
                            val chunkB64 = Base64.encodeToString(chunkBytes, Base64.NO_WRAP)

                            val chunk = JSONObject().apply {
                                put("version", 1)
                                put("type", "transfer_chunk")
                                put("messageId", UUID.randomUUID().toString())
                                put("sourceDeviceId", "android-direct-share")
                                put("timestamp", System.currentTimeMillis())
                                put("payload", JSONObject().apply {
                                    put("transferId", transferId)
                                    put("offset", offset)
                                    put("length", chunkBytes.size)
                                    put("data", chunkB64)
                                })
                            }.toString()

                            writer.write(chunk + "\n")
                            writer.flush()
                            offset = end

                            val pct = ((offset.toDouble() / bytes.size) * 100).toInt()
                            showNotification("Sending to ${target.displayName}", "Sending $filename ($pct%)", pct, true)
                        }

                        // 3. Send Complete
                        val complete = JSONObject().apply {
                            put("version", 1)
                            put("type", "transfer_complete")
                            put("messageId", UUID.randomUUID().toString())
                            put("sourceDeviceId", "android-direct-share")
                            put("timestamp", System.currentTimeMillis())
                            put("payload", JSONObject().apply {
                                put("transferId", transferId)
                                put("sha256Hash", sha)
                            })
                        }.toString()

                        writer.write(complete + "\n")
                        writer.flush()

                        // Wait for server complete ACK
                        try {
                            reader.readLine()
                        } catch (_: Exception) {}

                        socket.close()
                        showNotification("Sent to ${target.displayName}", "Successfully shared $filename", 100, false)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        Log.e(TAG, "Failed to send $filename: ${e.message}")
                        showNotification("Transfer Error", "Failed to send $filename to ${target.displayName}", 0, false)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun discoverActiveTargets(): List<DiscoveredTarget> {
        val targets = mutableMapOf<String, DiscoveredTarget>()
        val myDeviceName = Build.MODEL ?: "Android Phone"
        val prefs = getSharedPreferences("ecosystem_peers", Context.MODE_PRIVATE)
        val cachedIps = prefs.getStringSet("known_ips", emptySet()) ?: emptySet()

        // Active UDP ping to discover currently online peers
        try {
            val socket = DatagramSocket()
            socket.broadcast = true
            socket.soTimeout = 900

            val ping = JSONObject().apply {
                put("type", "PING")
                put("deviceId", "android-share-picker")
            }.toString().toByteArray(Charsets.UTF_8)

            // Send subnet broadcast
            socket.send(DatagramPacket(ping, ping.size, InetAddress.getByName("255.255.255.255"), 42421))
            for (ip in cachedIps) {
                if (!localIps.contains(ip)) {
                    try {
                        socket.send(DatagramPacket(ping, ping.size, InetAddress.getByName(ip), 42421))
                    } catch (_: Exception) {}
                }
            }

            val buf = ByteArray(2048)
            val start = System.currentTimeMillis()
            while (System.currentTimeMillis() - start < 900) {
                try {
                    val packet = DatagramPacket(buf, buf.size)
                    socket.receive(packet)
                    val text = String(packet.data, 0, packet.length, Charsets.UTF_8)
                    val json = JSONObject(text)
                    val type = json.optString("type")
                    if (type == "ANNOUNCE") {
                        val devId = json.optString("deviceId")
                        val name = json.optString("displayName", "Device")
                        var platform = json.optString("platform", "unknown")
                        if (platform == "unknown" && (name.startsWith("DESKTOP-") || name.startsWith("WIN-") || name.contains("Windows", ignoreCase = true))) {
                            platform = "windows"
                        }
                        val ip = packet.address.hostAddress ?: continue
                        val port = json.optInt("tcpPort", 51413)
                        if (!localIps.contains(ip) && ip != "127.0.0.1" && name != myDeviceName) {
                            targets[ip] = DiscoveredTarget(devId, name, ip, platform, port)
                            prefs.edit().putString("name_$ip", name).apply()
                        }
                    }
                } catch (_: Exception) {
                    break
                }
            }
            socket.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Fast TCP probe for any cached peer that hasn't answered UDP broadcast yet
        for (ip in cachedIps) {
            if (!targets.containsKey(ip) && !localIps.contains(ip) && ip != "127.0.0.1") {
                try {
                    val s = Socket()
                    s.connect(InetSocketAddress(ip, 51413), 300)
                    s.close()
                    val name = prefs.getString("name_$ip", "Ecosystem Device") ?: "Ecosystem Device"
                    val plat = if (name.startsWith("DESKTOP-") || name.startsWith("WIN-")) "windows" else "unknown"
                    targets[ip] = DiscoveredTarget("peer-$ip", name, ip, plat, 51413)
                } catch (_: Exception) {}
            }
        }

        return targets.values.toList()
    }

    private fun resolveUri(uri: Uri): Triple<String, Long, InputStream>? {
        var filename = "shared_file_${System.currentTimeMillis()}"
        var size: Long = 0

        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIdx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val sizeIdx = cursor.getColumnIndex(OpenableColumns.SIZE)
                if (nameIdx >= 0) {
                    filename = cursor.getString(nameIdx) ?: filename
                }
                if (sizeIdx >= 0) {
                    size = cursor.getLong(sizeIdx)
                }
            }
        }

        val stream = contentResolver.openInputStream(uri) ?: return null
        return Triple(filename, size, stream)
    }

    private fun sha256(data: ByteArray): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(data)
        return hash.joinToString("") { "%02x".format(it) }
    }

    private fun showNotification(title: String, content: String, progress: Int, ongoing: Boolean) {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    NOTIF_CHANNEL_ID,
                    "Direct Share Progress",
                    NotificationManager.IMPORTANCE_LOW
                )
                manager.createNotificationChannel(channel)
            }

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, NOTIF_CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

            builder.setContentTitle(title)
                .setContentText(content)
                .setSmallIcon(android.R.drawable.stat_sys_upload)
                .setOngoing(ongoing)

            if (ongoing) {
                builder.setProgress(100, progress, false)
            } else {
                builder.setProgress(0, 0, false)
            }

            manager.notify(NOTIF_ID, builder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
