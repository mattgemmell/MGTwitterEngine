//
//  MGTwitterEngine.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

#import "MGTwitterEngineDelegate.h"
#import "MGTwitterParserDelegate.h"

@interface MGTwitterEngine : NSObject <MGTwitterParserDelegate> {
    __weak NSObject <MGTwitterEngineDelegate> *_delegate;
    NSString *_username;
    NSString *_password;
    NSMutableDictionary *_connections;   // MGTwitterHTTPURLConnection objects
    NSString *_clientName;
    NSString *_clientVersion;
    NSString *_clientURL;
    NSString *_clientSourceToken;
	NSString *_APIDomain;
    BOOL _secureConnection;
	BOOL _clearsCookies;
}

// Constructors
+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)delegate;
- (MGTwitterEngine *)initWithDelegate:(NSObject *)delegate;

// Configuration and Accessors
+ (NSString *)version; // returns the version of MGTwitterEngine
- (NSString *)username;
- (NSString *)password;
- (void)setUsername:(NSString *)username password:(NSString *)password;
- (NSString *)clientName; // see README.txt for info on clientName/Version/URL/SourceToken
- (NSString *)clientVersion;
- (NSString *)clientURL;
- (NSString *)clientSourceToken;
- (void)setClientName:(NSString *)name version:(NSString *)version URL:(NSString *)url token:(NSString *)token;
- (NSString *)APIDomain;
- (void)setAPIDomain:(NSString *)domain;
- (BOOL)usesSecureConnection; // YES = uses HTTPS, default is YES
- (void)setUsesSecureConnection:(BOOL)flag;
- (BOOL)clearsCookies; // YES = deletes twitter.com cookies when setting username/password, default is NO (see README.txt)
- (void)setClearsCookies:(BOOL)flag;

// Connection methods
- (int)numberOfConnections;
- (NSArray *)connectionIdentifiers;
- (void)closeConnection:(NSString *)identifier;
- (void)closeAllConnections;

// Utility methods
/// Note: the -getImageAtURL: method works for any image URL, not just Twitter images.
// It does not require authentication, and is provided here for convenience.
// As with the Twitter API methods below, it returns a unique connection identifier.
// Retrieved images are sent to the delegate via the -imageReceived:forRequest: method.
- (NSString *)getImageAtURL:(NSString *)urlString;

// ======================================================================================================
// Twitter API methods
// See Twitter API docs at: http://apiwiki.twitter.com/REST+API+Documentation
// All methods below return a unique connection identifier.
// ======================================================================================================

// Account methods
- (NSString *)checkUserCredentials;
- (NSString *)endUserSession;
- (NSString *)enableUpdatesFor:(NSString *)username;          // i.e. follow
- (NSString *)disableUpdatesFor:(NSString *)username;         // i.e. no longer follow
- (NSString *)isUser:(NSString *)username1 receivingUpdatesFor:(NSString *)username2;	// i.e. test if username1 follows username2 (not the reverse)
- (NSString *)enableNotificationsFor:(NSString *)username;
- (NSString *)disableNotificationsFor:(NSString *)username;
- (NSString *)getRateLimitStatus;
- (NSString *)setLocation:(NSString *)location;
- (NSString *)setNotificationsDeliveryMethod:(NSString *)method;
- (NSString *)block:(NSString *)username;
- (NSString *)unblock:(NSString *)username;
- (NSString *)testService;
- (NSString *)getDowntimeSchedule;

// Retrieving updates
- (NSString *)getFollowedTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum;
- (NSString *)getFollowedTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum count:(int)count;		// max 200
- (NSString *)getFollowedTimelineFor:(NSString *)username sinceID:(int)updateID startingAtPage:(int)pageNum count:(int)count;		// max 200
- (NSString *)getUserTimelineFor:(NSString *)username since:(NSDate *)date count:(int)numUpdates;									// max 200
- (NSString *)getUserTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum count:(int)numUpdates;		// max 200
- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(int)updateID startingAtPage:(int)pageNum count:(int)numUpdates;		// max 200
- (NSString *)getUserUpdatesArchiveStartingAtPage:(int)pageNum;																		// 80 per page
- (NSString *)getPublicTimelineSinceID:(int)updateID;
- (NSString *)getRepliesStartingAtPage:(int)pageNum;                                          // sent TO this user
- (NSString *)getFavoriteUpdatesFor:(NSString *)username startingAtPage:(int)pageNum;
- (NSString *)getUpdate:(int)updateID;

// Retrieving direct messages
- (NSString *)getDirectMessagesSince:(NSDate *)date startingAtPage:(int)pageNum;              // sent TO this user
- (NSString *)getDirectMessagesSinceID:(int)updateID startingAtPage:(int)pageNum;             // sent TO this user
- (NSString *)getSentDirectMessagesSince:(NSDate *)date startingAtPage:(int)pageNum;          // sent BY this user
- (NSString *)getSentDirectMessagesSinceID:(int)updateID startingAtPage:(int)pageNum;         // sent BY this user

// Retrieving user information
- (NSString *)getUserInformationFor:(NSString *)username;
- (NSString *)getUserInformationForEmail:(NSString *)email;
- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username startingAtPage:(int)pageNum;
- (NSString *)getFollowersIncludingCurrentStatus:(BOOL)flag;
- (NSString *)getFeaturedUsers;

// Sending and editing updates
- (NSString *)sendUpdate:(NSString *)status;
- (NSString *)sendUpdate:(NSString *)status inReplyTo:(int)updateID;
- (NSString *)deleteUpdate:(int)updateID;                 // this user must be the AUTHOR
- (NSString *)markUpdate:(int)updateID asFavorite:(BOOL)flag;

// Sending and editing direct messages
- (NSString *)sendDirectMessage:(NSString *)message to:(NSString *)username;
- (NSString *)deleteDirectMessage:(int)updateID;          // this user must be the RECIPIENT

@end
