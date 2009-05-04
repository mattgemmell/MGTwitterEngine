//
//  MGTwitterMessagesYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterMessagesYAJLParser.h"

#define DEBUG_PARSING 0

@implementation MGTwitterMessagesYAJLParser

- (void)addValue:(id)value forKey:(NSString *)key
{
	if (_sender)
	{
		[_sender setObject:value forKey:key];
#if DEBUG_PARSING
		NSLog(@"messages:   sender: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
	else if (_recipient)
	{
		[_recipient setObject:value forKey:key];
#if DEBUG_PARSING
		NSLog(@"messages:   recipient: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
	else if (_status)
	{
		[_status setObject:value forKey:key];
#if DEBUG_PARSING
		NSLog(@"messages:   status: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
}

- (void)startDictionaryWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"messages: dictionary start = %@", key);
#endif

	if (! _status)
	{
		_status = [[NSMutableDictionary alloc] initWithCapacity:0];
	}
	else
	{
		if ([key isEqualToString:@"sender"])
		{
			_sender = [[NSMutableDictionary alloc] initWithCapacity:0];
		}
		else
		{
			_recipient = [[NSMutableDictionary alloc] initWithCapacity:0];
		}
	}
}

- (void)endDictionary
{
	if (_sender)
	{
		[_status setObject:_sender forKey:@"sender"];
		[_sender release];
		_sender = nil;
	}
	else if (_recipient)
	{
		[_status setObject:_recipient forKey:@"recipient"];
		[_recipient release];
		_recipient = nil;
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
	NSLog(@"messages: dictionary end");
#endif
}

- (void)startArrayWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"messages: array start = %@", key);
#endif
}

- (void)endArray
{
#if DEBUG_PARSING
	NSLog(@"messages: array end");
#endif
}

- (void)dealloc
{
	[_status release];
	[_sender release];
	[_recipient release];

	[super dealloc];
}

@end
