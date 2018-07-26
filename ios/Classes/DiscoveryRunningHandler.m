//
// Created by Sander Bruggeman on 24-07-18.
//

#import "DiscoveryRunningHandler.h"

@interface DiscoveryRunningHandler()
@end

@implementation DiscoveryRunningHandler {
    FlutterEventSink _eventSink;
}
- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    return nil;
}

- (void) onDiscoveryStopped {
    _eventSink([NSNumber numberWithBool:FALSE]);
}

- (void) onDiscoveryStarted {
    _eventSink([NSNumber numberWithBool:TRUE]);
}

- (BOOL) isReady {
    return nil != _eventSink;
}

@end
