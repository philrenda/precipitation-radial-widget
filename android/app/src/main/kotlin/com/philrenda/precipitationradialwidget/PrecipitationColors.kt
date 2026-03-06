package com.philrenda.precipitationradialwidget

import android.graphics.Color

/**
 * Kotlin mirror of the Dart PrecipitationColors class.
 * Thresholds and colors MUST match exactly.
 */
object PrecipitationColors {
    const val PROB_THRESHOLD = 0.10
    const val INTENSITY_THRESHOLD = 0.005

    val NO_PRECIP = Color.parseColor("#CCCCCC")
    val TRACE = Color.parseColor("#AED581")
    val VERY_LIGHT = Color.parseColor("#9CCC65")
    val LIGHT = Color.parseColor("#66BB6A")
    val MODERATE = Color.parseColor("#FFEE58")
    val HEAVY = Color.parseColor("#FFCA28")
    val VERY_HEAVY = Color.parseColor("#FF7043")
    val EXTREME = Color.parseColor("#E53935")

    val BASE_RING_DARK = Color.parseColor("#444444")
    val BASE_RING_LIGHT = Color.parseColor("#E0E0E0")

    fun getColor(intensity: Double, probability: Double): Int {
        if (probability < PROB_THRESHOLD || intensity < INTENSITY_THRESHOLD) {
            return NO_PRECIP
        }
        return when {
            intensity < 0.01 -> TRACE
            intensity < 0.05 -> VERY_LIGHT
            intensity < 0.15 -> LIGHT
            intensity < 0.30 -> MODERATE
            intensity < 0.60 -> HEAVY
            intensity < 1.0 -> VERY_HEAVY
            else -> EXTREME
        }
    }

    fun isPrecip(intensity: Double, probability: Double): Boolean {
        return intensity >= INTENSITY_THRESHOLD && probability >= PROB_THRESHOLD
    }
}
