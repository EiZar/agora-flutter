package com.clsm.agora_flutter

import io.flutter.embedding.android.FlutterActivity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.widget.Toast

class MainActivity: FlutterActivity() {

    private lateinit var channel : MethodChannel
    val CHANNEL = "native_communication.channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
//        GeneratedPluginRegistrant.registerWith(flutterEngine)
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            if (call.method == "showNativeView") {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
//                Toast.makeText(this, "Token :: ", Toast.LENGTH_SHORT).show()
            } else {
//                Toast.makeText(this, "No Token :: ", Toast.LENGTH_SHORT).show()
                result.notImplemented()
            }
        }
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).
//        setMethodCallHandler { call, result ->
//            if (call.method == "showNativeView") {
//                Toast.makeText(this, "Token :: ", Toast.LENGTH_SHORT).show()
//            } else {
//                Toast.makeText(this, "No Token :: ", Toast.LENGTH_SHORT).show()
//                result.notImplemented()
//            }
//        }
    }

//    private val CHANNEL = "native_communication.channel"
//    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler{
//            call, result ->
//            when {
//                call.method.equals("showNativeView") -> {
//                    var token = call.argument<String>("token")
//                    Toast.makeText(this, "Token :: " + token, Toast.LENGTH_SHORT).show()
//                    result.success("ActivityStarted")
//                }
//            }
//        }
//    }
}
