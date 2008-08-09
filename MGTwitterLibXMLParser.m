//
//  MGTwitterLibXMLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 18/02/2008.
//  Copyright 2008 Instinctive Code.
//
//  Major portions derived from BSTweetParser by Brent Simmons
//  <http://inessential.com/?comments=1&postid=3489>

#import "MGTwitterLibXMLParser.h"


@implementation MGTwitterLibXMLParser


#pragma mark Creation and Destruction


+ (id)parserWithXML:(NSData *)theXML delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)identifier requestType:(MGTwitterRequestType)reqType 
	   responseType:(MGTwitterResponseType)respType URL:(NSURL *)URL
{
	id parser = [[self alloc] initWithXML:theXML 
			delegate:theDelegate 
			connectionIdentifier:identifier 
			requestType:reqType
			responseType:respType
			URL:URL];

	return [parser autorelease];
}


- (id)initWithXML:(NSData *)theXML delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)theIdentifier requestType:(MGTwitterRequestType)reqType 
	 responseType:(MGTwitterResponseType)respType URL:(NSURL *)theURL
{
	if (self = [super init])
	{
		xml = [theXML retain];
		identifier = [theIdentifier retain];
		requestType = reqType;
		responseType = respType;
		URL = [theURL retain];
		delegate = theDelegate;
		parsedObjects = [[NSMutableArray alloc] initWithCapacity:0];

		// setup the xml reader
		_reader = xmlReaderForMemory([xml bytes], [xml length], [[URL absoluteString] UTF8String], nil, XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING);
		if (! _reader)
		{
			return nil;
		}

		// run the parser and create parsedObjects
        [self parse];

		// free the xml reader used for parsing
		xmlFree(_reader);
		
		// notify the delegate that parsing completed
		[self _parsingDidEnd];
	}
	
	return self;
}


- (void)dealloc
{
	[parsedObjects release];
	[xml release];
	[identifier release];
	[URL release];
	
	delegate = nil;
	[super dealloc];
}

- (void)parse
{
	// empty implementation -- override in subclasses
}

#pragma mark Subclass utilities

// get the value from the current node
- (xmlChar *)_nodeValue
{
	if (xmlTextReaderIsEmptyElement(_reader))
	{
		return nil;
	}

	xmlChar *result = nil;
	int nodeType = xmlTextReaderNodeType(_reader);
	while (nodeType != XML_READER_TYPE_END_ELEMENT)
	{
		if (nodeType == XML_READER_TYPE_TEXT)
		{
			result = xmlTextReaderValue(_reader);
		}
		
		// advance reader
		int readerResult = xmlTextReaderRead(_reader);
		if (readerResult != 1)
		{
			break;
		}
		nodeType = xmlTextReaderNodeType(_reader);
	}

	//NSLog(@"node: %25s = %s", xmlTextReaderConstName(_reader), result);
	
	return result;
}

