//
//  BonjourDiscoveredServices.m
//  BonjouriOS
//
//  Created by Spirit on 7/23/14.
//  Copyright (c) 2014 funymph. All rights reserved.
//

#import "BonjourDiscoveredServices.h"

#import "BonjourDiscoveredServiceCell.h"

@implementation BonjourDiscoveredServices {
	NSArray* _serviceNames;
	NSNetServiceBrowser* _browser;
	NSMutableDictionary* _servcies;
}

- (instancetype)init {
	if (self = [super init]) {
		_servcies = [NSMutableDictionary new];
		_browser = [[NSNetServiceBrowser alloc] init];
		_browser.delegate = self;
		_browser.includesPeerToPeer = YES;
	}
	return self;
}

- (void)startDiscovery {
	[_browser searchForServicesOfType:@"_chat._tcp." inDomain:@"local."];
}

- (void)stopDiscovery {
	[_browser stop];
	dispatch_async(dispatch_get_main_queue(), ^() {
		[self removeAll];
	});
}

- (void)addService:(NSNetService*)service {
	if (service.name != nil && service.name.length > 0) {
		[_servcies setObject:service forKey:service.name];
		_serviceNames = [[_servcies allKeys] sortedArrayUsingSelector:@selector(compare:)];
	}
	[self.delegate discoveredServicesChanged];
}

- (void)removeService:(NSNetService*)service {
	if (service.name != nil && service.name.length > 0) {
		[_servcies removeObjectForKey:service.name];
		_serviceNames = [[_servcies allKeys] sortedArrayUsingSelector:@selector(compare:)];
	}
	[self.delegate discoveredServicesChanged];
}

- (void)removeAll {
	[_servcies removeAllObjects];
	_serviceNames = @[];
	[self.delegate discoveredServicesChanged];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	return [_servcies count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	BonjourDiscoveredServiceCell* cell = (BonjourDiscoveredServiceCell*)[tableView dequeueReusableCellWithIdentifier:BonjourDiscoveredServiceCellIdentifier];
	if (cell == nil) {
		cell = [[[NSBundle mainBundle] loadNibNamed:BonjourDiscoveredServiceCellIdentifier owner:nil options:nil] firstObject];
	}
	NSNetService* service = [_servcies objectForKey:[_serviceNames objectAtIndex:indexPath.row]];
	cell.service = service;
	return cell;
}

#pragma mark - NSNetServiceBrowserDelegate
- (void)netServiceBrowser:(NSNetServiceBrowser*)browser didFindService:(NSNetService*)service moreComing:(BOOL)moreComing {
	NSLog(@"service: %@ found", service);
	dispatch_async(dispatch_get_main_queue(), ^() {
		[self addService:service];
	});
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)aNetServiceBrowser didNotSearch:(NSDictionary*)errorDict {
	NSLog(@"failed to discover services, due to %@", errorDict);
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)browser didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing {
	NSLog(@"service: %@ removed", service);
	dispatch_async(dispatch_get_main_queue(), ^() {
		[self removeService:service];
	});
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser*)aNetServiceBrowser {
	NSLog(@"service browser stopped");
}

@end
