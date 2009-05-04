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
    NSString *username = nil;
    NSString *password = nil;
    
    // Most API calls require a name and password to be set...
    if (! username || ! password) {
        NSLog(@"You forgot to specify your username/password in AppController.m, things might not work!");
		NSLog(@"And if things are mysteriously working without the username/password, it's because NSURLConnection is using a session cookie from another connection.");
    }
    
    // Create a TwitterEngine and set our login details.
    twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
    [twitterEngine setUsername:username password:password];
    
	// Configure how the delegate methods are called to deliver results. See MGTwitterEngineDelegate.h for more info
	//[twitterEngine setDeliveryOptions:MGTwitterEngineDeliveryIndividualResultsOption];

	// Get the public timeline
	NSLog(@"getPublicTimelineSinceID: connectionIdentifier = %@", [twitterEngine getPublicTimeline]);

	// Other types of information available from the API:
	
	#define TESTING_ID 1131604824
	#define TESTING_PRIMARY_USER @"gnitset"
	#define TESTING_SECONDARY_USER @"chockenberry"
	#define TESTING_MESSAGE_ID 52182684
	
	// Status methods:
	//NSLog(@"getUserTimelineFor: connectionIdentifier = %@", [twitterEngine getUserTimelineFor:TESTING_SECONDARY_USER sinceID:0 startingAtPage:0 count:3]);
	//NSLog(@"getUpdate: connectionIdentifier = %@", [twitterEngine getUpdate:TESTING_ID]);
	//NSLog(@"sendUpdate: connectionIdentifier = %@", [twitterEngine sendUpdate:[@"This is a test on " stringByAppendingString:[[NSDate date] description]]]);
	//NSLog(@"getRepliesStartingAtPage: connectionIdentifier = %@", [twitterEngine getRepliesStartingAtPage:0]);
	//NSLog(@"deleteUpdate: connectionIdentifier = %@", [twitterEngine deleteUpdate:TESTING_ID]);

	// User methods:
	//NSLog(@"getRecentlyUpdatedFriendsFor: connectionIdentifier = %@", [twitterEngine getRecentlyUpdatedFriendsFor:nil startingAtPage:0]);
	//NSLog(@"getFollowersIncludingCurrentStatus: connectionIdentifier = %@", [twitterEngine getFollowersIncludingCurrentStatus:YES]);
	//NSLog(@"getUserInformationFor: connectionIdentifier = %@", [twitterEngine getUserInformationFor:TESTING_PRIMARY_USER]);

	// Direct Message methods:
	//NSLog(@"getDirectMessagesSinceID: connectionIdentifier = %@", [twitterEngine getDirectMessagesSinceID:0 startingAtPage:0]);
	//NSLog(@"getSentDirectMessagesSinceID: connectionIdentifier = %@", [twitterEngine getSentDirectMessagesSinceID:0 startingAtPage:0]);
	//NSLog(@"sendDirectMessage: connectionIdentifier = %@", [twitterEngine sendDirectMessage:[@"This is a test on " stringByAppendingString:[[NSDate date] description]] to:TESTING_SECONDARY_USER]);
	//NSLog(@"deleteDirectMessage: connectionIdentifier = %@", [twitterEngine deleteDirectMessage:TESTING_MESSAGE_ID]);


	// Friendship methods:
	//NSLog(@"enableUpdatesFor: connectionIdentifier = %@", [twitterEngine enableUpdatesFor:TESTING_SECONDARY_USER]);
	//NSLog(@"disableUpdatesFor: connectionIdentifier = %@", [twitterEngine disableUpdatesFor:TESTING_SECONDARY_USER]);
	//NSLog(@"isUser:receivingUpdatesFor: connectionIdentifier = %@", [twitterEngine isUser:TESTING_SECONDARY_USER receivingUpdatesFor:TESTING_PRIMARY_USER]);


	// Account methods:
	//NSLog(@"checkUserCredentials: connectionIdentifier = %@", [twitterEngine checkUserCredentials]);
	//NSLog(@"endUserSession: connectionIdentifier = %@", [twitterEngine endUserSession]);
	//NSLog(@"setLocation: connectionIdentifier = %@", [twitterEngine setLocation:@"Playing in Xcode with a location that is really long and may or may not get truncated to 30 characters"]);
	//NSLog(@"setNotificationsDeliveryMethod: connectionIdentifier = %@", [twitterEngine setNotificationsDeliveryMethod:@"none"]);
	// TODO: Add: account/update_profile_colors
	// TODO: Add: account/update_profile_image
	// TODO: Add: account/update_profile_background_image
	//NSLog(@"getRateLimitStatus: connectionIdentifier = %@", [twitterEngine getRateLimitStatus]);
	// TODO: Add: account/update_profile

	// Favorite methods:
	//NSLog(@"getFavoriteUpdatesFor: connectionIdentifier = %@", [twitterEngine getFavoriteUpdatesFor:nil startingAtPage:0]);
	//NSLog(@"markUpdate: connectionIdentifier = %@", [twitterEngine markUpdate:TESTING_ID asFavorite:YES]);

	// Notification methods
	//NSLog(@"enableNotificationsFor: connectionIdentifier = %@", [twitterEngine enableNotificationsFor:TESTING_SECONDARY_USER]);
	//NSLog(@"disableNotificationsFor: connectionIdentifier = %@", [twitterEngine disableNotificationsFor:TESTING_SECONDARY_USER]);

	// Block methods
	//NSLog(@"block: connectionIdentifier = %@", [twitterEngine block:TESTING_SECONDARY_USER]);
	//NSLog(@"unblock: connectionIdentifier = %@", [twitterEngine unblock:TESTING_SECONDARY_USER]);

	// Help methods:
	//NSLog(@"testService: connectionIdentifier = %@", [twitterEngine testService]);

