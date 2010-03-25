//
//  MGTwitterTouchJSONParser.m
//  MGTwitterEngine
//
//  Created by Steve Streza on 3/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MGTwitterTouchJSONParser.h"
#import "CJSONDeserializer.h"

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
		
		if (deliveryOptions & MGTwitterEngineDeliveryAllResultsOption)
		{
			parsedObjects = [[NSMutableArray alloc] initWithCapacity:0];
		}
		else
		{
			parsedObjects = nil; // rely on nil target to discard addObject
		}
		
		if ([json length] <= 5)
		{
			// NOTE: this is a hack for API methods that return short JSON responses that can't be parsed by YAJL. These include:
			//   friendships/exists: returns "true" or "false"
			//   help/test: returns "ok"
			// An empty response of "[]" is a special case.
			NSString *result = [[[NSString alloc] initWithBytes:[json bytes] length:[json length] encoding:NSUTF8StringEncoding] autorelease];
			if (! [result isEqualToString:@"[]"])
			{
				NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];
				
				if ([result isEqualToString:@"\"ok\""])
				{
					[dictionary setObject:[NSNumber numberWithBool:YES] forKey:@"ok"];
				}
				else
				{
					[dictionary setObject:[NSNumber numberWithBool:[result isEqualToString:@"true"]] forKey:@"friends"];
				}
				[dictionary setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
				
				[self _parsedObject:dictionary];
				
				[parsedObjects addObject:dictionary];
			}
		}
		else
		{
			id results = [[CJSONDeserializer deserializer] deserialize:json
																 error:nil];
			if([results isKindOfClass:[NSArray class]]){
				for(NSDictionary *result in results){
					[self _parsedObject:result];
				}
			}else{
				[self _parsedObject:results];
			}
			
		}
		
		// notify the delegate that parsing completed
		[self _parsingDidEnd];
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
	[parsedObjects addObject:dictionary];
	if (deliveryOptions & MGTwitterEngineDeliveryIndividualResultsOption)
		if ([self _isValidDelegateForSelector:@selector(parsedObject:forRequest:ofResponseType:)])
			[delegate parsedObject:(NSDictionary *)dictionary forRequest:identifier ofResponseType:responseType];
}

@end
