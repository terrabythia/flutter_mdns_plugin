//
// Created by Sander Bruggeman on 24-07-18.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface ServiceResolvedHandler : NSObject <FlutterStreamHandler>
- (void)onServiceResolved:(NSDictionary *)serviceInfoMap;

- (BOOL)isReady;
@end