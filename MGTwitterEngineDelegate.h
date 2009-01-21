//
//  MGTwitterEngineDelegate.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 16/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

@protocol MGTwitterEngineDelegate

- (void)requestSucceeded:(NSString *)connectionIdentifier;
- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error;

#if YAJL_AVAILABLE
- (void)receivedObject:(NSDictionary *)dictionary forRequest:(NSString *)connectionIdentifier;
#endif

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier;
- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier;
- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)connectionIdentifier;
- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier;
#if YAJL_AVAILABLE
- (void)searchResultsReceived:(NSArray *)searchResults forRequest:(NSString *)connectionIdentifier;
#endif

#if TARGET_OS_IPHONE
- (void)imageReceived:(UIImage *)image forRequest:(NSString *)connectionIdentifier;
#else
- (void)imageReceived:(NSImage *)image forRequest:(NSString *)connectionIdentifier;
#endif

- (void)connectionFinished;

@end
