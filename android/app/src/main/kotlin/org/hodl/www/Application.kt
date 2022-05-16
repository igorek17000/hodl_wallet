import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin

class Application : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {

    override fun registerWith(registry: PluginRegistry?) {
        FlutterLocalNotificationsPlugin.registerWith(registry?.registrarFor("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin"))
        SharedPreferencesPlugin.registerWith(registry?.registrarFor("io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin"));
    }

}