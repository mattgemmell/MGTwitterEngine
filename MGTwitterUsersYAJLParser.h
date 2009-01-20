//
//  MGTwitterUsersYAJLParser.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

#import "MGTwitterYAJLParser.h"

@interface MGTwitterUsersYAJLParser : MGTwitterYAJLParser {

	NSMutableDictionary *_user;
	NSMutableDictionary *_status;

}

@end
