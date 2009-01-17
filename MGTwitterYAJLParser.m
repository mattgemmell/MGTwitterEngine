//
//  MGTwitterYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 18/02/2008.
//  Copyright 2008 Instinctive Code.

#import "MGTwitterYAJLParser.h"


@implementation MGTwitterYAJLParser

#pragma mark Callbacks

int process_yajl_null(void *ctx)
{
	id self = ctx;
	
    NSLog(@"%@: null", self);
/*
	if (dict && key)
	{
		[dict setValue:[NSNull null] forKey:key];
	}
*/
    return 1;
}

int process_yajl_boolean(void * ctx, int boolVal)
{
	id theSelf = ctx;

    NSLog(@"%@: bool: %s", theSelf, boolVal ? "true" : "false");
/*
	if (dict && key)
	{
		[dict setValue:[NSNumber numberWithBool:boolVal] forKey:key];
	}
*/
    return 1;
}

int process_yajl_integer(void *ctx, long integerVal)
{
	id theSelf = ctx;
	
    NSLog(@"%@: integer: %ld", theSelf, integerVal);
/*
	if (dict && key)
	{
		[dict setValue:[NSNumber numberWithLong:integerVal] forKey:key];
	}
*/
    return 1;
}

int process_yajl_double(void *ctx, double doubleVal)
{
	id theSelf = ctx;
	
    NSLog(@"%@: double: %lf", theSelf, doubleVal);
/*
 	if (dict && key)
	{
		[dict setValue:[NSNumber numberWithDouble:doubleVal] forKey:key];
	}
*/
   return 1;
}

int process_yajl_string(void *ctx, const unsigned char * stringVal, unsigned int stringLen)
{
	id theSelf = ctx;
	
    NSLog(@"%@: string: %@", theSelf, [[[NSString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding] autorelease]);
/*
 	if (dict && key)
	{
		NSString *value = [[[NSString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding] autorelease];
		[dict setValue:value forKey:key];
	}
*/
    return 1;
}

int process_yajl_map_key(void *ctx, const unsigned char * stringVal, unsigned int stringLen)
{
	id theSelf = ctx;
	
    NSLog(@"%@: key: %@", theSelf, [[[NSString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding] autorelease]);

/*
	if (key)
	{
		[key release];
		key = nil;
	}
	
	key = [[NSString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding];
*/	
    return 1;
}

int process_yajl_start_map(void *ctx)
{
	id theSelf = ctx;
	
    NSLog(@"%@: map open '{'", theSelf);
/*
	dict = [[NSMutableDictionary alloc] initWithCapacity:0];
*/
	return 1;
}


int process_yajl_end_map(void *ctx)
{
	id theSelf = ctx;
	
    NSLog(@"%@: map close '}'", theSelf);
/*
	[dict release];
	dict = nil;
*/
	return 1;
}

int process_yajl_start_array(void *ctx)
{
	id theSelf = ctx;
	
    NSLog(@"%@: array open '['", theSelf);
	
    return 1;
}

int process_yajl_end_array(void *ctx)
{
	id theSelf = ctx;
	
    NSLog(@"%@: array close ']'", theSelf);
	
    return 1;
}

static yajl_callbacks callbacks = {
    process_yajl_null,
    process_yajl_boolean,
    process_yajl_integer,
    process_yajl_double,
    NULL,
    process_yajl_string,
    process_yajl_start_map,
    process_yajl_map_key,
    process_yajl_end_map,
    process_yajl_start_array,
    process_yajl_end_array
};

#pragma mark Creation and Destruction


+ (id)parserWithJSON:(NSData *)theJSON delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)identifier requestType:(MGTwitterRequestType)reqType 
	   responseType:(MGTwitterResponseType)respType URL:(NSURL *)URL
{
	id parser = [[self alloc] initWithJSON:theJSON 
			delegate:theDelegate 
			connectionIdentifier:identifier 
			requestType:reqType
			responseType:respType
			URL:URL];

	return [parser autorelease];
}


- (id)initWithJSON:(NSData *)theJSON delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)theIdentifier requestType:(MGTwitterRequestType)reqType 
	 responseType:(MGTwitterResponseType)respType URL:(NSURL *)theURL
{
	if (self = [super init])
	{
		json = [theJSON retain];
		identifier = [theIdentifier retain];
		requestType = reqType;
		responseType = respType;
		URL = [theURL retain];
		delegate = theDelegate;
		parsedObjects = [[NSMutableArray alloc] initWithCapacity:0];

		// setup the yajl parser
		yajl_parser_config cfg = {
			0, // allowComments: if nonzero, javascript style comments will be allowed in the input (both /* */ and //)
			1  // checkUTF8: if nonzero, invalid UTF8 strings will cause a parse error
		};
		_handle = yajl_alloc(&callbacks, &cfg, self);
		if (! _handle)
		{
			return nil;
		}
		
		// run the parser and create parsedObjects
        [self parse];

		yajl_status status = yajl_parse(_handle, [json bytes], [json	length]);
		if (status != yajl_status_insufficient_data && status != yajl_status_ok)
		{
			unsigned char *errorMessage = yajl_get_error(_handle, 0, [json bytes], [json length]);
			NSLog(@"YAJL error = %s", errorMessage);
			yajl_free_error(errorMessage);
		}

		// free the yajl parser
		yajl_free(_handle);
		
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

- (void)parse
{
	// empty implementation -- override in subclasses
}

#pragma mark Subclass utilities

/*
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
*/

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
