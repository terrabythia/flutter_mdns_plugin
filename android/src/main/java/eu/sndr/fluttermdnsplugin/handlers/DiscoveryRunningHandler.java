package eu.sndr.fluttermdnsplugin.handlers;

import android.os.Handler;
import android.os.Looper;

import io.flutter.plugin.common.EventChannel;

public class DiscoveryRunningHandler implements EventChannel.StreamHandler {

    private Handler handler;
    EventChannel.EventSink sink;

    public DiscoveryRunningHandler(){
        this.handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        sink = eventSink;
    }

    @Override
    public void onCancel(Object o) {

    }

    public void onDiscoveryStopped(){
        handler.post(() -> sink.success(false));
    }

    public void onDiscoveryStarted(){
        handler.post(() -> sink.success(true));
    }
}
