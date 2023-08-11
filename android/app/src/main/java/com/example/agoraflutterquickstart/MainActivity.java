package com.example.agoraflutter;

import io.flutter.embedding.android.FlutterActivity;
import androidx.annotation.NonNull;
import android.os.Bundle;
import android.content.Intent;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.view.FlutterMain;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "native_communication.channel";
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            // Note: this method is invoked on the main thread.
                            // TODO
                            if (call.method.equals("showNativeView")) {
                                Intent intent = new Intent(this, NativeAndroidActivity.class);
                                startActivity(intent);
                                String message ="Life Changed Java";
                                result.success(message);
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }
}
