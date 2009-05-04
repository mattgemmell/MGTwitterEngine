//
//  MGTwitterUsersYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterUsersYAJLParser.h"

#define DEBUG_PARSING 0

@implementation MGTwitterUsersYAJLParser

- (void)addValue:(id)value forKey:(NSString *)key
{
	if (_status)
	{
		[_status setObject:value forKey:key];
#if DEBUG_PARSING
		NSLog(@"user:   status: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
	else if (_user)
	{
		[_user setObject:value forKey:key];
#if DEBUG_PARSING
		NSLog(@"user:   user: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
}

- (void)startDictionaryWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"user: dictionary start = %@", key);
#endif

	if (! _user)
	{
		_user = [[NSMutableDictionary alloc] initWithCapacity:0];
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
	if (_status)
	{
		[_user setObject:_status forKey:@"status"];
		[_status release];
		_status = nil;
	}
	else
	{
		[_user setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
		
		[self _parsedObject:_user];
		
		[parsedObjects addObject:_user];
		[_user release];
		_user = nil;
	}
	
#if DEBUG_PARSING
	NSLog(@"user: dictionary end");
#endif
}

- (void)startArrayWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"user: array start = %@", key);
#endif
}

- (void)endArray
{
#if DEBUG_PARSING
	NSLog(@"user: array end");
#endif
}

- (void)dealloc
{
	[_user release];
	[_status release];

	[super dealloc];
}

@end
