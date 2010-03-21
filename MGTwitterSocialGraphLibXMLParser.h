//
//  MGTwitterSocialGraphLibXMLParser.h
//  MGTwitterEngine
//
//  Created by Robert McGovern on 2010/03/20.
//  Copyright 2010 Tarasis. All rights reserved.
//

#import "MGTwitterEngineGlobalHeader.h"

#import "MGTwitterLibXMLParser.h"

@interface MGTwitterSocialGraphLibXMLParser : MGTwitterLibXMLParser {
	NSMutableArray * twitterIDs;	
}

- (NSDictionary *)_socialGraphDictionaryForNodeWithName:(const xmlChar *)parentNodeName;

@end
