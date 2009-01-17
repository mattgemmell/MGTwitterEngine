//
//  MGTwitterYAJLParser.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 18/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"
//#include <libxml/xmlreader.h>
#include <yajl/yajl_parse.h>

#import "MGTwitterParserDelegate.h"

@interface MGTwitterYAJLParser : NSObject {
	__weak NSObject <MGTwitterParserDelegate> *delegate; // weak ref
	NSString *identifier;
	MGTwitterRequestType requestType;
	MGTwitterResponseType responseType;
	NSURL *URL;
	NSData *json;
	NSMutableArray *parsedObjects;
	
//	xmlTextReaderPtr _reader;
	yajl_handle _handle;
}

+ (id)parserWithJSON:(NSData *)theJSON delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)identifier requestType:(MGTwitterRequestType)reqType 
	   responseType:(MGTwitterResponseType)respType URL:(NSURL *)URL;
- (id)initWithJSON:(NSData *)theJSON delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)identifier requestType:(MGTwitterRequestType)reqType 
	 responseType:(MGTwitterResponseType)respType URL:(NSURL *)URL;

- (void)parse;

// subclass utilities
/*
- (xmlChar *)_nodeValue;
- (NSString *)_nodeValueAsString;
- (NSDate *)_nodeValueAsDate;
- (NSNumber *)_nodeValueAsInt;
- (NSNumber *)_nodeValueAsBool;
- (NSDictionary *)_statusDictionaryForNodeWithName:(const xmlChar *)parentNodeName;
- (NSDictionary *)_userDictionaryForNodeWithName:(const xmlChar *)parentNodeName;
- (NSDictionary *)_hashDictionaryForNodeWithName:(const xmlChar *)parentNodeName;
*/

// delegate callbacks
- (void)_parsingDidEnd;
- (void)_parsingErrorOccurred:(NSError *)parseError;


@end
