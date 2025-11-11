package com.example.client

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class AppInstallPlugin(private val context: Context) : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "app_install")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installApp" -> {
                val apkData = call.argument<ByteArray>("apkData")
                val fileName = call.argument<String>("fileName") ?: "app.apk"
                
                if (apkData != null) {
                    try {
                        installApk(apkData, fileName)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.message, null)
                        return
                    }
                } else {
                    result.error("INVALID_ARGS", "APK data is required", null)
                    return
                }
                
                result.success(true)
            }
            "checkInstallPermission" -> {
                val hasPermission = checkInstallPermission()
                result.success(hasPermission)
            }
            else -> result.notImplemented()
        }
    }

    private fun installApk(apkData: ByteArray, fileName: String) {
        // 保存 APK 文件到临时目录
        val cacheDir = context.cacheDir
        val apkFile = File(cacheDir, fileName)
        
        FileOutputStream(apkFile).use { output ->
            output.write(apkData)
        }

        // 检查安装权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!context.packageManager.canRequestPackageInstalls()) {
                // 请求安装权限
                val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                    data = Uri.parse("package:${context.packageName}")
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                throw Exception("需要安装权限，请先授权")
            }
        }

        // 安装 APK
        val intent = Intent(Intent.ACTION_VIEW).apply {
            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Android 7.0+ 使用 FileProvider
                FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    apkFile
                )
            } else {
                Uri.fromFile(apkFile)
            }
            
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        
        context.startActivity(intent)
    }

    private fun checkInstallPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.packageManager.canRequestPackageInstalls()
        } else {
            true // Android 8.0 以下不需要特殊权限
        }
    }
}

