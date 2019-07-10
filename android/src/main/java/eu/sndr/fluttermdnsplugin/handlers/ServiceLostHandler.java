package eu.sndr.fluttermdnsplugin.handlers;

import java.util.Map;
import android.os.Handler;
import android.os.Looper;

import io.flutter.plugin.common.EventChannel;

public class ServiceLostHandler implements EventChannel.StreamHandler {

    EventChannel.EventSink sink;
    private Handler handler;
    Map<String, Object> serviceInfoMap;
    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        sink = eventSink;
    }

    @Override
    public void onCancel(Object o) {

    }

    public void onServiceLost(Map<String, Object> serviceInfoMapGot){
        serviceInfoMap = serviceInfoMapGot;
        handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                sink.success(serviceInfoMap);
            }
        });
    }
}