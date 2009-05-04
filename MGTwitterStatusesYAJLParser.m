//
//  MGTwitterStatusesYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterStatusesYAJLParser.h"

#define DEBUG_PARSING 0

@implementation MGTwitterStatusesYAJLParser

- (void)addValue:(id)value forKey:(NSString *)key
{
	if (_user)
	{
		[_user setObject:value forKey:key];
#if DEBUG_PARSING
		NSLog(@"status:   user: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
	else if (_status)
	{
		[_status setObject:value forKey:key];
#if DEBUG_PARSING
		NSLog(@"status:   status: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
}

- (void)startDictionaryWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"status: dictionary start = %@", key);
#endif

	if (! _status)
	{
		_status = [[NSMutableDictionary alloc] initWithCapacity:0];
	}
	else
	{
		if (! _user)
		{
			_user = [[NSMutableDictionary alloc] initWithCapacity:0];
		}
	}
}

- (void)endDictionary
{
	if (_user)
	{
		[_status setObject:_user forKey:@"user"];
		[_user release];
		_user = nil;
	}
	else
	{
		[_status setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
		
		[self _parsedObject:_status];
		
		[parsedObjects addObject:_status];
		[_status release];
		_status = nil;
	}
	
#if DEBUG_PARSING
	NSLog(@"status: dictionary end");
#endif
}

- (void)startArrayWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"status: array start = %@", key);
#endif
}

- (void)endArray
{
#if DEBUG_PARSING
	NSLog(@"status: array end");
#endif
}

- (void)dealloc
{
	[_status release];
	[_user release];

	[super dealloc];
}

@end
