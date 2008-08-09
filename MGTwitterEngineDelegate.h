//
//  MGTwitterEngineDelegate.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 16/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

@protocol MGTwitterEngineDelegate

- (void)requestSucceeded:(NSString *)requestIdentifier;
- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error;

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier;
- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)identifier;
- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)identifier;
- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)identifier;

#if MG_ALT_PLATFORM
- (void)imageReceived:(MG_ALT_PLATFORM_IMAGE_CLASS *)image forRequest:(NSString *)identifier;
#else
- (void)imageReceived:(NSImage *)image forRequest:(NSString *)identifier;
#endif

@end
