//
//  MGTwitterMiscLibXMLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterMiscLibXMLParser.h"


@implementation MGTwitterMiscLibXMLParser

- (void)parse
{
	int readerResult = xmlTextReaderRead(_reader);
	if (readerResult != 1)
		return;

	int nodeType = xmlTextReaderNodeType(_reader);
	const xmlChar *name = xmlTextReaderConstName(_reader);
	while (! (nodeType == XML_READER_TYPE_END_ELEMENT))
	{
		if (nodeType == XML_READER_TYPE_ELEMENT)
		{
			if (xmlStrEqual(name, BAD_CAST "hash"))
			{
				[parsedObjects addObject:[self _hashDictionaryForNodeWithName:name]];
			}
			else
			{
				// process element as a string -- API calls like friendships/exists.xml just return <friends>false</friends> or <friends>true</friends>
				NSString *string = [self _nodeValueAsString];
				if (string)
				{
					NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
					[dictionary setObject:string forKey:[NSString stringWithUTF8String:(const char *)name]];
					[parsedObjects addObject:dictionary];
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
}

@end
