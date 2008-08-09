//
//  MGTwitterLibXMLParser.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 18/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"
#include <libxml/xmlreader.h>

#import "MGTwitterParserDelegate.h"

@interface MGTwitterLibXMLParser : NSObject {
	__weak NSObject <MGTwitterParserDelegate> *delegate; // weak ref
	NSString *identifier;
	MGTwitterRequestType requestType;
	MGTwitterResponseType responseType;
	NSURL *URL;
	NSData *xml;
	NSMutableArray *parsedObjects;
	
	xmlTextReaderPtr _reader;
}

+ (id)parserWithXML:(NSData *)theXML delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)identifier requestType:(MGTwitterRequestType)reqType 
	   responseType:(MGTwitterResponseType)respType URL:(NSURL *)URL;
- (id)initWithXML:(NSData *)theXML delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)identifier requestType:(MGTwitterRequestType)reqType 
	 responseType:(MGTwitterResponseType)respType URL:(NSURL *)URL;

- (void)parse;

// subclass utilities
- (xmlChar *)_nodeValue;
- (NSString *)_nodeValueAsString;
- (NSDate *)_nodeValueAsDate;
- (NSNumber *)_nodeValueAsInt;
- (NSNumber *)_nodeValueAsBool;
- (NSDictionary *)_statusDictionaryForNodeWithName:(const xmlChar *)parentNodeName;
- (NSDictionary *)_userDictionaryForNodeWithName:(const xmlChar *)parentNodeName;
- (NSDictionary *)_hashDictionaryForNodeWithName:(const xmlChar *)parentNodeName;

// delegate callbacks
- (void)_parsingDidEnd;
- (void)_parsingErrorOccurred:(NSError *)parseError;


@end
