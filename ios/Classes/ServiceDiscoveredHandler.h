//
// Created by Sander Bruggeman on 24-07-18.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface ServiceDiscoveredHandler : NSObject <FlutterStreamHandler>

- (void)onServiceDiscovered:(NSDictionary *)serviceInfoMap;

- (BOOL)isReady;
@end