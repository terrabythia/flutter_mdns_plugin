#import <arpa/inet.h>
#import "FlutterMdnsPlugin.h"
#import "ServiceDiscoveredHandler.h"
#import "ServiceResolvedHandler.h"
#import "ServiceLostHandler.h"
#import "DiscoveryRunningHandler.h"

@interface FlutterMdnsPlugin ()

@property(nonatomic, retain) ServiceDiscoveredHandler *serviceDiscoveredHandler;
@property(nonatomic, retain) ServiceResolvedHandler *serviceResolvedHandler;
@property(nonatomic, retain) ServiceLostHandler *serviceLostHandler;
@property(nonatomic, retain) DiscoveryRunningHandler *discoveryRunningHandler;

@property(nonatomic, retain) NSNetServiceBrowser *serviceBrowser;
@property(nonatomic, retain) NSMutableArray* services;

@end

@implementation FlutterMdnsPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {

  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_mdns_plugin"
            binaryMessenger:[registrar messenger]];
  FlutterMdnsPlugin* instance = [[FlutterMdnsPlugin alloc] init];

    FlutterEventChannel *serviceDiscoveryChannel = [[FlutterEventChannel alloc]
            initWithName:@"eu.sndr.mdns/discovered"
         binaryMessenger:registrar.messenger
                   codec:[FlutterStandardMethodCodec sharedInstance]];
    instance.serviceDiscoveredHandler = [[ServiceDiscoveredHandler alloc] init];
    [serviceDiscoveryChannel setStreamHandler:instance.serviceDiscoveredHandler];

    FlutterEventChannel *serviceResolved = [[FlutterEventChannel alloc]
            initWithName:@"eu.sndr.mdns/resolved"
         binaryMessenger:registrar.messenger
                   codec:[FlutterStandardMethodCodec sharedInstance]];
    instance.serviceResolvedHandler = [[ServiceResolvedHandler alloc] init];
    [serviceResolved setStreamHandler:instance.serviceResolvedHandler];

    FlutterEventChannel *serviceLost = [[FlutterEventChannel alloc]
            initWithName:@"eu.sndr.mdns/lost"
         binaryMessenger:registrar.messenger
                   codec:[FlutterStandardMethodCodec sharedInstance]];
    instance.serviceLostHandler = [[ServiceLostHandler alloc] init];
    [serviceLost setStreamHandler:instance.serviceLostHandler];

    FlutterEventChannel *discoveryRunning = [[FlutterEventChannel alloc]
            initWithName:@"eu.sndr.mdns/running"
         binaryMessenger:registrar.messenger
                   codec:[FlutterStandardMethodCodec sharedInstance]];
    instance.discoveryRunningHandler = [[DiscoveryRunningHandler alloc] init];
    [discoveryRunning setStreamHandler:instance.discoveryRunningHandler];

  [registrar addMethodCallDelegate:instance channel:channel];

}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

  if ([@"startDiscovery" isEqualToString:call.method]) {
      [self startDiscovery:call.arguments[@"serviceType"]];
      result([NSNull null]);
  }
  else if ([@"stopDiscovery" isEqualToString:call.method]) {
      [self stopDiscovery];
      result([NSNull null]);
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

- (BOOL) areAllStreamHandlersReady {
    return self.serviceDiscoveredHandler.isReady &&
            self.discoveryRunningHandler.isReady &&
                    self.serviceResolvedHandler.isReady;
}

- (void) startDiscoveryTimerFinished:(NSTimer *)timer {
    // user info is the passed in service name
    [self startDiscovery:(NSString *)timer.userInfo];
}

- (void) startDiscovery:(NSString *)serviceName {

    // Sometimes flutter needs a few moments before the eventSink set
    // in the event handlers, we'll just check once every 100ms if
    // flutter is ready yet...
    if (! self.areAllStreamHandlersReady) {
        [NSTimer scheduledTimerWithTimeInterval:0.1f
                                         target:self
                                       selector:@selector(startDiscoveryTimerFinished:)
                                       userInfo:serviceName
                                        repeats:NO];
        return;
    }
    self.services = [[NSMutableArray alloc] init];
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    self.serviceBrowser.delegate = self;

    [self.serviceBrowser searchForServicesOfType:serviceName inDomain:@"local"];

    [self.discoveryRunningHandler onDiscoveryStarted];

}

- (void) stopDiscovery {

    [self.serviceBrowser stop];

    self.services = nil;
    self.serviceBrowser = nil;

    [self.discoveryRunningHandler onDiscoveryStopped];

}

#pragma mark NSNetServiceDelegate
- (void)netServiceDidResolveAddress:(NSNetService *)service {

    for (NSData* data in [service addresses]) {
        char addressBuffer[100];
        struct sockaddr_in* socketAddress = (struct sockaddr_in*) [data bytes];
        int sockFamily = socketAddress->sin_family;
        if (sockFamily == AF_INET) {
            const char* addressStr = inet_ntop(sockFamily,
                    &(socketAddress->sin_addr), addressBuffer,
                    sizeof(addressBuffer));

            int port = ntohs(socketAddress->sin_port);
            if (addressStr && port) {
                [self.serviceResolvedHandler onServiceResolved:
                    [self serviceToDictionary:service withAddress:[NSString stringWithUTF8String:addressStr]]
                ];
                NSLog(@"Found service at %s:%d", addressStr, port);
            }
        }
    }

}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {



}

#pragma mark NSNetserviceBrowserDelegate
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    NSLog(@"service found! %@", aNetService.name);

    aNetService.delegate = self;
    [self.services addObject:aNetService];

    [aNetService resolve];

    [self.serviceDiscoveredHandler onServiceDiscovered:
        [self serviceToDictionary:aNetService]
    ];

}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreServicesComing
{
    [self.services removeObject:aNetService];

    [self.serviceLostHandler onServiceLost:
        [self serviceToDictionary:aNetService]
    ];
}

- (NSDictionary *) serviceToDictionary:(NSNetService *)aNetService withAddress:(NSString *)address  {
    NSData* data = [aNetService TXTRecordData];
    NSDictionary* dict = [NSNetService dictionaryFromTXTRecordData:data];
    return @{
            @"attr": nil == dict ? [NSMutableDictionary dictionary] : dict,
            @"name": nil == [aNetService name] ? @"" : [aNetService name],
            @"type": nil == [aNetService type] ? @"" : [aNetService type],
            @"hostName": nil == [aNetService hostName] ? @"" : [aNetService hostName],
            @"address": nil == address ? @"" : address,
            @"port": @([aNetService port])
    };
}

- (NSDictionary *) serviceToDictionary:(NSNetService *)aNetService  {
    return [self serviceToDictionary:aNetService withAddress:nil];
}

@end
