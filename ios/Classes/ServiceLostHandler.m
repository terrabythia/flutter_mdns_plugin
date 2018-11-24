//
// Created by brouwer on 23-11-18.
//

#import "ServiceLostHandler.h"

@implementation ServiceLostHandler {
    FlutterEventSink _eventSink;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    return nil;
}

- (void) onServiceLost:(NSDictionary *)serviceInfoMap {
    _eventSink(serviceInfoMap);
}

- (BOOL) isReady {
    return nil != _eventSink;
}

@end