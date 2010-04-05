//
//  MGTwitterStatusesParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterStatusesParser.h"


@implementation MGTwitterStatusesParser


#pragma mark NSXMLParser delegate methods


- (void)parser:(NSXMLParser *)theParser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
    attributes:(NSDictionary *)attributeDict
{
    //NSLog(@"Started element: %@ (%@)", elementName, attributeDict);
    [self setLastOpenedElement:elementName];
    
    if ([elementName isEqualToString:@"status"]) {
        // Make new entry in parsedObjects.
        NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
        [parsedObjects addObject:newNode];
        currentNode = newNode;
    } else if ([elementName isEqualToString:@"user"]) {
        // Add a 'user' dictionary to current node.
        NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
        [currentNode setObject:newNode forKey:elementName];
        currentNode = newNode;
    } else if ([elementName isEqualToString:@"place"]) {
        // Add a 'place' dictionary to current node.
        NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
        [currentNode setObject:newNode forKey:elementName];
        currentNode = newNode;
    } else if ([elementName isEqualToString:@"retweeted_status"]) {
        // Add a 'retweet_status' dictionary to current node.
        NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
        [currentNode setObject:newNode forKey:elementName];
        currentNode = newNode;
    } else if (currentNode) {
        // Create relevant name-value pair.
        [currentNode setObject:[NSMutableString string] forKey:elementName];
    }
}


- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)characters
{
    //NSLog(@"Found characters: %@", characters);
    // Append found characters to value of lastOpenedElement in currentNode.
    if (lastOpenedElement && currentNode) {
        [[currentNode objectForKey:lastOpenedElement] appendString:characters];
    }
}


- (void)parser:(NSXMLParser *)theParser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    [super parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
    
    if ([elementName isEqualToString:@"user"]) {
        currentNode = [parsedObjects lastObject];
    } else if ([elementName isEqualToString:@"place"]) {
        currentNode = [parsedObjects lastObject];
    } else if ([elementName isEqualToString:@"retweeted_status"]) {
        currentNode = [parsedObjects lastObject];
    } else if ([elementName isEqualToString:@"status"]) {
        [self addSource];
        currentNode = nil;
    }
}


@end
