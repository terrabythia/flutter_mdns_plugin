import 'dart:typed_data';
import 'package:flutter/services.dart';

class ServiceInfo {
  Map<String, Uint8List?>? attr;
  String name;
  String type;
  String hostName;
  String address;
  int port;
  ServiceInfo(
      this.attr, this.name, this.type, this.hostName, this.address, this.port);

  static ServiceInfo fromMap(Map fromChannel) {
    Map<String, Uint8List?>? attr;
    String name = "";
    String type = "";
    String hostName = "";
    String address = "";
    int port = 0;

    if (fromChannel.containsKey("attr")) {
      attr = Map<String, Uint8List?>.from(fromChannel["attr"]);
    }

    if (fromChannel.containsKey("name")) {
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

    return ServiceInfo(attr, name, type, hostName, address, port);
  }

  @override
  String toString() {
    return "Name: $name, Type: $type, HostName: $hostName, Address: $address, Port: $port";
  }
}

typedef void ServiceInfoCallback(ServiceInfo info);

typedef void IntCallback(int data);
typedef void VoidCallback();

class DiscoveryCallbacks {
  VoidCallback? onDiscoveryStarted;
  VoidCallback? onDiscoveryStopped;
  ServiceInfoCallback? onDiscovered;
  ServiceInfoCallback? onResolved;
  ServiceInfoCallback? onLost;

  DiscoveryCallbacks({
    this.onDiscoveryStarted,
    this.onDiscoveryStopped,
    this.onDiscovered,
    this.onResolved,
    this.onLost,
  });
}

class FlutterMdnsPlugin {
  static const String NAMESPACE = "eu.sndr.mdns";

  late String _serviceType;

  static const MethodChannel _channel =
      const MethodChannel('flutter_mdns_plugin');

  final EventChannel _serviceDiscoveredChannel =
      const EventChannel("$NAMESPACE/discovered");

  final EventChannel _serviceResolvedChannel =
      const EventChannel("$NAMESPACE/resolved");

  final EventChannel _serviceLostChannel =
      const EventChannel("$NAMESPACE/lost");

  final EventChannel _discoveryRunningChannel =
      const EventChannel("$NAMESPACE/running");

  DiscoveryCallbacks discoveryCallbacks;

  FlutterMdnsPlugin({required this.discoveryCallbacks}) {
    _serviceResolvedChannel.receiveBroadcastStream().listen((data) {
      print("Service resolved ${data.toString()}");
      discoveryCallbacks.onResolved?.call(ServiceInfo.fromMap(data));
    });

    _serviceDiscoveredChannel.receiveBroadcastStream().listen((data) {
      print("Service discovered ${data.toString()}");
      discoveryCallbacks.onDiscovered?.call(ServiceInfo.fromMap(data));
    });

    _serviceLostChannel.receiveBroadcastStream().listen((data) {
      print("Service lost ${data.toString()}");
      discoveryCallbacks.onLost?.call(ServiceInfo.fromMap(data));
    });

    _discoveryRunningChannel.receiveBroadcastStream().listen((running) {
      print("Discovery Running? $running");
      if (running && discoveryCallbacks.onDiscoveryStarted != null) {
        discoveryCallbacks.onDiscoveryStarted?.call();
      } else if (discoveryCallbacks.onDiscoveryStopped != null) {
        discoveryCallbacks.onDiscoveryStopped?.call();
      }
    });
  }

  startDiscovery(String serviceType) {
    _serviceType = serviceType;
    Map args = new Map();
    args["serviceType"] = _serviceType;
    _channel.invokeMethod("startDiscovery", args);
  }

  stopDiscovery() {
    _channel.invokeMethod("stopDiscovery", new Map());
  }

  restartDiscovery() {
    stopDiscovery();
    startDiscovery(_serviceType);
  }
}
