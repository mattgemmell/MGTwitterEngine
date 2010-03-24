//
//  MGTwitterTouchJSONParser.m
//  MGTwitterEngine
//
//  Created by Steve Streza on 3/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MGTwitterTouchJSONParser.h"


@implementation MGTwitterTouchJSONParser

+ (id)parserWithJSON:(NSData *)theJSON
			delegate:(NSObject *)theDelegate
connectionIdentifier:(NSString *)identifier
		 requestType:(MGTwitterRequestType)reqType
		responseType:(MGTwitterResponseType)respType
				 URL:(NSURL *)URL
	 deliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions
{
	return [[[self alloc] initWithJSON:theJSON
							  delegate:theDelegate 
				  connectionIdentifier:identifier
						   requestType:reqType
						  responseType:respType
								   URL:URL
					   deliveryOptions:deliveryOptions] autorelease];
}

- (id)  initWithJSON:(NSData *)theJSON
		    delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)theIdentifier
  	     requestType:(MGTwitterRequestType)reqType 
	    responseType:(MGTwitterResponseType)respType
			     URL:(NSURL *)theURL
     deliveryOptions:(MGTwitterEngineDeliveryOptions)theDeliveryOptions
{
	if(self = [super init]){
		json = [theJSON retain];
		identifier = [theIdentifier retain];
		requestType = reqType;
		responseType = respType;
		URL = [theURL retain];
		deliveryOptions = theDeliveryOptions;
		delegate = theDelegate;
	}
	return self;
}

- (void)dealloc
{
	[parsedObjects release];
	[json release];
	[identifier release];
	[URL release];
	
	delegate = nil;
	[super dealloc];
}

#pragma mark Delegate callbacks

- (BOOL) _isValidDelegateForSelector:(SEL)selector
{
	return ((delegate != nil) && [delegate respondsToSelector:selector]);
}

- (void)_parsingDidEnd
{
	if ([self _isValidDelegateForSelector:@selector(parsingSucceededForRequest:ofResponseType:withParsedObjects:)])
		[delegate parsingSucceededForRequest:identifier ofResponseType:responseType withParsedObjects:parsedObjects];
}

- (void)_parsingErrorOccurred:(NSError *)parseError
{
	if ([self _isValidDelegateForSelector:@selector(parsingFailedForRequest:ofResponseType:withError:)])
		[delegate parsingFailedForRequest:identifier ofResponseType:responseType withError:parseError];
}

- (void)_parsedObject:(NSDictionary *)dictionary
{
	if (deliveryOptions & MGTwitterEngineDeliveryIndividualResultsOption)
		if ([self _isValidDelegateForSelector:@selector(parsedObject:forRequest:ofResponseType:)])
			[delegate parsedObject:(NSDictionary *)dictionary forRequest:identifier ofResponseType:responseType];
}

@end
