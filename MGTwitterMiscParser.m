//
//  MGTwitterMiscParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 06/06/2008.
//  Copyright 2008 Instinctive Code. All rights reserved.
//

#import "MGTwitterMiscParser.h"


@implementation MGTwitterMiscParser


#pragma mark NSXMLParser delegate methods


- (void)parser:(NSXMLParser *)theParser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
    attributes:(NSDictionary *)attributeDict
{
    //NSLog(@"Started element: %@ (%@)", elementName, attributeDict);
    [self setLastOpenedElement:elementName];
    
	if (!currentNode) {
		NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
        [parsedObjects addObject:newNode];
        currentNode = newNode;
	}
	
	// Create relevant name-value pair.
	[currentNode setObject:[NSMutableString string] forKey:elementName];
}


- (void)parser:(NSXMLParser *)theParser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    [super parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
    
    if ([elementName isEqualToString:@"remaining_hits"]) {
        NSNumber *hits = [NSNumber numberWithInt:[[currentNode objectForKey:elementName] intValue]];
        [currentNode setObject:hits forKey:elementName];
    }
}


@end
