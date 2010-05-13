//
//  MGTwitterTouchJSONParser.h
//  MGTwitterEngine
//
//  Created by Steve Streza on 3/24/10.
//  Copyright 2010 MGTwitterEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MGTwitterParserDelegate.h"
#import "MGTwitterEngineDelegate.h"

@interface MGTwitterTouchJSONParser : NSObject {
	__weak NSObject <MGTwitterParserDelegate> *delegate; // weak ref
	NSString *identifier;
	MGTwitterRequestType requestType;
	MGTwitterResponseType responseType;
	NSURL *URL;
	NSData *json;
	NSMutableArray *parsedObjects;
	MGTwitterEngineDeliveryOptions deliveryOptions;
}

+ (id)parserWithJSON:(NSData *)theJSON
			delegate:(NSObject *)theDelegate
connectionIdentifier:(NSString *)identifier
		 requestType:(MGTwitterRequestType)reqType
		responseType:(MGTwitterResponseType)respType
				 URL:(NSURL *)URL
	 deliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions;
- (id)initWithJSON:(NSData *)theJSON
		  delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)identifier
	   requestType:(MGTwitterRequestType)reqType 
	  responseType:(MGTwitterResponseType)respType
			   URL:(NSURL *)URL
   deliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions;

// delegate callbacks
- (void)_parsingDidEnd;
- (void)_parsingErrorOccurred:(NSError *)parseError;
- (void)_parsedObject:(NSDictionary *)dictionary;

@end
