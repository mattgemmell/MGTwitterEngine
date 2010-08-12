//
//  MGTwitterUserListsParser.m
//  MGTwitterEngine
//
//  Created by Clinton Shryock on 6/10/10.
//  Copyright 2010 scary-robot. All rights reserved.
//

#import "MGTwitterUserListsParser.h"


@implementation MGTwitterUserListsParser

#pragma mark NSXMLParser delegate methods


- (void)parser:(NSXMLParser *)theParser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
    attributes:(NSDictionary *)attributeDict
{
    //NSLog(@"Started element: %@ (%@)", elementName, attributeDict);
    [self setLastOpenedElement:elementName];
    
    if ([elementName isEqualToString:@"list"]) {
        // Make new entry in parsedObjects.
        NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
        [parsedObjects addObject:newNode];
        currentNode = newNode;
    } else if ([elementName isEqualToString:@"user"]) {
        // Add a 'user' dictionary to current node.
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

    if ([elementName isEqualToString:@"list"]) {
        currentNode = [parsedObjects lastObject];
    } else if ([elementName isEqualToString:@"user"]) {
        [self addSource];
        currentNode = nil;
    }
}


@end
