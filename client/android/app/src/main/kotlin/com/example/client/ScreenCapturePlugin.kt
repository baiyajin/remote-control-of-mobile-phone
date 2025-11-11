package com.example.client

import android.content.Context
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.util.DisplayMetrics
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

class ScreenCapturePlugin(private val context: Context) : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var mediaProjection: MediaProjection? = null
    private var imageReader: ImageReader? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var screenWidth = 0
    private var screenHeight = 0

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "screen_capture")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopCapture()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getScreenSize" -> {
                val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val displayMetrics = DisplayMetrics()
                windowManager.defaultDisplay.getMetrics(displayMetrics)
                val size = mapOf(
                    "width" to displayMetrics.widthPixels,
                    "height" to displayMetrics.heightPixels
                )
                result.success(size)
            }
            "captureScreen" -> {
                try {
                    val bitmap = captureScreenBitmap()
                    if (bitmap != null) {
                        val outputStream = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                        result.success(outputStream.toByteArray())
                    } else {
                        result.error("CAPTURE_FAILED", "无法捕获屏幕", null)
                    }
                } catch (e: Exception) {
                    result.error("CAPTURE_ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun captureScreenBitmap(): Bitmap? {
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val displayMetrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(displayMetrics)
        
        screenWidth = displayMetrics.widthPixels
        screenHeight = displayMetrics.heightPixels

        imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)
        
        // 注意：实际使用时需要通过 MediaProjectionManager 获取权限
        // 这里简化处理，使用反射或系统服务
        try {
            val bitmap = Bitmap.createBitmap(screenWidth, screenHeight, Bitmap.Config.ARGB_8888)
            // 使用系统服务捕获（需要权限）
            // 实际实现需要使用 MediaProjection API
            return bitmap
        } catch (e: Exception) {
            return null
        }
    }

    private fun stopCapture() {
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        virtualDisplay = null
        imageReader = null
        mediaProjection = null
    }
}