- (NSString *)_nodeValueAsString
{
	xmlChar *nodeValue = [self _nodeValue];
	if (! nodeValue)
	{
		return nil;
	}

	NSMutableString *value = [NSMutableString stringWithUTF8String:(const char *)nodeValue];
	xmlFree(nodeValue);
	
	// convert HTML entities back into UTF-8
	[value replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
	[value replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
	
	NSString *result = [NSString stringWithString:value];
	return result;
}

- (NSDate *)_nodeValueAsDate
{
	xmlChar *nodeValue = [self _nodeValue];
	if (! nodeValue)
	{
		return nil;
	}

	struct tm theTime;
	strptime((char *)nodeValue, "%a %b %d %H:%M:%S +0000 %Y", &theTime);
	xmlFree(nodeValue);
	time_t epochTime = timegm(&theTime);
	return [NSDate dateWithTimeIntervalSince1970:epochTime];
}

- (NSNumber *)_nodeValueAsInt
{
	xmlChar *nodeValue = [self _nodeValue];
	if (! nodeValue)
	{
		return nil;
	}

	NSString *intString = [NSString stringWithUTF8String:(const char *)nodeValue];
	xmlFree(nodeValue);
	return [NSNumber numberWithInt:[intString intValue]];
}

- (NSNumber *)_nodeValueAsBool
{
	xmlChar *nodeValue = [self _nodeValue];
	if (! nodeValue)
	{
		return nil;
	}

	NSString *boolString = [NSString stringWithUTF8String:(const char *)nodeValue];
	xmlFree(nodeValue);
	return [NSNumber numberWithBool:[boolString isEqualToString:@"true"]];
}

- (NSDictionary *)_statusDictionaryForNodeWithName:(const xmlChar *)parentNodeName
{
	if (xmlTextReaderIsEmptyElement(_reader))
		return nil;
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

	int readerResult = xmlTextReaderRead(_reader);
	if (readerResult != 1)
		return nil;
	int nodeType = xmlTextReaderNodeType(_reader);
	const xmlChar *name = xmlTextReaderConstName(_reader);
	while (! (nodeType == XML_READER_TYPE_END_ELEMENT && xmlStrEqual(parentNodeName, name)))
	{
		if (nodeType == XML_READER_TYPE_ELEMENT)
		{
			if (xmlStrEqual(name, BAD_CAST "user"))
			{
				// "user" is the name of a sub-dictionary in each <status> item
				[dictionary setObject:[self _userDictionaryForNodeWithName:name] forKey:@"user"];
			}
			else if (xmlStrEqual(name, BAD_CAST "id") || xmlStrEqual(name, BAD_CAST "in_reply_to_user_id") || xmlStrEqual(name, BAD_CAST "in_reply_to_status_id"))
			{
				// process element as an integer
				NSNumber *number = [self _nodeValueAsInt];
				if (number)
				{
					[dictionary setObject:number forKey:[NSString stringWithUTF8String:(const char *)name]];
				}
			}
			else if (xmlStrEqual(name, BAD_CAST "created_at"))
			{
				// process element as a date
				NSDate *date = [self _nodeValueAsDate];
				if (date)
				{
					[dictionary setObject:date forKey:[NSString stringWithUTF8String:(const char *)name]];
				}
			}
			else if (xmlStrEqual(name, BAD_CAST "truncated") || xmlStrEqual(name, BAD_CAST "favorited"))
			{
				// process element as a boolean
				NSNumber *number = [self _nodeValueAsBool];
				if (number)
				{
					[dictionary setObject:number forKey:[NSString stringWithUTF8String:(const char *)name]];
				}
			}
			else
			{
				// process element as a string
				NSString *string = [self _nodeValueAsString];
				if (string)
				{
					[dictionary setObject:string forKey:[NSString stringWithUTF8String:(const char *)name]];
				}
			}
		}

		// advance reader
		int readerResult = xmlTextReaderRead(_reader);
		if (readerResult != 1)
			break;
		nodeType = xmlTextReaderNodeType(_reader);
		name = xmlTextReaderConstName(_reader);
	}

	// save the request type in the tweet
	[dictionary setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];

	return dictionary;
}

- (NSDictionary *)_userDictionaryForNodeWithName:(const xmlChar *)parentNodeName
{
	if (xmlTextReaderIsEmptyElement(_reader))
		return nil;
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

	int readerResult = xmlTextReaderRead(_reader);
	if (readerResult != 1)
		return nil;
	int nodeType = xmlTextReaderNodeType(_reader);
	const xmlChar *name = xmlTextReaderConstName(_reader);
	while (! (nodeType == XML_READER_TYPE_END_ELEMENT && xmlStrEqual(parentNodeName, name)))
	{
		if (nodeType == XML_READER_TYPE_ELEMENT)
		{
			if (xmlStrEqual(name, BAD_CAST "id") || xmlStrEqual(name, BAD_CAST "followers_count")
					|| xmlStrEqual(name, BAD_CAST "friends_count") || xmlStrEqual(name, BAD_CAST "favourites_count")
					|| xmlStrEqual(name, BAD_CAST "statuses_count"))
			{
				// process element as an integer
				NSNumber *number = [self _nodeValueAsInt];
				if (number)
				{
					[dictionary setObject:number forKey:[NSString stringWithUTF8String:(const char *)name]];
				}
			}
			else if (xmlStrEqual(name, BAD_CAST "protected"))
			{
				// process element as a boolean
				NSNumber *number = [self _nodeValueAsBool];
				if (number)
				{
					[dictionary setObject:number forKey:[NSString stringWithUTF8String:(const char *)name]];
				}
			}
			else
			{
				// process element as a string
				NSString *s = [self _nodeValueAsString];
				if (s)
				{
					[dictionary setObject:s forKey:[NSString stringWithUTF8String:(const char *)name]];
				}
			}
		}

		// advance reader
		int readerResult = xmlTextReaderRead(_reader);
		if (readerResult != 1)
			break;
		nodeType = xmlTextReaderNodeType(_reader);
		name = xmlTextReaderConstName(_reader);
	}

	return dictionary;
}

- (NSDictionary *)_hashDictionaryForNodeWithName:(const xmlChar *)parentNodeName
{
	if (xmlTextReaderIsEmptyElement(_reader))
		return nil;
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

	int readerResult = xmlTextReaderRead(_reader);
	if (readerResult != 1)
		return nil;
	int nodeType = xmlTextReaderNodeType(_reader);
	const xmlChar *name = xmlTextReaderConstName(_reader);
	while (! (nodeType == XML_READER_TYPE_END_ELEMENT && xmlStrEqual(parentNodeName, name)))
	{
		if (nodeType == XML_READER_TYPE_ELEMENT)
		{
			if (xmlStrEqual(name, BAD_CAST "hourly-limit") || xmlStrEqual(name, BAD_CAST "remaining-hits")
					|| xmlStrEqual(name, BAD_CAST "reset-time-in-seconds"))
			{
				// process element as an integer
				NSNumber *number = [self _nodeValueAsInt];
				if (number)
				{
					[dictionary setObject:number forKey:[NSString stringWithUTF8String:(const char *)name]];
				}
			}
			else
			{
				// process element as a string
				NSString *s = [self _nodeValueAsString];
				if (s)
				{
					[dictionary setObject:s forKey:[NSString stringWithUTF8String:(const char *)name]];
				}
			}
		}

		// advance reader
		int readerResult = xmlTextReaderRead(_reader);
		if (readerResult != 1)
			break;
		nodeType = xmlTextReaderNodeType(_reader);
		name = xmlTextReaderConstName(_reader);
	}

	return dictionary;
}


#pragma mark Delegate callbacks

- (void)_parsingDidEnd
{
    //NSLog(@"Parsing complete: %@", parsedObjects);
    [delegate parsingSucceededForRequest:identifier ofResponseType:responseType withParsedObjects:parsedObjects];
}

- (void)_parsingErrorOccurred:(NSError *)parseError
{
	//NSLog(@"Parsing error occurred: %@", parseError);
	[delegate parsingFailedForRequest:identifier ofResponseType:responseType withError:parseError];
}

@end
