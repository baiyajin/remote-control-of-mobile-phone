package com.example.client

import android.app.Activity
import android.content.Context
import android.content.Intent
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
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

class ScreenCapturePlugin(private val context: Context) : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var mediaProjection: MediaProjection? = null
    private var mediaProjectionManager: MediaProjectionManager? = null
    private var imageReader: ImageReader? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var screenWidth = 0
    private var screenHeight = 0
    private var pendingResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "screen_capture")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopCapture()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        mediaProjectionManager = activity?.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        mediaProjectionManager = activity?.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
    }

    override fun onDetachedFromActivity() {
        activity = null
        stopCapture()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == ScreenCaptureActivity.REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null && mediaProjectionManager != null) {
                mediaProjection = mediaProjectionManager!!.getMediaProjection(resultCode, data)
                captureScreenFrame()
            } else {
                pendingResult?.error("PERMISSION_DENIED", "用户拒绝了屏幕捕获权限", null)
                pendingResult = null
            }
            return true
        }
        return false
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
                pendingResult = result
                if (mediaProjection == null) {
                    // 请求权限
                    requestPermission()
                } else {
                    captureScreenFrame()
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun requestPermission() {
        activity?.let {
            val intent = Intent(it, ScreenCaptureActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            it.startActivity(intent)
        } ?: run {
            pendingResult?.error("NO_ACTIVITY", "无法获取Activity", null)
            pendingResult = null
        }
    }

    private fun captureScreenFrame() {
        if (mediaProjection == null || mediaProjectionManager == null) {
            pendingResult?.error("NO_PROJECTION", "MediaProjection未初始化", null)
            pendingResult = null
            return
        }

        try {
            val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val displayMetrics = DisplayMetrics()
            windowManager.defaultDisplay.getMetrics(displayMetrics)
            
            screenWidth = displayMetrics.widthPixels
            screenHeight = displayMetrics.heightPixels

            imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)
            
            virtualDisplay = mediaProjection!!.createVirtualDisplay(
                "ScreenCapture",
                screenWidth, screenHeight,
                displayMetrics.densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader!!.surface,
                null, null
            )

            // 等待一帧
            Thread.sleep(100)
            
            val image = imageReader!!.acquireLatestImage()
            if (image != null) {
                val planes = image.planes
                val buffer = planes[0].buffer
                val pixelStride = planes[0].pixelStride
                val rowStride = planes[0].rowStride
                val rowPadding = rowStride - pixelStride * screenWidth

                val bitmap = Bitmap.createBitmap(
                    screenWidth + rowPadding / pixelStride,
                    screenHeight,
                    Bitmap.Config.ARGB_8888
                )
                bitmap.copyPixelsFromBuffer(buffer)
                
                // 裁剪到实际屏幕尺寸
                val finalBitmap = Bitmap.createBitmap(bitmap, 0, 0, screenWidth, screenHeight)
                bitmap.recycle()
                
                val outputStream = ByteArrayOutputStream()
                finalBitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                finalBitmap.recycle()
                image.close()
                
                pendingResult?.success(outputStream.toByteArray())
                pendingResult = null
            } else {
                pendingResult?.error("CAPTURE_FAILED", "无法获取图像", null)
                pendingResult = null
            }
        } catch (e: Exception) {
            pendingResult?.error("CAPTURE_ERROR", e.message, null)
            pendingResult = null
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

