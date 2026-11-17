package com.angelosonsy.fatorty

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Widget الشاشة الرئيسية — بيعرض لحد 3 فواتير (الأقرب استحقاقاً
/// الأول). البيانات بتتحدّث من الـ Flutter side
/// (lib/services/widget_service.dart) في كل مرة الفواتير تتغيّر
/// (إضافة/تعديل/حذف/أرشفة)، مش بس كل ساعة زي الـ updatePeriodMillis
/// الافتراضي في fatorty_widget_info.xml (ده مجرد شبكة أمان احتياطية).
class FatortyWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val MAX_ROWS = 3
        private val ROW_IDS = intArrayOf(
            R.id.widget_row_0,
            R.id.widget_row_1,
            R.id.widget_row_2
        )
        private val NAME_IDS = intArrayOf(
            R.id.widget_bill_name_0,
            R.id.widget_bill_name_1,
            R.id.widget_bill_name_2
        )
        private val SUBTITLE_IDS = intArrayOf(
            R.id.widget_bill_subtitle_0,
            R.id.widget_bill_subtitle_1,
            R.id.widget_bill_subtitle_2
        )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.fatorty_widget).apply {
                var anyRowVisible = false

                for (i in 0 until MAX_ROWS) {
                    val billName = widgetData.getString("widget_bill_name_$i", null)
                    val billSubtitle = widgetData.getString("widget_bill_subtitle_$i", null)

                    if (!billName.isNullOrEmpty()) {
                        anyRowVisible = true
                        setTextViewText(NAME_IDS[i], billName)
                        setTextViewText(SUBTITLE_IDS[i], billSubtitle ?: "")
                        setViewVisibility(ROW_IDS[i], View.VISIBLE)
                    } else {
                        setViewVisibility(ROW_IDS[i], View.GONE)
                    }
                }

                setViewVisibility(
                    R.id.widget_empty_text,
                    if (anyRowVisible) View.GONE else View.VISIBLE
                )

                // الضغط على الـ widget بيفتح التطبيق
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
