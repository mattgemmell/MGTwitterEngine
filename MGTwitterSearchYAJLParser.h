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
	NSMutableDictionary *_results;
	NSMutableDictionary *_status;
}

@end
