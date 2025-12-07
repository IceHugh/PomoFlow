package com.example.flow.flow

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import com.example.flow.flow.R
import java.io.File

class TimerWidgetProvider : HomeWidgetProvider() {
    companion object {
        // Cache widget states to avoid unnecessary updates
        private val widgetStates = mutableMapOf<Int, WidgetState>()
    }
    
    data class WidgetState(
        val time: String,
        val progress: Int,
        val isRunning: Boolean,
        val status: String,
        val contentColor: Int,
        val backgroundColor: Int,
        val backgroundType: String
    )
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                // --- Data Retrieval ---
                val time = widgetData.getString("time", "25:00") ?: "25:00"
                val progress = widgetData.getInt("progress", 100)
                val isRunning = widgetData.getBoolean("isRunning", false)
                val status = widgetData.getString("status", "Focusing") ?: "Focusing"
                
                // Style Data
                val contentColor = getColorFromPrefs(widgetData, "contentColor", Color.WHITE)
                val backgroundColor = getColorFromPrefs(widgetData, "backgroundColor", 0xFF2196F3.toInt())
                val backgroundType = widgetData.getString("backgroundType", "default") ?: "default"
                
                // Create current state
                val currentState = WidgetState(
                    time, progress, isRunning, status,
                    contentColor, backgroundColor, backgroundType
                )
                
                // Get cached state
                val cachedState = widgetStates[widgetId]
                
                // Only update if state changed
                if (cachedState == null || cachedState != currentState) {
                    val views = RemoteViews(context.packageName, R.layout.widget_layout)
                    
                    // Update only changed properties
                    if (cachedState == null || cachedState.time != time || cachedState.contentColor != contentColor) {
                        views.setTextViewText(R.id.timer_display, time)
                        views.setTextColor(R.id.timer_display, contentColor)
                    }
                    
                    if (cachedState == null || cachedState.progress != progress) {
                        views.setProgressBar(R.id.widget_progress_bar, 100, progress, false)
                    }
                    
                    // Icon & Overlay Logic - only show pause button during Focus mode
                    val isFocusMode = status == "Focusing"
                    val shouldShowPause = !isRunning && isFocusMode
                    
                    if (cachedState == null || 
                        cachedState.isRunning != isRunning || 
                        cachedState.status != status ||
                        cachedState.contentColor != contentColor) {
                        
                        if (shouldShowPause) {
                            views.setViewVisibility(R.id.widget_action_icon, View.VISIBLE)
                            views.setImageViewResource(R.id.widget_action_icon, R.drawable.ic_pause_state)
                            views.setInt(R.id.widget_action_icon, "setColorFilter", contentColor)
                            views.setViewVisibility(R.id.widget_pause_overlay, View.VISIBLE)
                        } else {
                            views.setViewVisibility(R.id.widget_action_icon, View.INVISIBLE)
                            views.setViewVisibility(R.id.widget_pause_overlay, View.GONE)
                        }
                    }
                    
                    // Background Logic
                    if (cachedState == null || 
                        cachedState.backgroundType != backgroundType || 
                        cachedState.backgroundColor != backgroundColor) {
                        
                        if (backgroundType == "color") {
                            views.setInt(R.id.widget_background_layer, "setColorFilter", backgroundColor)
                        } else {
                            views.setInt(R.id.widget_background_layer, "setColorFilter", 0)
                        }
                    }
                    
                    // Set up interactions (only on first update or when needed)
                    if (cachedState == null) {
                        val intent = Intent(context, MainActivity::class.java)
                        intent.action = Intent.ACTION_MAIN
                        intent.addCategory(Intent.CATEGORY_LAUNCHER)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        
                        val openAppIntent = PendingIntent.getActivity(
                            context,
                            0,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent)

                        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                            context,
                            Uri.parse("pomoflow://toggle")
                        )
                        views.setOnClickPendingIntent(R.id.timer_container, backgroundIntent)
                    }
                    
                    appWidgetManager.partiallyUpdateAppWidget(widgetId, views)
                    
                    // Update cache
                    widgetStates[widgetId] = currentState
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    private fun getColorFromPrefs(prefs: SharedPreferences, key: String, defaultVal: Int): Int {
        return try {
            prefs.getInt(key, defaultVal)
        } catch (e: Exception) {
            try {
                prefs.getLong(key, defaultVal.toLong()).toInt()
            } catch (e2: Exception) {
                defaultVal
            }
        }
    }
}
