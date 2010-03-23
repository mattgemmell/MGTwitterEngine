//
//  MGTwitterSocialGraphParser.h
//  MGTwitterEngine
//
//  Created by Robert McGovern on 2010/03/19.
//  Copyright 2010 Tarasis. All rights reserved.
//

#import "MGTwitterEngineGlobalHeader.h"

#import "MGTwitterStatusesParser.h"

@interface MGTwitterSocialGraphParser : MGTwitterStatusesParser {
	NSMutableArray * twitterIDs;
}

@end
