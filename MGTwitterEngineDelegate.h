//
//  MGTwitterEngineDelegate.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 16/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"


typedef enum _MGTwitterEngineDeliveryOptions {
	// all results will be delivered as an array via statusesReceived: and similar delegate methods
    MGTwitterEngineDeliveryAllResultsOption = 1 << 0,

	// individual results will be delivered as a dictionary via the receivedObject: delegate method
    MGTwitterEngineDeliveryIndividualResultsOption = 1 << 1,
	
	// these options can be combined with the | operator
} MGTwitterEngineDeliveryOptions;



@protocol MGTwitterEngineDelegate

// These delegate methods are called after a connection has been established
- (void)requestSucceeded:(NSString *)connectionIdentifier;
- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error;

@optional

#if YAJL_AVAILABLE
// This delegate method is called each time a new result is parsed from the connection and
// the deliveryOption is configured for MGTwitterEngineDeliveryIndividualResults.
- (void)receivedObject:(NSDictionary *)dictionary forRequest:(NSString *)connectionIdentifier;
#endif

// These delegate methods are called after all results are parsed from the connection. If 
// the deliveryOption is configured for MGTwitterEngineDeliveryAllResults (the default), a
// collection of all results is also returned.
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

// This delegate method is called whenever a connection has finished.
- (void)connectionFinished:(NSString *)connectionIdentifier;

@end
