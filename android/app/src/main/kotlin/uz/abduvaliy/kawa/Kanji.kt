package uz.abduvaliy.kawa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.TimeZone
import kotlin.random.Random

/**
 * Kanji of the Hour: which N5 kanji to show right now.
 *
 * Every local hour gets the next kanji of a shuffled cycle; a new shuffle starts
 * once all of them have been shown, so nothing repeats inside a cycle. It is a
 * pure function of the clock, so the Home Glance and the widget always agree
 * without sharing any state.
 */
object Kanji {
    @Volatile private var cache: JSONArray? = null

    fun all(context: Context): JSONArray =
        cache ?: context.assets.open("kanji.json").bufferedReader(Charsets.UTF_8).use {
            JSONObject(it.readText()).getJSONArray("kanji")
        }.also { cache = it }

    /** Hours since the epoch in local time (so the change lands on :00 locally). */
    fun localHour(nowMillis: Long = System.currentTimeMillis()): Long =
        (nowMillis + TimeZone.getDefault().getOffset(nowMillis)) / 3_600_000L

    /** Index into [all] for local hour [hour]. */
    fun indexFor(hour: Long, count: Int): Int {
        val cycle = Math.floorDiv(hour, count.toLong())
        val pos = Math.floorMod(hour, count.toLong()).toInt()
        val order = (0 until count).shuffled(Random(cycle * 7919L + 17L))
        return order[pos]
    }

    fun now(context: Context, nowMillis: Long = System.currentTimeMillis()): JSONObject {
        val list = all(context)
        return list.getJSONObject(indexFor(localHour(nowMillis), list.length()))
    }

    /** Millis of the next local :00. */
    fun nextHourMillis(nowMillis: Long = System.currentTimeMillis()): Long {
        val offset = TimeZone.getDefault().getOffset(nowMillis)
        return (localHour(nowMillis) + 1) * 3_600_000L - offset
    }
}
