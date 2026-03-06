package com.philrenda.precipitationradialwidget

import android.graphics.*
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.PI

/**
 * Native Canvas renderer for the radial precipitation chart.
 * Must produce output matching the Dart RadialChartPainter pixel-for-pixel.
 *
 * Coordinate system: 100×100 logical units scaled to RENDER_SIZE pixels.
 */
object PrecipitationWidgetRenderer {
    const val RENDER_SIZE = 800
    private const val COORD_SPACE = 100f
    private const val CENTER = 50f
    private const val MINUTE_RING_RADIUS = 30f
    private const val BAR_WIDTH = 4.5f
    private const val HOUR_RING_RADIUS = 42.5f
    private const val HOUR_DOT_RADIUS = 3.2f

    data class MinutelyPoint(
        val precipIntensity: Double,
        val precipProbability: Double
    )

    data class HourlyPoint(
        val precipIntensity: Double,
        val precipProbability: Double,
        val icon: String,
        val summary: String,
        val temperature: Double
    )

    data class WeatherData(
        val minutely: List<MinutelyPoint>,
        val hourly: List<HourlyPoint>,
        val currentTemp: Double,
        val todayHigh: Double,
        val todayLow: Double,
        val windSpeed: Double,
        val currentIcon: String
    )

    fun render(
        data: WeatherData,
        locationName: String,
        isDarkMode: Boolean,
        backgroundColor: Int
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(RENDER_SIZE, RENDER_SIZE, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val scale = RENDER_SIZE / COORD_SPACE

        canvas.save()
        canvas.scale(scale, scale)

        // Background
        canvas.drawRect(0f, 0f, COORD_SPACE, COORD_SPACE, Paint().apply {
            color = backgroundColor
            style = Paint.Style.FILL
        })

        drawBaseRing(canvas, isDarkMode)
        drawMinutelyBars(canvas, data.minutely)
        drawMinuteLabels(canvas, isDarkMode)
        drawBaseHourTicks(canvas, isDarkMode)
        drawHourlyDots(canvas, data.hourly)
        drawHourLabels(canvas, isDarkMode)
        drawCenterContent(canvas, data, isDarkMode)
        drawLocationName(canvas, locationName, isDarkMode)

        canvas.restore()
        return bitmap
    }

    private fun drawBaseRing(canvas: Canvas, isDarkMode: Boolean) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (isDarkMode) PrecipitationColors.BASE_RING_DARK
                    else PrecipitationColors.BASE_RING_LIGHT
            style = Paint.Style.STROKE
            strokeWidth = BAR_WIDTH + 0.5f
        }
        canvas.drawCircle(CENTER, CENTER, MINUTE_RING_RADIUS, paint)
    }

    private fun drawMinutelyBars(canvas: Canvas, minutely: List<MinutelyPoint>) {
        val count = minOf(60, minutely.size)
        for (i in 0 until count) {
            val point = minutely[i]
            if (!PrecipitationColors.isPrecip(point.precipIntensity, point.precipProbability)) {
                continue
            }

            val color = PrecipitationColors.getColor(point.precipIntensity, point.precipProbability)
            val angle = ((i - 15).toFloat() / 60f) * 2f * PI.toFloat()

            val innerR = MINUTE_RING_RADIUS - BAR_WIDTH
            val x1 = CENTER + innerR * cos(angle)
            val y1 = CENTER + innerR * sin(angle)
            val x2 = CENTER + MINUTE_RING_RADIUS * cos(angle)
            val y2 = CENTER + MINUTE_RING_RADIUS * sin(angle)

            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = color
                strokeWidth = BAR_WIDTH + 0.5f
                strokeCap = Paint.Cap.BUTT
            }
            canvas.drawLine(x1, y1, x2, y2, paint)
        }
    }

    private fun drawMinuteLabels(canvas: Canvas, isDarkMode: Boolean) {
        val labels = intArrayOf(0, 10, 20, 30, 40, 50)
        val labelRadius = MINUTE_RING_RADIUS - BAR_WIDTH / 2f

        for (minute in labels) {
            val angle = ((minute - 15).toFloat() / 60f) * 2f * PI.toFloat()
            val x = CENTER + labelRadius * cos(angle)
            val y = CENTER + labelRadius * sin(angle)
            drawOutlinedText(canvas, minute.toString(), x, y, 2.8f, isDarkMode, true)
        }
    }

    private fun drawBaseHourTicks(canvas: Canvas, isDarkMode: Boolean) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (isDarkMode) PrecipitationColors.BASE_RING_DARK
                    else PrecipitationColors.BASE_RING_LIGHT
            style = Paint.Style.FILL
        }
        for (i in 0 until 12) {
            val angle = ((i - 3).toFloat() / 12f) * 2f * PI.toFloat()
            val x = CENTER + HOUR_RING_RADIUS * cos(angle)
            val y = CENTER + HOUR_RING_RADIUS * sin(angle)
            canvas.drawCircle(x, y, HOUR_DOT_RADIUS * 0.7f, paint)
        }
    }

    private fun drawHourlyDots(canvas: Canvas, hourly: List<HourlyPoint>) {
        val hourNow = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)
        val count = minOf(12, hourly.size)

        for (i in 0 until count) {
            val data = hourly[i]
            if (!PrecipitationColors.isPrecip(data.precipIntensity, data.precipProbability)) {
                continue
            }

            val color = PrecipitationColors.getColor(data.precipIntensity, data.precipProbability)
            val actualHour = (hourNow + i) % 24
            val clockPos = actualHour % 12
            val angle = ((clockPos - 3).toFloat() / 12f) * 2f * PI.toFloat()

            val x = CENTER + HOUR_RING_RADIUS * cos(angle)
            val y = CENTER + HOUR_RING_RADIUS * sin(angle)

            canvas.drawCircle(x, y, HOUR_DOT_RADIUS, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = color
                style = Paint.Style.FILL
            })
        }
    }

    private fun drawHourLabels(canvas: Canvas, isDarkMode: Boolean) {
        val hourNow = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)

        for (i in 0 until 12) {
            val actualHour = (hourNow + i) % 24
            val clockPos = actualHour % 12
            val angle = ((clockPos - 3).toFloat() / 12f) * 2f * PI.toFloat()

            val labelR = HOUR_RING_RADIUS + HOUR_DOT_RADIUS + 2f
            val x = CENTER + labelR * cos(angle)
            val y = CENTER + labelR * sin(angle)

            drawOutlinedText(canvas, formatHour(actualHour), x, y, 3.2f, isDarkMode)
        }
    }

    private fun drawCenterContent(canvas: Canvas, data: WeatherData, isDarkMode: Boolean) {
        // Summary
        val summary = getSummary(data)
        val summaryColor = if (isDarkMode) Color.WHITE else Color.parseColor("#333333")
        drawCenteredText(canvas, summary, CENTER, CENTER - 3f, 3.0f, summaryColor)

        // Temperature
        val temp = data.currentTemp.roundToInt()
        val high = data.todayHigh.roundToInt()
        val low = data.todayLow.roundToInt()
        val detailColor = if (isDarkMode) Color.parseColor("#BBBBBB") else Color.parseColor("#555555")
        drawCenteredText(canvas, "$temp°F  H:$high° L:$low°", CENTER, CENTER + 3f, 2.6f, detailColor)

        // Wind
        val wind = data.windSpeed.roundToInt()
        drawCenteredText(canvas, "Wind $wind mph", CENTER, CENTER + 7f, 2.4f, detailColor)
    }

    private fun drawLocationName(canvas: Canvas, name: String, isDarkMode: Boolean) {
        if (name.isEmpty()) return
        drawOutlinedText(canvas, name, 5f, 5f, 3.0f, isDarkMode, isBold = true, centerAlign = false)
    }

    private fun drawOutlinedText(
        canvas: Canvas, text: String, x: Float, y: Float,
        fontSize: Float, isDarkMode: Boolean,
        isBold: Boolean = false, centerAlign: Boolean = true
    ) {
        val textColor = if (isDarkMode) Color.WHITE else Color.BLACK
        val strokeColor = if (isDarkMode) Color.BLACK else Color.WHITE

        val strokePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            this.textSize = fontSize
            this.color = strokeColor
            this.style = Paint.Style.STROKE
            this.strokeWidth = 0.8f
            if (isBold) this.typeface = Typeface.DEFAULT_BOLD
        }

        val fillPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            this.textSize = fontSize
            this.color = textColor
            if (isBold) this.typeface = Typeface.DEFAULT_BOLD
        }

        val bounds = Rect()
        fillPaint.getTextBounds(text, 0, text.length, bounds)

        val drawX = if (centerAlign) x - bounds.width() / 2f else x
        val drawY = if (centerAlign) y + bounds.height() / 2f else y + bounds.height()

        canvas.drawText(text, drawX, drawY, strokePaint)
        canvas.drawText(text, drawX, drawY, fillPaint)
    }

    private fun drawCenteredText(
        canvas: Canvas, text: String, x: Float, y: Float,
        fontSize: Float, color: Int
    ) {
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            this.textSize = fontSize
            this.color = color
            this.textAlign = Paint.Align.CENTER
        }
        canvas.drawText(text, x, y, paint)
    }

    private fun formatHour(hour24: Int): String {
        val hour12 = if (hour24 % 12 == 0) 12 else hour24 % 12
        val ampm = if (hour24 < 12 || hour24 == 24) "a" else "p"
        return "$hour12$ampm"
    }

    /**
     * Simplified weather summary for background rendering.
     * Mirrors the Dart WeatherSummary logic.
     */
    private fun getSummary(data: WeatherData): String {
        if (data.minutely.isEmpty() && data.hourly.isEmpty()) return "No data"
        if (data.minutely.isEmpty()) {
            return if (data.hourly.isNotEmpty()) data.hourly[0].summary else "No data"
        }

        val precipType = getPrecipType(data.hourly)
        var isCurrentlyPrecipitating = false
        var maxIntensity = 0.0
        var actualEndsIn = -1
        var actualStartsIn = -1
        var actualSpellDuration = -1

        if (PrecipitationColors.isPrecip(
                data.minutely[0].precipIntensity,
                data.minutely[0].precipProbability
            )
        ) {
            isCurrentlyPrecipitating = true
            maxIntensity = data.minutely[0].precipIntensity
        }

        if (isCurrentlyPrecipitating) {
            for (i in 1 until data.minutely.size) {
                val pt = data.minutely[i]
                if (PrecipitationColors.isPrecip(pt.precipIntensity, pt.precipProbability)) {
                    if (pt.precipIntensity > maxIntensity) maxIntensity = pt.precipIntensity
                } else {
                    var isDrySpell = true
                    for (j in i until minOf(i + 5, data.minutely.size)) {
                        if (PrecipitationColors.isPrecip(
                                data.minutely[j].precipIntensity,
                                data.minutely[j].precipProbability
                            )
                        ) {
                            isDrySpell = false
                            break
                        }
                    }
                    if (isDrySpell) {
                        actualEndsIn = i
                        break
                    }
                }
            }
            if (actualEndsIn == -1) actualEndsIn = data.minutely.size
        } else {
            var firstPrecipMinute = -1
            var lastPrecipMinute = -1

            for (i in 1 until data.minutely.size) {
                val pt = data.minutely[i]
                if (PrecipitationColors.isPrecip(pt.precipIntensity, pt.precipProbability)) {
                    if (pt.precipIntensity > maxIntensity) maxIntensity = pt.precipIntensity
                    if (firstPrecipMinute == -1) firstPrecipMinute = i
                    lastPrecipMinute = i
                } else if (firstPrecipMinute != -1) {
                    var isDrySpell = true
                    for (j in i until minOf(i + 5, data.minutely.size)) {
                        if (PrecipitationColors.isPrecip(
                                data.minutely[j].precipIntensity,
                                data.minutely[j].precipProbability
                            )
                        ) {
                            isDrySpell = false
                            break
                        }
                    }
                    if (isDrySpell) {
                        actualStartsIn = firstPrecipMinute
                        actualSpellDuration = lastPrecipMinute - firstPrecipMinute + 1
                        break
                    }
                }
            }
            if (firstPrecipMinute != -1 && actualStartsIn == -1) {
                actualStartsIn = firstPrecipMinute
                actualSpellDuration = lastPrecipMinute - firstPrecipMinute + 1
            }
        }

        val intensityDesc = getIntensityDescription(maxIntensity, precipType)

        if (isCurrentlyPrecipitating) {
            return if (actualEndsIn < data.minutely.size) {
                "$intensityDesc ending in $actualEndsIn min"
            } else {
                "$intensityDesc ongoing"
            }
        }

        if (actualStartsIn > 0) {
            return if (actualSpellDuration > 0) {
                "$intensityDesc starting in $actualStartsIn min, for $actualSpellDuration min"
            } else {
                "$intensityDesc starting in $actualStartsIn min"
            }
        }

        return if (data.hourly.isNotEmpty()) data.hourly[0].summary else "No precipitation expected"
    }

    private fun getPrecipType(hourly: List<HourlyPoint>): String {
        if (hourly.isEmpty()) return "Rain"
        val icon = hourly[0].icon.lowercase()
        return when {
            icon.contains("snow") -> "Snow"
            icon.contains("sleet") -> "Sleet"
            icon.contains("rain") || icon.contains("showers") || icon.contains("thunderstorm") -> "Rain"
            else -> "Precipitation"
        }
    }

    private fun getIntensityDescription(intensity: Double, type: String): String {
        return when {
            intensity >= 0.8 -> "Very Heavy $type"
            intensity >= 0.5 -> "Heavy $type"
            intensity >= 0.2 -> "Moderate $type"
            intensity > 0.005 -> "Light $type"
            else -> type
        }
    }

}

typealias TextPaint = android.text.TextPaint
