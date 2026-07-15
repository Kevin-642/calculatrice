package com.kevincreation.calculatricecosmique

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
    private val channelName = "com.kevincreation.calculatricecosmique/preferences"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val preferences = getSharedPreferences("calculator_preferences", Context.MODE_PRIVATE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "load" -> {
                        val historyJson = preferences.getString("history", "[]") ?: "[]"
                        val historyArray = JSONArray(historyJson)
                        val history = List(historyArray.length()) { index ->
                            historyArray.getString(index)
                        }
                        result.success(
                            mapOf(
                                "history" to history,
                                "highContrast" to preferences.getBoolean("highContrast", false),
                                "radians" to preferences.getBoolean("radians", false),
                                "memory" to preferences.getFloat("memory", 0f).toDouble(),
                            ),
                        )
                    }

                    "save" -> {
                        val history = call.argument<List<String>>("history") ?: emptyList()
                        preferences.edit()
                            .putString("history", JSONArray(history).toString())
                            .putBoolean(
                                "highContrast",
                                call.argument<Boolean>("highContrast") ?: false,
                            )
                            .putBoolean("radians", call.argument<Boolean>("radians") ?: false)
                            .putFloat(
                                "memory",
                                (call.argument<Double>("memory") ?: 0.0).toFloat(),
                            )
                            .apply()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
