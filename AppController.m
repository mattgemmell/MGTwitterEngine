//
//  AppController.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "AppController.h"


@implementation AppController


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Put your Twitter username and password here:
    NSString *username = @"";
    NSString *password = @"";
    
    // Make sure you entered your login details before running this code... ;)
    if ([username isEqualToString:@""] || [password isEqualToString:@""]) {
        NSLog(@"You forgot to specify your username/password in AppController.m!");
        [NSApp terminate:self];
    }
    
    // Create a TwitterEngine and set our login details.
    twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
    [twitterEngine setUsername:username password:password];
    
    // Get updates from people the authenticated user follows.
    //NSLog(@"getFollowedTimelineFor: connection identifier = %@", [twitterEngine getFollowedTimelineFor:nil since:nil startingAtPage:0]);
	
	// Other types of information available from the API:
	
	#define TESTING_ID 1131604824
	#define TESTING_PRIMARY_USER @"gnitset"
	#define TESTING_SECONDARY_USER @"chockenberry"
	#define TESTING_MESSAGE_ID 52182684
	
	// Status methods:

	NSLog(@"getPublicTimelineSinceID: connection identifier = %@", [twitterEngine getPublicTimelineSinceID:0]);
	//NSLog(@"getUserTimelineFor: connection identifier = %@", [twitterEngine getUserTimelineFor:TESTING_SECONDARY_USER sinceID:0 startingAtPage:0 count:20]);
	//NSLog(@"getUpdate: connection identifier = %@", [twitterEngine getUpdate:TESTING_ID]);
	//NSLog(@"sendUpdate: connection identifier = %@", [twitterEngine sendUpdate:[@"This is a test on " stringByAppendingString:[[NSDate date] description]]]);
	//NSLog(@"getRepliesStartingAtPage: connection identifier = %@", [twitterEngine getRepliesStartingAtPage:0]);
	//NSLog(@"deleteUpdate: connection identifier = %@", [twitterEngine deleteUpdate:TESTING_ID]);

	// User methods:
	//NSLog(@"getRecentlyUpdatedFriendsFor: connection identifier = %@", [twitterEngine getRecentlyUpdatedFriendsFor:nil startingAtPage:0]);
	//NSLog(@"getFollowersIncludingCurrentStatus: connection identifier = %@", [twitterEngine getFollowersIncludingCurrentStatus:YES]);
	//NSLog(@"getUserInformationFor: connection identifier = %@", [twitterEngine getUserInformationFor:TESTING_PRIMARY_USER]);

	// Direct Message methods:
	//NSLog(@"getDirectMessagesSinceID: connection identifier = %@", [twitterEngine getDirectMessagesSinceID:0 startingAtPage:0]);
	//NSLog(@"getSentDirectMessagesSinceID: connection identifier = %@", [twitterEngine getSentDirectMessagesSinceID:0 startingAtPage:0]);
	//NSLog(@"sendDirectMessage: connection identifier = %@", [twitterEngine sendDirectMessage:[@"This is a test on " stringByAppendingString:[[NSDate date] description]] to:TESTING_SECONDARY_USER]);
	//NSLog(@"deleteDirectMessage: connection identifier = %@", [twitterEngine deleteDirectMessage:TESTING_MESSAGE_ID]);


	// Friendship methods:
	//NSLog(@"enableUpdatesFor: connection identifier = %@", [twitterEngine enableUpdatesFor:TESTING_SECONDARY_USER]);
	//NSLog(@"disableUpdatesFor: connection identifier = %@", [twitterEngine disableUpdatesFor:TESTING_SECONDARY_USER]);
	//NSLog(@"isUser:receivingUpdatesFor: connection identifier = %@", [twitterEngine isUser:TESTING_SECONDARY_USER receivingUpdatesFor:TESTING_PRIMARY_USER]);


	// Account methods:
	//NSLog(@"checkUserCredentials: connection identifier = %@", [twitterEngine checkUserCredentials]);
	//NSLog(@"endUserSession: connection identifier = %@", [twitterEngine endUserSession]);
	//NSLog(@"setLocation: connection identifier = %@", [twitterEngine setLocation:@"Playing in Xcode with a location that is really long and may or may not get truncated to 30 characters"]);
	//NSLog(@"setNotificationsDeliveryMethod: connection identifier = %@", [twitterEngine setNotificationsDeliveryMethod:@"none"]);
	// TODO: Add: account/update_profile_colors
	// TODO: Add: account/update_profile_image
	// TODO: Add: account/update_profile_background_image
	//NSLog(@"getRateLimitStatus: connection identifier = %@", [twitterEngine getRateLimitStatus]);
	// TODO: Add: account/update_profile

	// Favorite methods:
	//NSLog(@"getFavoriteUpdatesFor: connection identifier = %@", [twitterEngine getFavoriteUpdatesFor:nil startingAtPage:0]);
	//NSLog(@"markUpdate: connection identifier = %@", [twitterEngine markUpdate:TESTING_ID asFavorite:YES]);

	// Notification methods
	//NSLog(@"enableNotificationsFor: connection identifier = %@", [twitterEngine enableNotificationsFor:TESTING_SECONDARY_USER]);
	//NSLog(@"disableNotificationsFor: connection identifier = %@", [twitterEngine disableNotificationsFor:TESTING_SECONDARY_USER]);

	// Block methods
	//NSLog(@"block: connection identifier = %@", [twitterEngine block:TESTING_SECONDARY_USER]);
	//NSLog(@"unblock: connection identifier = %@", [twitterEngine unblock:TESTING_SECONDARY_USER]);

	// Help methods:
	//NSLog(@"testService: connection identifier = %@", [twitterEngine testService]);

