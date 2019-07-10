package eu.sndr.fluttermdnsplugin.handlers;

import io.flutter.plugin.common.EventChannel;
import android.os.Handler;
import android.os.Looper;

public class DiscoveryRunningHandler implements EventChannel.StreamHandler {
    EventChannel.EventSink sink;
    private Handler handler;

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        sink = eventSink;
    }

    @Override
    public void onCancel(Object o) {

    }

    public void onDiscoveryStopped(){
        handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                sink.success(true);
            }
        });
    }

    public void onDiscoveryStarted(){
        handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                sink.success(true);
            }
        });
    }
}
