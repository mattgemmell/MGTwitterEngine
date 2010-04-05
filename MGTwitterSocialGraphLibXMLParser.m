//
//  MGTwitterSocialGraphLibXMLParser.m
//  MGTwitterEngine
//
//  Created by Robert McGovern on 2010/03/20.
//  Copyright 2010 Tarasis. All rights reserved.
//

#import "MGTwitterSocialGraphLibXMLParser.h"


@implementation MGTwitterSocialGraphLibXMLParser
- (void)parse
{
	int readerResult = xmlTextReaderRead(_reader);
	if (readerResult != 1)
		return;
	
	int nodeType = xmlTextReaderNodeType(_reader);
	const xmlChar *name = xmlTextReaderConstName(_reader);

	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
		
	while (! (nodeType == XML_READER_TYPE_END_ELEMENT))
	{
		//NSLog(@"name is: %@", [NSString stringWithUTF8String:(const char *)name]);
		if (nodeType == XML_READER_TYPE_ELEMENT)
		{
			if (xmlStrEqual(name, BAD_CAST "ids"))
			{
				[dictionary addEntriesFromDictionary:[self _socialGraphDictionaryForNodeWithName:name]];
			} 
			else if (xmlStrEqual(BAD_CAST "previous_cursor", name) || xmlStrEqual(BAD_CAST "next_cursor", name))
			{
				// process element as a string -- API calls like friendships/exists.xml just return <friends>false</friends> or <friends>true</friends>
				NSString *string = [self _nodeValueAsString];
				if (string)
				{
					[dictionary setObject:string forKey:[NSString stringWithUTF8String:(const char *)name]];
				}
			}
			 
		}
		
		// advance reader
		readerResult = xmlTextReaderRead(_reader);
		if (readerResult != 1)
		{
			break;
		}
		nodeType = xmlTextReaderNodeType(_reader);
		name = xmlTextReaderConstName(_reader);
	}
	
	[dictionary setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];	
	[parsedObjects addObject:dictionary];
}

- (NSDictionary *)_socialGraphDictionaryForNodeWithName:(const xmlChar *)parentNodeName
{
	if (xmlTextReaderIsEmptyElement(_reader))
		return nil;
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	twitterIDs = [NSMutableArray arrayWithCapacity:0];
	
	int readerResult = xmlTextReaderRead(_reader);
	if (readerResult != 1)
		return nil;
	int nodeType = xmlTextReaderNodeType(_reader);
	const xmlChar *name = xmlTextReaderConstName(_reader);
	while (! (nodeType == XML_READER_TYPE_END_ELEMENT && xmlStrEqual(parentNodeName, name)))
	{
		if (nodeType == XML_READER_TYPE_ELEMENT)
		{
			//NSLog(@"		name is: %@", [NSString stringWithUTF8String:(const char *)name]);
			// process element as an integer
			NSNumber *number = [self _nodeValueAsInt];
			if (number)
			{
				//[dictionary setObject:number forKey:[NSString stringWithUTF8String:(const char *)name]];
				[twitterIDs addObject:number];
			}
		}
		
		// advance reader
		readerResult = xmlTextReaderRead(_reader);
		if (readerResult != 1)
			break;
		nodeType = xmlTextReaderNodeType(_reader);
		name = xmlTextReaderConstName(_reader);
	}

	[dictionary setObject:twitterIDs forKey:[NSString stringWithUTF8String:(const char *)name]];
	
	return dictionary;
}


@end
