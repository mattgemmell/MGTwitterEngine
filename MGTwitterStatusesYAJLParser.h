//
//  MGTwitterStatusesYAJLParser.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

#import "MGTwitterYAJLParser.h"

@interface MGTwitterStatusesYAJLParser : MGTwitterYAJLParser {
	NSMutableArray *_dictionaries;		//an array of NSMutableDictionary objects
	NSMutableArray *_dictionaryKeys;	//an array of NSMutableDictionary keys corresponding to _dictionaries
}

@end