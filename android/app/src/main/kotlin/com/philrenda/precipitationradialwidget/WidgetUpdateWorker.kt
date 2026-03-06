package com.philrenda.precipitationradialwidget

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Color
import android.location.LocationManager
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.google.gson.Gson
import com.google.gson.JsonObject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.TimeUnit

class WidgetUpdateWorker(
    private val context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    private val gson = Gson()

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )

            val apiKey = prefs.getString("flutter.api_key", "") ?: ""
            if (apiKey.isEmpty()) return@withContext Result.failure()

            var lat = getDouble(prefs, "flutter.latitude", 0.0)
            var lon = getDouble(prefs, "flutter.longitude", 0.0)
            val useDeviceLocation = prefs.getBoolean("flutter.use_device_location", false)
            val locationName = prefs.getString("flutter.location_name", "") ?: ""
            val bgColorValue = prefs.getLong("flutter.background_color", Color.BLACK.toLong()).toInt()
            val transparent = prefs.getBoolean("flutter.transparent_background", false)
            val themeMode = prefs.getString("flutter.theme_mode", "system") ?: "system"

            // One-shot GPS if enabled
            if (useDeviceLocation) {
                val gpsLocation = getGpsLocation()
                if (gpsLocation != null) {
                    lat = gpsLocation.first
                    lon = gpsLocation.second
                    // Save updated location back to prefs
                    prefs.edit()
                        .putLong("flutter.latitude", java.lang.Double.doubleToRawLongBits(lat))
                        .putLong("flutter.longitude", java.lang.Double.doubleToRawLongBits(lon))
                        .apply()
                }
            }

            if (lat == 0.0 && lon == 0.0) return@withContext Result.failure()

            // Fetch minutely data
            val minutelyJson = fetchJson(
                "https://api.pirateweather.net/forecast/$apiKey/$lat,$lon?exclude=hourly,daily,current,alerts,flags&units=us"
            ) ?: return@withContext Result.retry()

            // Fetch hourly data
            val hourlyJson = fetchJson(
                "https://api.pirateweather.net/forecast/$apiKey/$lat,$lon?exclude=minutely,daily,alerts,flags&units=us"
            ) ?: return@withContext Result.retry()

            // Parse minutely
            val minutelyData = mutableListOf<PrecipitationWidgetRenderer.MinutelyPoint>()
            minutelyJson.getAsJsonObject("minutely")?.getAsJsonArray("data")?.forEach { elem ->
                val obj = elem.asJsonObject
                minutelyData.add(
                    PrecipitationWidgetRenderer.MinutelyPoint(
                        precipIntensity = obj.get("precipIntensity")?.asDouble ?: 0.0,
                        precipProbability = obj.get("precipProbability")?.asDouble ?: 0.0
                    )
                )
            }

            // Parse hourly + current
            val hourlyDataList = mutableListOf<PrecipitationWidgetRenderer.HourlyPoint>()
            hourlyJson.getAsJsonObject("hourly")?.getAsJsonArray("data")?.let { arr ->
                for (i in 0 until minOf(24, arr.size())) {
                    val obj = arr[i].asJsonObject
                    hourlyDataList.add(
                        PrecipitationWidgetRenderer.HourlyPoint(
                            precipIntensity = obj.get("precipIntensity")?.asDouble ?: 0.0,
                            precipProbability = obj.get("precipProbability")?.asDouble ?: 0.0,
                            icon = obj.get("icon")?.asString ?: "cloudy",
                            summary = obj.get("summary")?.asString ?: "",
                            temperature = obj.get("temperature")?.asDouble ?: 0.0
                        )
                    )
                }
            }

            val currently = hourlyJson.getAsJsonObject("currently")
            val currentTemp = currently?.get("temperature")?.asDouble ?: 0.0
            val windSpeed = currently?.get("windSpeed")?.asDouble ?: 0.0
            val currentIcon = currently?.get("icon")?.asString ?: "cloudy"

            // Calculate today's high/low
            var high = Double.NEGATIVE_INFINITY
            var low = Double.POSITIVE_INFINITY
            for (h in hourlyDataList) {
                if (h.temperature > high) high = h.temperature
                if (h.temperature < low) low = h.temperature
            }
            if (high == Double.NEGATIVE_INFINITY) high = currentTemp
            if (low == Double.POSITIVE_INFINITY) low = currentTemp

            val weatherData = PrecipitationWidgetRenderer.WeatherData(
                minutely = minutelyData,
                hourly = hourlyDataList,
                currentTemp = currentTemp,
                todayHigh = high,
                todayLow = low,
                windSpeed = windSpeed,
                currentIcon = currentIcon
            )

            // Determine dark mode
            val isDarkMode = when (themeMode) {
                "dark" -> true
                "light" -> false
                else -> {
                    val uiMode = context.resources.configuration.uiMode and
                            android.content.res.Configuration.UI_MODE_NIGHT_MASK
                    uiMode == android.content.res.Configuration.UI_MODE_NIGHT_YES
                }
            }

            val bgColor = if (transparent) Color.TRANSPARENT else bgColorValue

            // Render bitmap
            val bitmap = PrecipitationWidgetRenderer.render(
                weatherData, locationName, isDarkMode, bgColor
            )

            // Save to file
            val file = File(context.filesDir, "widget_chart.png")
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }

            // Update all widget instances
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val widgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, PrecipitationWidget::class.java)
            )
            for (id in widgetIds) {
                PrecipitationWidget.updateWidget(context, appWidgetManager, id)
            }

            // Also save weather data as JSON for Flutter to read
            val weatherJson = gson.toJson(mapOf(
                "minutely" to minutelyData.map { mapOf("precipIntensity" to it.precipIntensity, "precipProbability" to it.precipProbability, "time" to 0, "precipIntensityError" to 0.0, "precipType" to "none") },
                "hourly" to hourlyDataList.map { mapOf("precipIntensity" to it.precipIntensity, "precipProbability" to it.precipProbability, "icon" to it.icon, "summary" to it.summary, "temperature" to it.temperature, "time" to 0) },
                "currentTemp" to currentTemp,
                "todayHigh" to high,
                "todayLow" to low,
                "windSpeed" to windSpeed,
                "currentIcon" to currentIcon,
                "lastUpdated" to java.time.Instant.now().toString()
            ))
            prefs.edit().putString("flutter.weather_data", weatherJson).apply()

            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            Result.retry()
        }
    }

    private fun fetchJson(url: String): JsonObject? {
        val request = Request.Builder().url(url).build()
        val response = client.newCall(request).execute()
        if (!response.isSuccessful) return null
        val body = response.body?.string() ?: return null
        return gson.fromJson(body, JsonObject::class.java)
    }

    private fun getGpsLocation(): Pair<Double, Double>? {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return null
        }

        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val location = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            ?: locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            ?: return null

        return Pair(location.latitude, location.longitude)
    }

    /**
     * SharedPreferences stores doubles as longs (raw bits) via Flutter.
     */
    private fun getDouble(prefs: android.content.SharedPreferences, key: String, default: Double): Double {
        return try {
            java.lang.Double.longBitsToDouble(prefs.getLong(key, java.lang.Double.doubleToRawLongBits(default)))
        } catch (e: ClassCastException) {
            default
        }
    }
}
