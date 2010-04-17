//
//  MGTwitterSearchYAJLParser.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

#import "MGTwitterYAJLParser.h"

@interface MGTwitterSearchYAJLParser : MGTwitterYAJLParser {
	BOOL insideArray;
	NSMutableDictionary *_status;
	NSMutableArray *_dictionaries; // effectively a stack for parsing nested dictionaries
	NSMutableArray *_dictionaryKeys;
}

@end