#if YAJL_AVAILABLE
	// Search method
	//NSLog(@"getSearchResultsForQuery: connection identifier = %@", [twitterEngine getSearchResultsForQuery:TESTING_PRIMARY_USER sinceID:0 startingAtPage:1 count:20]);
	
	// Trends method
	//NSLog(@"getTrends: connection identifier = %@", [twitterEngine getTrends]);
#endif
}

- (void)dealloc
{
    [twitterEngine release];
    [super dealloc];
}


#pragma mark MGTwitterEngineDelegate methods


- (void)requestSucceeded:(NSString *)requestIdentifier
{
    NSLog(@"Request succeeded for connection identifier = %@", requestIdentifier);
}


- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error
{
    NSLog(@"Request failed for connection identifier = %@, error = %@ (%@)", 
          requestIdentifier, 
          [error localizedDescription], 
          [error userInfo]);
}


- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier
{
    NSLog(@"Got statuses for %@:\r%@", identifier, statuses);
	
	if ([twitterEngine numberOfConnections] == 1)
	{
		[NSApp terminate:self];
	}
}


- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)identifier
{
    NSLog(@"Got direct messages for %@:\r%@", identifier, messages);
	
	if ([twitterEngine numberOfConnections] == 1)
	{
		[NSApp terminate:self];
	}
}


- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)identifier
{
    NSLog(@"Got user info for %@:\r%@", identifier, userInfo);
	
	if ([twitterEngine numberOfConnections] == 1)
	{
		[NSApp terminate:self];
	}
}


- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)identifier
{
	NSLog(@"Got misc info for %@:\r%@", identifier, miscInfo);
	
	if ([twitterEngine numberOfConnections] == 1)
	{
		[NSApp terminate:self];
	}
}

- (void)searchResultsReceived:(NSArray *)searchResults forRequest:(NSString *)identifier
{
	NSLog(@"Got search results for %@:\r%@", identifier, searchResults);
	
	if ([twitterEngine numberOfConnections] == 1)
	{
		[NSApp terminate:self];
	}
}


- (void)imageReceived:(NSImage *)image forRequest:(NSString *)identifier
{
    NSLog(@"Got an image for %@: %@", identifier, image);
    
    // Save image to the Desktop.
    NSString *path = [[NSString stringWithFormat:@"~/Desktop/%@.tiff", identifier] 
                      stringByExpandingTildeInPath];
    [[image TIFFRepresentation] writeToFile:path atomically:NO];

	
	if ([twitterEngine numberOfConnections] == 1)
	{
		[NSApp terminate:self];
	}
}


@end
