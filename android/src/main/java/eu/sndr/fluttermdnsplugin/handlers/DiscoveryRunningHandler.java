package eu.sndr.fluttermdnsplugin.handlers;

import io.flutter.plugin.common.EventChannel;

public class DiscoveryRunningHandler implements EventChannel.StreamHandler {
    EventChannel.EventSink sink;
    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        sink = eventSink;
    }

    @Override
    public void onCancel(Object o) {

    }

    public void onDiscoveryStopped(){
        sink.success(false);
    }

    public void onDiscoveryStarted(){
        sink.success(true);
    }
}
