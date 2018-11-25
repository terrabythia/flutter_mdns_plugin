import 'package:flutter/services.dart';

class ServiceInfo{
  String name;
  String type;
  String host;
  int port;
  ServiceInfo(this.name, this.type, this.host, this.port);

  static ServiceInfo fromMap(Map fromChannel){
    String name = "";
    String type = "";
    String host = "";
    int port = 0;

    if ( fromChannel.containsKey("name") ) {
      name = fromChannel["name"];
    }

    if (fromChannel.containsKey("type")) {
      type = fromChannel["type"];
    }

    if (fromChannel.containsKey("host")) {
      host = fromChannel["host"];
    }

    if (fromChannel.containsKey("port")) {
      port = fromChannel["port"];
    }

    return new ServiceInfo(name, type, host, port);
  }

  @override
  String toString(){
    return "Name: $name, Type: $type, Host: $host, Port: $port";
  }
}
typedef void ServiceInfoCallback(ServiceInfo info);

typedef void IntCallback (int data);
typedef void VoidCallback();

class DiscoveryCallbacks{
  VoidCallback onDiscoveryStarted;
  VoidCallback onDiscoveryStopped;
  ServiceInfoCallback onDiscovered;
  ServiceInfoCallback onResolved;
  DiscoveryCallbacks({
    this.onDiscoveryStarted,
    this.onDiscoveryStopped,
    this.onDiscovered,
    this.onResolved,
  });
}

class FlutterMdnsPlugin {

  static const String NAMESPACE = "eu.sndr.mdns";

  String _serviceType;

  static const MethodChannel _channel =
  const MethodChannel('flutter_mdns_plugin');

  final EventChannel _serviceDiscoveredChannel =
  const EventChannel("$NAMESPACE/discovered");

  final EventChannel _serviceResolvedChannel =
  const EventChannel("$NAMESPACE/resolved");

  final EventChannel _discoveryRunningChannel =
  const EventChannel("$NAMESPACE/running");

  DiscoveryCallbacks discoveryCallbacks;

  FlutterMdnsPlugin({this.discoveryCallbacks}){

    if ( discoveryCallbacks != null ) {
      //Configure all the discovery related callbacks and event channels
      _serviceResolvedChannel.receiveBroadcastStream().listen((data) {
        print("Service resolved ${data.toString()}");
        discoveryCallbacks.onResolved(ServiceInfo.fromMap(data));
      });

      _serviceDiscoveredChannel.receiveBroadcastStream().listen((data) {
        print("Service discovered ${data.toString()}");
        discoveryCallbacks.onDiscovered(ServiceInfo.fromMap(data));
      });

      _discoveryRunningChannel.receiveBroadcastStream().listen((running) {
        print("Discovery Running? $running");
        if (running && discoveryCallbacks.onDiscoveryStarted != null) {
          discoveryCallbacks.onDiscoveryStarted();
        } else if (discoveryCallbacks.onDiscoveryStopped != null) {
          discoveryCallbacks.onDiscoveryStopped();
        }
      });
    }

  }

  startDiscovery(String serviceType) {
    _serviceType = serviceType;
    Map args = new Map();
    args["serviceType"] = _serviceType;
    _channel.invokeMethod("startDiscovery", args);
  }

  stopDiscovery(){
    _channel.invokeMethod("stopDiscovery", new Map());
  }

  restartDiscovery() {
    stopDiscovery();
    startDiscovery(_serviceType);
  }

}
