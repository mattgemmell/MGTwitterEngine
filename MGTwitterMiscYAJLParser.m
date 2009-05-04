//
//  MGTwitterMiscYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterMiscYAJLParser.h"

#define DEBUG_PARSING 0

@implementation MGTwitterMiscYAJLParser

- (void)addValue:(id)value forKey:(NSString *)key
{
	if (_results)
	{
		[_results setObject:value forKey:key];
#if DEBUG_PARSING
		NSLog(@"misc:   results: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
}

- (void)startDictionaryWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"misc: dictionary start = %@", key);
#endif

	if (! _results)
	{
		_results = [[NSMutableDictionary alloc] initWithCapacity:0];
	}
}

- (void)endDictionary
{
	[_results setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
		
	[self _parsedObject:_results];
		
	[parsedObjects addObject:_results];
	[_results release];
	_results = nil;
	
#if DEBUG_PARSING
	NSLog(@"misc: dictionary end");
#endif
}

- (void)startArrayWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"misc: array start = %@", key);
#endif
}

- (void)endArray
{
#if DEBUG_PARSING
	NSLog(@"misc: array end");
#endif
}

- (void)dealloc
{
	[_results release];

	[super dealloc];
}

@end
