//
// Created by Sander Bruggeman on 24-07-18.
//

#import "ServiceDiscoveredHandler.h"

@implementation ServiceDiscoveredHandler {

    FlutterEventSink _eventSink;

}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    return nil;
}

- (void) onServiceDiscovered:(NSDictionary *)serviceInfoMap {
    _eventSink(serviceInfoMap);
}

- (BOOL) isReady {
    return nil != _eventSink;
}

@end