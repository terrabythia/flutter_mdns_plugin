//
// Created by Sander Bruggeman on 24-07-18.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface DiscoveryRunningHandler : NSObject <FlutterStreamHandler>

- (void)onDiscoveryStopped;

- (void)onDiscoveryStarted;

- (BOOL)isReady;
@end