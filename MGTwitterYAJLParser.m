//
//  MGTwitterYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 18/02/2008.
//  Copyright 2008 Instinctive Code.

#import "MGTwitterYAJLParser.h"


@implementation MGTwitterYAJLParser

#pragma mark Callbacks

static NSString *currentKey;

int process_yajl_null(void *ctx)
{
	id self = ctx;
	
	if (currentKey)
	{
		[self addValue:[NSNull null] forKey:currentKey];
	}
	
    return 1;
}

int process_yajl_boolean(void * ctx, int boolVal)
{
	id self = ctx;

	if (currentKey)
	{
		[self addValue:[NSNumber numberWithBool:(BOOL)boolVal] forKey:currentKey];

		[currentKey release];
		currentKey = nil;
	}

    return 1;
}

int process_yajl_number(void *ctx, const char *numberVal, unsigned int numberLen)
{
	id self = ctx;
  
	if (currentKey)
	{
		NSString *stringValue = [[NSString alloc] initWithBytesNoCopy:(void *)numberVal length:numberLen encoding:NSUTF8StringEncoding freeWhenDone:NO];

		NSNumber *longLongValue = [NSNumber numberWithLongLong:[stringValue longLongValue]];
		[self addValue:longLongValue forKey:currentKey];

		[stringValue release];

		[currentKey release];
		currentKey = nil;    
	}

	return 1;
}

int process_yajl_string(void *ctx, const unsigned char * stringVal, unsigned int stringLen)
{
	id self = ctx;
	
	if (currentKey)
	{
		NSMutableString *value = [[[NSMutableString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding] autorelease];
		
		[value replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
		[value replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
		[value replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
		[value replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];

		if ([currentKey isEqualToString:@"created_at"])
		{
			// we have a priori knowledge that the value for created_at is a date, not a string
			struct tm theTime;
			if ([value hasSuffix:@"+0000"])
			{
				// format for Search API: "Fri, 06 Feb 2009 07:28:06 +0000"
				strptime([value UTF8String], "%a, %d %b %Y %H:%M:%S +0000", &theTime);
			}
			else
			{
				// format for REST API: "Thu Jan 15 02:04:38 +0000 2009"
				strptime([value UTF8String], "%a %b %d %H:%M:%S +0000 %Y", &theTime);
			}
			time_t epochTime = timegm(&theTime);
			// save the date as a long with the number of seconds since the epoch in 1970
			[self addValue:[NSNumber numberWithLong:epochTime] forKey:currentKey];
			// this value can be converted to a date with [NSDate dateWithTimeIntervalSince1970:epochTime]
		}
		else
		{
			[self addValue:value forKey:currentKey];
		}
		
		[currentKey release];
		currentKey = nil;
	}

    return 1;
}

int process_yajl_map_key(void *ctx, const unsigned char * stringVal, unsigned int stringLen)
{
	if (currentKey)
	{
		[currentKey release];
		currentKey = nil;
	}
	
	currentKey = [[NSString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding];

    return 1;
}

int process_yajl_start_map(void *ctx)
{
	id self = ctx;
	
	[self startDictionaryWithKey:currentKey];

	return 1;
}


int process_yajl_end_map(void *ctx)
{
	id self = ctx;
	
	[self endDictionary];

	return 1;
}

int process_yajl_start_array(void *ctx)
{
	id self = ctx;
	
	[self startArrayWithKey:currentKey];
	
    return 1;
}

int process_yajl_end_array(void *ctx)
{
	id self = ctx;
	
	[self endArray];
	
    return 1;
}

static yajl_callbacks callbacks = {
	process_yajl_null,
	process_yajl_boolean,
	NULL,
	NULL,
	process_yajl_number,
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
	deliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions
{
	id parser = [[self alloc] initWithJSON:theJSON 
			delegate:theDelegate 
			connectionIdentifier:identifier 
			requestType:reqType
			responseType:respType
			URL:URL
			deliveryOptions:deliveryOptions];

	return [parser autorelease];
}


- (id)initWithJSON:(NSData *)theJSON delegate:(NSObject *)theDelegate 
	connectionIdentifier:(NSString *)theIdentifier requestType:(MGTwitterRequestType)reqType 
	responseType:(MGTwitterResponseType)respType URL:(NSURL *)theURL
	deliveryOptions:(MGTwitterEngineDeliveryOptions)theDeliveryOptions
{
	if (self = [super init])
	{
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
			// setup the yajl parser
			yajl_parser_config cfg = {
				0, // allowComments: if nonzero, javascript style comments will be allowed in the input (both /* */ and //)
				0  // checkUTF8: if nonzero, invalid UTF8 strings will cause a parse error
			};
			_handle = yajl_alloc(&callbacks, &cfg, self);
			if (! _handle)
			{
				return nil;
			}
			
			yajl_status status = yajl_parse(_handle, [json bytes], [json length]);
			if (status != yajl_status_insufficient_data && status != yajl_status_ok)
			{
				unsigned char *errorMessage = yajl_get_error(_handle, 0, [json bytes], [json length]);
				NSLog(@"MGTwitterYAJLParser: error = %s", errorMessage);
				[self _parsingErrorOccurred:[NSError errorWithDomain:@"YAJL" code:status userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:(char *)errorMessage] forKey:@"errorMessage"]]];
				yajl_free_error(errorMessage);
			}

			// free the yajl parser
			yajl_free(_handle);
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

- (void)parse
{
	// empty implementation -- override in subclasses
}

#pragma mark Subclass utilities

- (void)addValue:(id)value forKey:(NSString *)key
{
	// default implementation -- override in subclasses
	
	NSLog(@"%@ = %@ (%@)", key, value, NSStringFromClass([value class]));
}

- (void)startDictionaryWithKey:(NSString *)key
{
	// default implementation -- override in subclasses
	
	NSLog(@"dictionary start = %@", key);
}

- (void)endDictionary
{
	// default implementation -- override in subclasses
	
	NSLog(@"dictionary end");
}

- (void)startArrayWithKey:(NSString *)key
{
	// default implementation -- override in subclasses
	
	NSLog(@"array start = %@", key);
}

- (void)endArray
{
	// default implementation -- override in subclasses
	
	NSLog(@"array end");
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
