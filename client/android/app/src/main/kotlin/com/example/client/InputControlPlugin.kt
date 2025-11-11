package com.example.client

import android.content.Context
import android.os.Build
import android.view.MotionEvent
import android.view.KeyEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.Method

class InputControlPlugin(private val context: Context) : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "input_control")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "moveMouse" -> {
                val x = (call.argument<Double>("x") ?: 0.0).toFloat()
                val y = (call.argument<Double>("y") ?: 0.0).toFloat()
                injectTouchEvent(MotionEvent.ACTION_MOVE, x, y)
                result.success(null)
            }
            "clickMouse" -> {
                val x = (call.argument<Double>("x") ?: 0.0).toFloat()
                val y = (call.argument<Double>("y") ?: 0.0).toFloat()
                val button = call.argument<String>("button") ?: "left"
                val action = if (button == "right") MotionEvent.ACTION_BUTTON_PRESS else MotionEvent.ACTION_DOWN
                injectTouchEvent(action, x, y)
                injectTouchEvent(MotionEvent.ACTION_UP, x, y)
                result.success(null)
            }
            "pressKey" -> {
                val key = call.argument<String>("key") ?: ""
                injectKeyEvent(key, true)
                injectKeyEvent(key, false)
                result.success(null)
            }
            "typeText" -> {
                val text = call.argument<String>("text") ?: ""
                for (char in text) {
                    injectKeyEvent(char.toString(), true)
                    injectKeyEvent(char.toString(), false)
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun injectTouchEvent(action: Int, x: Float, y: Float) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ 需要使用 AccessibilityService 或系统权限
                // 这里简化处理
            } else {
                // 使用反射注入触摸事件（需要系统权限）
                val service = context.getSystemService(Context.INPUT_SERVICE)
                val method: Method = service.javaClass.getMethod(
                    "injectInputEvent",
                    android.view.InputEvent::class.java,
                    Int::class.javaPrimitiveType
                )
                val event = MotionEvent.obtain(
                    System.currentTimeMillis(),
                    System.currentTimeMillis(),
                    action,
                    x,
                    y,
                    0
                )
                method.invoke(service, event, 0)
            }
        } catch (e: Exception) {
            // 需要系统权限才能注入事件
        }
    }

    private fun injectKeyEvent(key: String, pressed: Boolean) {
        try {
            val service = context.getSystemService(Context.INPUT_SERVICE)
            val method: Method = service.javaClass.getMethod(
                "injectInputEvent",
                android.view.InputEvent::class.java,
                Int::class.javaPrimitiveType
            )
            val keyCode = getKeyCode(key)
            val event = KeyEvent(
                if (pressed) KeyEvent.ACTION_DOWN else KeyEvent.ACTION_UP,
                keyCode
            )
            method.invoke(service, event, 0)
        } catch (e: Exception) {
            // 需要系统权限
        }
    }

    private fun getKeyCode(key: String): Int {
        return when (key.lowercase()) {
            "enter" -> KeyEvent.KEYCODE_ENTER
            "backspace" -> KeyEvent.KEYCODE_DEL
            "space" -> KeyEvent.KEYCODE_SPACE
            "tab" -> KeyEvent.KEYCODE_TAB
            "escape" -> KeyEvent.KEYCODE_ESCAPE
            else -> {
                if (key.length == 1) {
                    key[0].code
                } else {
                    KeyEvent.KEYCODE_UNKNOWN
                }
            }
        }
    }
}

