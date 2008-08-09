//
//  MGTwitterUsersLibXMLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterUsersLibXMLParser.h"


@implementation MGTwitterUsersLibXMLParser

- (void)parse
{
	int readerResult = xmlTextReaderRead(_reader);
	if (readerResult != 1)
		return;
	int nodeType = xmlTextReaderNodeType(_reader);
	const xmlChar *name = xmlTextReaderConstName(_reader);
	while (! (nodeType == XML_READER_TYPE_END_ELEMENT && xmlStrEqual(BAD_CAST "users", name)))
	{
		if (nodeType == XML_READER_TYPE_ELEMENT)
		{
			if (xmlStrEqual(name, BAD_CAST "user"))
			{
				[parsedObjects addObject:[self _userDictionaryForNodeWithName:name]];
			}
		}

		// advance reader
		int readerResult = xmlTextReaderRead(_reader);
		if (readerResult != 1)
		{
			break;
		}
		nodeType = xmlTextReaderNodeType(_reader);
		name = xmlTextReaderConstName(_reader);
	}
}

@end
