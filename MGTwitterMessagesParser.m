//
//  MGTwitterMessagesParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 19/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterMessagesParser.h"


@implementation MGTwitterMessagesParser


#pragma mark NSXMLParser delegate methods


- (void)parser:(NSXMLParser *)theParser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
    attributes:(NSDictionary *)attributeDict
{
    //NSLog(@"Started element: %@ (%@)", elementName, attributeDict);
    [self setLastOpenedElement:elementName];
    
    if ([elementName isEqualToString:@"direct_message"]) {
        // Make new entry in parsedObjects.
        NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
        [parsedObjects addObject:newNode];
        currentNode = newNode;
    } else if ([elementName isEqualToString:@"sender"] || [elementName isEqualToString:@"recipient"]) {
        // Add an appropriate dictionary to current node.
        NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
        [currentNode setObject:newNode forKey:elementName];
        currentNode = newNode;
    } else if (currentNode) {
        // Create relevant name-value pair.
        [currentNode setObject:[NSMutableString string] forKey:elementName];
    }
}


- (void)parser:(NSXMLParser *)theParser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    [super parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
    
    if ([elementName isEqualToString:@"sender"] || [elementName isEqualToString:@"recipient"]) {
        currentNode = [parsedObjects lastObject];
    } else if ([elementName isEqualToString:@"direct_message"]) {
        [self addSource];
        currentNode = nil;
    }
}


@end
