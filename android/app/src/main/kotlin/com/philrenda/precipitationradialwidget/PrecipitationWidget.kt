package com.philrenda.precipitationradialwidget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import androidx.work.*
import java.io.File
import java.util.concurrent.TimeUnit

class PrecipitationWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleWorker(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
    }

    companion object {
        const val WORK_NAME = "precipitation_widget_update"
        private const val MIN_INTERVAL_MINUTES = 15L

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.precipitation_widget)

            // Load the rendered bitmap from internal storage
            val chartFile = File(context.filesDir, "widget_chart.png")
            if (chartFile.exists()) {
                val bitmap = BitmapFactory.decodeFile(chartFile.absolutePath)
                if (bitmap != null) {
                    views.setImageViewBitmap(R.id.widget_image, bitmap)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun scheduleWorker(context: Context) {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            // Use the shorter of the two intervals, clamped to 15 min minimum
            val minutelyInterval = prefs.getLong("flutter.minutely_interval_seconds", 600)
            val hourlyInterval = prefs.getLong("flutter.hourly_interval_seconds", 1800)
            val intervalMinutes = maxOf(
                MIN_INTERVAL_MINUTES,
                minOf(minutelyInterval, hourlyInterval) / 60
            )

            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val workRequest = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                intervalMinutes, TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                workRequest
            )
        }
    }
}
