//
//  MGTwitterMessagesYAJLParser.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

#import "MGTwitterYAJLParser.h"

@interface MGTwitterMessagesYAJLParser : MGTwitterYAJLParser {

	NSMutableDictionary *_status;
	NSMutableDictionary *_sender;
	NSMutableDictionary *_recipient;

}

@end
