//
//  MGTwitterSocialGraphParser.m
//  MGTwitterEngine
//
//  Created by Robert McGovern on 2010/03/19.
//  Copyright 2010 Tarasis. All rights reserved.
//

#import "MGTwitterSocialGraphParser.h"
#import "MGTwitterMiscParser.h"


@implementation MGTwitterSocialGraphParser


#pragma mark NSXMLParser delegate methods


- (void)parser:(NSXMLParser *)theParser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
    attributes:(NSDictionary *)attributeDict
{
    //NSLog(@"SG: Started element: %@ (%@)", elementName, attributeDict);
    [self setLastOpenedElement:elementName];

	if ([elementName isEqualToString:@"ids"]) {
		twitterIDs = [NSMutableArray arrayWithCapacity:0];
		NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
        [parsedObjects addObject:newNode];
        currentNode = newNode;
	} else if (currentNode && ![elementName isEqualToString:@"id"]) {
        // Create relevant name-value pair.
        [currentNode setObject:[NSMutableString string] forKey:elementName];
    }
}

- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)characters
{
    //NSLog(@"SG: Found characters: %@", characters);
    // Add the Twitter ID to the array
    if ([lastOpenedElement isEqualToString:@"id"]) {
		[twitterIDs addObject:characters];
	// Append found characters to value of lastOpenedElement in currentNode.
	} else if (lastOpenedElement && currentNode) {
		[[currentNode objectForKey:lastOpenedElement] appendString:characters];
    }
}

- (void)parser:(NSXMLParser *)theParser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    //NSLog(@"SG: didEndElement: %@", elementName);

    [super parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];

	// At the end of parsing, add the source type
    if ([elementName isEqualToString:@"id_list"]) {
		[self addSource];
		currentNode = nil;
	} else if ([elementName isEqualToString:@"ids"]) {
		[currentNode setObject:twitterIDs forKey:elementName];
		currentNode = [parsedObjects lastObject];
	} 
}


@end
