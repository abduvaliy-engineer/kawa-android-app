package uz.abduvaliy.kawa

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.LauncherApps
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.UserHandle
import android.provider.AlarmClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Kawa's only native code: the Android-only parts Flutter can't reach.
 * Channel "kawa/apps" answers calls; "kawa/events" pushes "apps" / "alarm" / "home".
 */
class MainActivity : FlutterActivity() {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private val launcherApps by lazy { getSystemService(LauncherApps::class.java) }
    private val user: UserHandle get() = Process.myUserHandle()
    private val prefs by lazy { getSharedPreferences("kawa", Context.MODE_PRIVATE) }

    // Draw the wallpaper behind a transparent Flutter surface.
    override fun getBackgroundMode() = BackgroundMode.transparent

    private fun emit(event: String) = main.post { sink?.success(event) }

    private val packages = object : LauncherApps.Callback() {
        override fun onPackageRemoved(p: String, u: UserHandle) { emit("apps") }
        override fun onPackageAdded(p: String, u: UserHandle) { emit("apps") }
        override fun onPackageChanged(p: String, u: UserHandle) { emit("apps") }
        override fun onPackagesAvailable(p: Array<out String>, u: UserHandle, r: Boolean) { emit("apps") }
        override fun onPackagesUnavailable(p: Array<out String>, u: UserHandle, r: Boolean) { emit("apps") }
    }

    private val alarmChanged = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) { emit("alarm") }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        launcherApps.registerCallback(packages, main)
        val filter = IntentFilter(AlarmManager.ACTION_NEXT_ALARM_CLOCK_CHANGED)
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(alarmChanged, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(alarmChanged, filter)
        }
    }

    override fun onDestroy() {
        launcherApps.unregisterCallback(packages)
        unregisterReceiver(alarmChanged)
        io.shutdown()
        super.onDestroy()
    }

    // singleTask HOME activity: pressing home while we're on top lands here.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == Intent.ACTION_MAIN) emit("home")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        EventChannel(messenger, "kawa/events").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, events: EventChannel.EventSink) { sink = events }
            override fun onCancel(args: Any?) { sink = null }
        })

        MethodChannel(messenger, "kawa/apps").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "apps" -> io.execute {
                        val list = launcherApps.getActivityList(null, user)
                            .filter { it.componentName.packageName != packageName }
                            .map {
                                mapOf(
                                    "package" to it.componentName.packageName,
                                    "component" to it.componentName.flattenToString(),
                                    "label" to it.label.toString(),
                                )
                            }
                        main.post { result.success(list) }
                    }

                    // Favorites live in plain SharedPreferences: one package name per line.
                    "getFavorites" -> result.success(
                        prefs.getString("favorites", "")!!.split("\n").filter { it.isNotBlank() }
                    )

                    "setFavorites" -> {
                        val list = call.argument<List<String>>("favorites") ?: emptyList()
                        prefs.edit().putString("favorites", list.joinToString("\n")).apply()
                        result.success(null)
                    }

                    "launch" -> {
                        launcherApps.startMainActivity(component(call.argument("component")), user, null, null)
                        result.success(null)
                    }

                    "appInfo" -> {
                        launcherApps.startAppDetailsActivity(component(call.argument("component")), user, null, null)
                        result.success(null)
                    }

                    "uninstall" -> {
                        val pkg = call.argument<String>("package")!!
                        startActivity(
                            Intent(Intent.ACTION_DELETE, Uri.parse("package:$pkg"))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }

                    "nextAlarm" -> result.success(
                        getSystemService(AlarmManager::class.java).nextAlarmClock?.triggerTime
                    )

                    "openClock" -> { openClock(alarms = false); result.success(null) }
                    "openAlarms" -> { openClock(alarms = true); result.success(null) }

                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("kawa", e.message, null)
            }
        }
    }

    private fun component(flat: String?): ComponentName =
        ComponentName.unflattenFromString(flat ?: "") ?: error("bad component: $flat")

    /** Clock tap opens the clock app; alarm tap opens its alarms screen. */
    private fun openClock(alarms: Boolean) {
        val showAlarms = Intent(AlarmClock.ACTION_SHOW_ALARMS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (alarms) {
            startActivity(showAlarms)
            return
        }
        val pkg = packageManager.resolveActivity(showAlarms, 0)?.activityInfo?.packageName
        val launch = pkg?.let { packageManager.getLaunchIntentForPackage(it) }
        startActivity(launch?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) ?: showAlarms)
    }
}
