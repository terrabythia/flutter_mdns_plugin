package eu.sndr.fluttermdnsplugin.handlers;

import java.util.Map;

import io.flutter.plugin.common.EventChannel;

public class ServiceLostHandler implements EventChannel.StreamHandler {

    EventChannel.EventSink sink;
    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        sink = eventSink;
    }

    @Override
    public void onCancel(Object o) {

    }

    public void onServiceLost(Map<String, Object> serviceInfoMap){
        sink.success(serviceInfoMap);
    }
}