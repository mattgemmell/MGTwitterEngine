//
//  MGTwitterSearchYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterSearchYAJLParser.h"

#define DEBUG_PARSING 0

@implementation MGTwitterSearchYAJLParser

- (void)addValue:(id)value forKey:(NSString *)key
{
	if (_results)
	{
		[_results setObject:value forKey:key];
#if DEBUG_PARSING
		NSLog(@"search:   results: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
	else if (_status)
	{
		[_status setObject:value forKey:key];
#if DEBUG_PARSING
		NSLog(@"search:   status: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
}

- (void)startDictionaryWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"search: dictionary start = %@", key);
#endif

	if (insideArray)
	{
		if (! _results)
		{
			_results = [[NSMutableDictionary alloc] initWithCapacity:0];
		}
	}
	else
	{
		if (! _status)
		{
			_status = [[NSMutableDictionary alloc] initWithCapacity:0];
		}
	}
}

- (void)endDictionary
{
	if (insideArray)
	{
		if (_results)
		{
			[_results setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
				
			[self _parsedObject:_results];
		
			[parsedObjects addObject:_results];
			[_results release];
			_results = nil;
		}
	}
	else
	{
		if (_status)
		{
			[_status setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
				
			[parsedObjects addObject:_status];
			[_status release];
			_status = nil;
		}
	}
	
#if DEBUG_PARSING
	NSLog(@"search: dictionary end");
#endif
}

- (void)startArrayWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"search: array start = %@", key);
#endif
	insideArray = YES;
}

- (void)endArray
{
#if DEBUG_PARSING
	NSLog(@"search: array end");
#endif
	insideArray = NO;
}

- (void)dealloc
{
	[_results release];
	[_status release];

	[super dealloc];
}


@end
