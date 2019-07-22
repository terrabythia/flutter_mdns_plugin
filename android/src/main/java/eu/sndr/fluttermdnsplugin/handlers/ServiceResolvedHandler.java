package eu.sndr.fluttermdnsplugin.handlers;

import android.os.Handler;
import android.os.Looper;

import java.util.Map;

import io.flutter.plugin.common.EventChannel;

public class ServiceResolvedHandler implements EventChannel.StreamHandler {

    private Handler handler;
    EventChannel.EventSink sink;

    public ServiceResolvedHandler(){
        this.handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        sink = eventSink;
    }

    @Override
    public void onCancel(Object o) {

    }

    public void onServiceResolved(Map<String, Object> serviceInfoMap) {
        handler.post(() -> sink.success(serviceInfoMap));
    }

}
