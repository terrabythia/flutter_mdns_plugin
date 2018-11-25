//
// Created by brouwer on 23-11-18.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface ServiceLostHandler : NSObject <FlutterStreamHandler>
- (void)onServiceLost:(NSDictionary *)serviceInfoMap;

- (BOOL)isReady;
@end