#if YAJL_AVAILABLE
	// Search method
	//NSLog(@"getSearchResultsForQuery: connectionIdentifier = %@", [twitterEngine getSearchResultsForQuery:TESTING_PRIMARY_USER sinceID:0 startingAtPage:1 count:20]);
	
	// Trends method
	//NSLog(@"getTrends: connectionIdentifier = %@", [twitterEngine getTrends]);
#endif
}

- (void)dealloc
{
    [twitterEngine release];
    [super dealloc];
}


#pragma mark MGTwitterEngineDelegate methods


- (void)requestSucceeded:(NSString *)connectionIdentifier
{
    NSLog(@"Request succeeded for connectionIdentifier = %@", connectionIdentifier);
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    NSLog(@"Request failed for connectionIdentifier = %@, error = %@ (%@)", 
          connectionIdentifier, 
          [error localizedDescription], 
          [error userInfo]);
}


- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
    NSLog(@"Got statuses for %@:\r%@", connectionIdentifier, statuses);
}


- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier
{
    NSLog(@"Got direct messages for %@:\r%@", connectionIdentifier, messages);
}


- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)connectionIdentifier
{
    NSLog(@"Got user info for %@:\r%@", connectionIdentifier, userInfo);
}


- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier
{
	NSLog(@"Got misc info for %@:\r%@", connectionIdentifier, miscInfo);
}

- (void)searchResultsReceived:(NSArray *)searchResults forRequest:(NSString *)connectionIdentifier
{
	NSLog(@"Got search results for %@:\r%@", connectionIdentifier, searchResults);
}


- (void)imageReceived:(NSImage *)image forRequest:(NSString *)connectionIdentifier
{
    NSLog(@"Got an image for %@: %@", connectionIdentifier, image);
    
    // Save image to the Desktop.
    NSString *path = [[NSString stringWithFormat:@"~/Desktop/%@.tiff", connectionIdentifier] stringByExpandingTildeInPath];
    [[image TIFFRepresentation] writeToFile:path atomically:NO];
}

- (void)connectionFinished:(NSString *)connectionIdentifier
{
    NSLog(@"Connection finished %@", connectionIdentifier);

	if ([twitterEngine numberOfConnections] == 0)
	{
		[NSApp terminate:self];
	}
}

#if YAJL_AVAILABLE

- (void)receivedObject:(NSDictionary *)dictionary forRequest:(NSString *)connectionIdentifier
{
    NSLog(@"Got an object for %@: %@", connectionIdentifier, dictionary);
}

#endif

@end
