//
//  AppController.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import <Cocoa/Cocoa.h>
#import "MGTwitterEngine.h"

@class OAToken;

@interface AppController : NSObject <MGTwitterEngineDelegate> {
    MGTwitterEngine *twitterEngine;
	
	OAToken *token;
	
	IBOutlet NSTextField* pinCode;
	IBOutlet NSWindow* pinWindow;
}

// this gets called when the OAuth token is received
-(void)runTests;

- (IBAction)enteredPin: (id)sender;

@end
