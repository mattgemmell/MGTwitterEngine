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
	//if for some reason there are no dictionaries, exit here
	if (!_dictionaries || [_dictionaries count] == 0)
	{
		return;
	}
	
	//add the item to its dictionary
	NSMutableDictionary *lastDictionary = [_dictionaries lastObject];
	[lastDictionary setObject:value forKey:key];
	
#if DEBUG_PARSING
	NSLog(@"parsed item: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
}

- (void)startDictionaryWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"status: dictionary start = %@", key);
#endif
	
	//initialize the array that will hold all of the dictionaries if it doesn't exist yet
	if (!_dictionaries) 
	{
		_dictionaries = [[NSMutableArray alloc] init];
	}
	
	//initialize the array that will hold all of the dictionary keys if it doesn't exist yet
	if (!_dictionaryKeys) 
	{
		_dictionaryKeys = [[NSMutableArray alloc] init];
	}
	
	//add a new dictionary to the array
	NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
	[_dictionaries addObject:newDictionary];
	[newDictionary release];
	
	//convert the key to camel case
	NSString *camelKey = [[key capitalizedString] stringByReplacingOccurrencesOfString:@"_" withString:@""];
	camelKey = [NSString stringWithFormat:@"%@%@", [[camelKey substringToIndex:1] lowercaseString], [camelKey substringFromIndex:1]];
	
	//add a key for the above dictionary to the array
	[_dictionaryKeys addObject:(key) ? camelKey : @""];
}

- (void)endDictionary
{
	if (_dictionaries && _dictionaryKeys && [_dictionaries count] > 0 && [_dictionaryKeys count] > 0)
	{
		//is this the root dictionary?
		if ([_dictionaries count] == 1)
		{
			//one dictionary left, so it must be the root
			NSMutableDictionary *rootDictionary = [_dictionaries lastObject];
			
			//set the request type in the root dictionary
			[rootDictionary setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
			
			//send the root dictionary to the super class
			[self _parsedObject:rootDictionary];			
			[parsedObjects addObject:rootDictionary];
		}
		else 
		{
			//child dictionary found
			//add the child dictionary to its parent dictionary
			NSMutableDictionary *parentDictionary = [_dictionaries objectAtIndex:[_dictionaries count] - 2];
			[parentDictionary setObject:[_dictionaries lastObject] forKey:[_dictionaryKeys lastObject]];
		}
		
		//remove the last dictionary since it has been joined with its parent (or was the root dictionary)
		//also remove the corresponding key
		[_dictionaries removeLastObject];
		[_dictionaryKeys removeLastObject];
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
	[_dictionaries release];
	[_dictionaryKeys release];
	[super dealloc];
}

@end
