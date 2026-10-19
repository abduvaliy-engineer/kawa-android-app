package uz.abduvaliy.kawa

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * The Kanji of the Hour widget: home screen, or the lock screen through
 * Good Lock → LockStar. Redrawn at every local :00 by an inexact alarm (no
 * exact-alarm permission needed); whatever time it redraws, it shows the kanji
 * for *that* hour, so a late alarm is only ever late, never wrong.
 */
class KanjiWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val views = render(context)
        ids.forEach { manager.updateAppWidget(it, views) }
        scheduleNext(context)
    }

    override fun onEnabled(context: Context) = scheduleNext(context)

    override fun onDisabled(context: Context) {
        context.getSystemService(AlarmManager::class.java).cancel(tick(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_TICK, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED ->
                refreshAll(context)
        }
    }

    companion object {
        const val ACTION_TICK = "uz.abduvaliy.kawa.KANJI_TICK"
        const val ACTION_OPEN = "uz.abduvaliy.kawa.SHOW_KANJI"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, KanjiWidget::class.java))
            if (ids.isEmpty()) return
            val views = render(context)
            ids.forEach { manager.updateAppWidget(it, views) }
            scheduleNext(context)
        }

        private fun render(context: Context): RemoteViews {
            val k = Kanji.now(context)
            val ex = k.getJSONArray("ex").optJSONObject(0)
            return RemoteViews(context.packageName, R.layout.kanji_widget).apply {
                setTextViewText(R.id.kanji, k.getString("k"))
                setTextViewText(R.id.reading, "${k.getString("ro")}・${k.getString("r")}")
                setTextViewText(R.id.meaning, k.getString("m"))
                setTextViewText(
                    R.id.example,
                    ex?.let { "${it.getString("w")}・${it.getString("m")}" } ?: ""
                )
                setOnClickPendingIntent(R.id.root, open(context))
            }
        }

        /** Tap → Kawa opens and shows the Kanji Card. */
        private fun open(context: Context): PendingIntent = PendingIntent.getActivity(
            context, 1,
            Intent(context, MainActivity::class.java)
                .setAction(ACTION_OPEN)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        private fun tick(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context, 0,
            Intent(context, KanjiWidget::class.java).setAction(ACTION_TICK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        private fun scheduleNext(context: Context) {
            context.getSystemService(AlarmManager::class.java).setAndAllowWhileIdle(
                AlarmManager.RTC, Kanji.nextHourMillis() + 1_000L, tick(context)
            )
        }
    }
}
