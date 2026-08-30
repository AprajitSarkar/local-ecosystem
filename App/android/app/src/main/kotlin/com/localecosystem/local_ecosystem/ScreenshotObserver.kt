package com.localecosystem.local_ecosystem

import android.content.ContentUris
import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.provider.MediaStore
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.Socket
import java.util.UUID
import org.json.JSONObject

class ScreenshotObserver(
    private val context: Context,
    handler: Handler,
    private val onScreenshot: (String, ByteArray) -> Unit
) : ContentObserver(handler) {
    private var lastId: Long = -1
    private var lastTime: Long = 0

    override fun onChange(selfChange: Boolean, uri: Uri?) {
        super.onChange(selfChange, uri)
        checkLatestScreenshot()
    }

    fun checkLatestScreenshot() {
        try {
            val projection = arrayOf(
                MediaStore.Images.Media._ID,
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.DATE_ADDED
            )
            val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"
            val cursor = context.contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                sortOrder
            ) ?: return

            cursor.use {
                if (it.moveToFirst()) {
                    val idIndex = it.getColumnIndex(MediaStore.Images.Media._ID)
                    val nameIndex = it.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
                    val dateIndex = it.getColumnIndex(MediaStore.Images.Media.DATE_ADDED)

                    if (idIndex >= 0) {
                        val id = it.getLong(idIndex)
                        val name = if (nameIndex >= 0) it.getString(nameIndex) ?: "" else ""
                        val dateAdded = if (dateIndex >= 0) it.getLong(dateIndex) else 0

                        val isScreenshot = name.contains("screenshot", ignoreCase = true) ||
                                name.contains("screen_shot", ignoreCase = true) ||
                                name.startsWith("Screenshot_", ignoreCase = true)

                        val nowSec = System.currentTimeMillis() / 1000
                        val isRecent = (nowSec - dateAdded) <= 30

                        if ((isScreenshot || isRecent) && id != lastId && (System.currentTimeMillis() - lastTime) > 1500) {
                            lastId = id
                            lastTime = System.currentTimeMillis()

                            val contentUri = ContentUris.withAppendedId(
                                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                                id
                            )

                            context.contentResolver.openInputStream(contentUri)?.use { stream ->
                                val buffer = ByteArray(16384)
                                val baos = ByteArrayOutputStream()
                                var read: Int
                                while (stream.read(buffer).also { read = it } != -1) {
                                    baos.write(buffer, 0, read)
                                }
                                val bytes = baos.toByteArray()

                                if (bytes.isNotEmpty()) {
                                    // 1. Dispatch to Flutter UI
                                    onScreenshot(name, bytes)

                                    // 2. Direct native broadcast over LAN so Laptop receives it instantly
                                    broadcastScreenshotNative(name, bytes)
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun broadcastScreenshotNative(name: String, bytes: ByteArray) {
        Thread {
            try {
                val prefs = context.getSharedPreferences("ecosystem_peers", Context.MODE_PRIVATE)
                val cachedIps = prefs.getStringSet("known_ips", emptySet()) ?: emptySet()
                val b64 = Base64.encodeToString(bytes, Base64.NO_WRAP)

                val payload = JSONObject().apply {
                    put("type", "image_clipboard")
                    put("sourceDeviceId", "android-screenshot-native")
                    put("payload", JSONObject().apply {
                        put("filename", name)
                        put("data", b64)
                        put("deviceName", Build.MODEL ?: "Android Phone")
                    })
                }.toString()

                // Direct TCP stream to port 51413 for each peer (100% reliable)
                for (ip in cachedIps) {
                    try {
                        val socket = Socket(ip, 51413)
                        socket.soTimeout = 4000
                        val writer = socket.getOutputStream().bufferedWriter(Charsets.UTF_8)
                        writer.write(payload + "\n")
                        writer.flush()
                        socket.close()
                    } catch (_: Exception) {}
                }

                // Fallback default host
                try {
                    val socket = Socket("192.168.1.153", 51413)
                    socket.soTimeout = 4000
                    val writer = socket.getOutputStream().bufferedWriter(Charsets.UTF_8)
                    writer.write(payload + "\n")
                    writer.flush()
                    socket.close()
                } catch (_: Exception) {}
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }.start()
    }
}
