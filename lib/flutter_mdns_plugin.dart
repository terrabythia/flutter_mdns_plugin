import 'dart:typed_data';
import 'package:flutter/services.dart';

class ServiceInfo{
  Map<String, Uint8List> attr;
  String name;
  String type;
  String hostName;
  String address;
  int port;
  ServiceInfo(this.attr, this.name, this.type, this.hostName, this.address, this.port);

  static ServiceInfo fromMap(Map fromChannel){
    Map<String, Uint8List> attr;
    String name = "";
    String type = "";
    String hostName = "";
    String address = "";
    int port = 0;

    if (fromChannel.containsKey("attr") ) {
      attr = fromChannel["attr"];
    }

    if (fromChannel.containsKey("name") ) {
      name = fromChannel["name"];
    }

    if (fromChannel.containsKey("type")) {
      type = fromChannel["type"];
    }

    if (fromChannel.containsKey("hostName")) {
      hostName = fromChannel["hostName"];
    }

    if (fromChannel.containsKey("address")) {
      address = fromChannel["address"];
    }

    if (fromChannel.containsKey("port")) {
      port = fromChannel["port"];
    }

    return new ServiceInfo(attr, name, type, hostName, address, port);
  }

  @override
  String toString(){
    return "Name: $name, Type: $type, HostName: $hostName, Address: $address, Port: $port";
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
    Map args = new Map();
    args["serviceType"] = serviceType;
    _channel.invokeMethod("startDiscovery", args);
  }

  stopDiscovery(){
    _channel.invokeMethod("stopDiscovery", new Map());
  }

}
