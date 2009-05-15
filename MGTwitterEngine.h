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
#if YAJL_AVAILABLE
	NSString *_searchDomain;
#endif
    BOOL _secureConnection;
	BOOL _clearsCookies;
#if YAJL_AVAILABLE
	MGTwitterEngineDeliveryOptions _deliveryOptions;
#endif
}

#pragma mark Class management

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
#if YAJL_AVAILABLE
- (NSString *)searchDomain;
- (void)setSearchDomain:(NSString *)domain;
#endif
- (BOOL)usesSecureConnection; // YES = uses HTTPS, default is YES
- (void)setUsesSecureConnection:(BOOL)flag;
- (BOOL)clearsCookies; // YES = deletes twitter.com cookies when setting username/password, default is NO (see README.txt)
- (void)setClearsCookies:(BOOL)flag;
#if YAJL_AVAILABLE
- (MGTwitterEngineDeliveryOptions)deliveryOptions;
- (void)setDeliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions;
#endif

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

#pragma mark REST API methods

// ======================================================================================================
// Twitter REST API methods
// See documentation at: http://apiwiki.twitter.com/Twitter-API-Documentation
// All methods below return a unique connection identifier.
// ======================================================================================================

// Status methods

- (NSString *)getPublicTimeline; // statuses/public_timeline

- (NSString *)getFollowedTimelineSinceID:(unsigned long)sinceID startingAtPage:(int)pageNum count:(int)count; // statuses/friends_timeline
- (NSString *)getFollowedTimelineSinceID:(unsigned long)sinceID withMaximumID:(unsigned long)maxID startingAtPage:(int)pageNum count:(int)count; // statuses/friends_timeline

- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(unsigned long)sinceID startingAtPage:(int)pageNum count:(int)count; // statuses/user_timeline & statuses/user_timeline/user
- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(unsigned long)sinceID withMaximumID:(unsigned long)maxID startingAtPage:(int)pageNum count:(int)count; // statuses/user_timeline & statuses/user_timeline/user

- (NSString *)getUpdate:(unsigned long)updateID; // statuses/show
- (NSString *)sendUpdate:(NSString *)status; // statuses/update
- (NSString *)sendUpdate:(NSString *)status inReplyTo:(unsigned long)updateID; // statuses/update

- (NSString *)getRepliesStartingAtPage:(int)pageNum; // statuses/mentions
- (NSString *)getRepliesSinceID:(unsigned long)sinceID startingAtPage:(int)pageNum count:(int)count; // statuses/mentions
- (NSString *)getRepliesSinceID:(unsigned long)sinceID withMaximumID:(unsigned long)maxID startingAtPage:(int)pageNum count:(int)count; // statuses/mentions

- (NSString *)deleteUpdate:(unsigned long)updateID; // statuses/destroy

- (NSString *)getFeaturedUsers; // statuses/features (undocumented, returns invalid JSON data)


// User methods

- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username startingAtPage:(int)pageNum; // statuses/friends & statuses/friends/user

- (NSString *)getFollowersIncludingCurrentStatus:(BOOL)flag; // statuses/followers

- (NSString *)getUserInformationFor:(NSString *)usernameOrID; // users/show
- (NSString *)getUserInformationForEmail:(NSString *)email; // users/show


// Direct Message methods

- (NSString *)getDirectMessagesSinceID:(unsigned long)sinceID startingAtPage:(int)pageNum; // direct_messages
- (NSString *)getDirectMessagesSinceID:(unsigned long)sinceID withMaximumID:(unsigned long)maxID startingAtPage:(int)pageNum count:(int)count; // direct_messages

- (NSString *)getSentDirectMessagesSinceID:(unsigned long)sinceID startingAtPage:(int)pageNum; // direct_messages/sent
- (NSString *)getSentDirectMessagesSinceID:(unsigned long)sinceID withMaximumID:(unsigned long)maxID startingAtPage:(int)pageNum count:(int)count; // direct_messages/sent

- (NSString *)sendDirectMessage:(NSString *)message to:(NSString *)username; // direct_messages/new
- (NSString *)deleteDirectMessage:(unsigned long)updateID;// direct_messages/destroy


// Friendship methods

- (NSString *)enableUpdatesFor:(NSString *)username; // friendships/create (follow username)
- (NSString *)disableUpdatesFor:(NSString *)username; // friendships/destroy (unfollow username)
- (NSString *)isUser:(NSString *)username1 receivingUpdatesFor:(NSString *)username2; // friendships/exists (test if username1 follows username2)


// Account methods

- (NSString *)checkUserCredentials; // account/verify_credentials
- (NSString *)endUserSession; // account/end_session

- (NSString *)setLocation:(NSString *)location; // account/update_location (deprecated, use account/update_profile instead)

- (NSString *)setNotificationsDeliveryMethod:(NSString *)method; // account/update_delivery_device

// TODO: Add: account/update_profile_colors
// TODO: Add: account/update_profile_image
// TODO: Add: account/update_profile_background_image

- (NSString *)getRateLimitStatus; // account/rate_limit_status

// TODO: Add: account/update_profile

// - (NSString *)getUserUpdatesArchiveStartingAtPage:(int)pageNum; // account/archive (removed, use /statuses/user_timeline instead)


// Favorite methods

- (NSString *)getFavoriteUpdatesFor:(NSString *)username startingAtPage:(int)pageNum; // favorites

- (NSString *)markUpdate:(unsigned long)updateID asFavorite:(BOOL)flag; // favorites/create, favorites/destroy


// Notification methods

- (NSString *)enableNotificationsFor:(NSString *)username; // notifications/follow
- (NSString *)disableNotificationsFor:(NSString *)username; // notifications/leave


// Block methods

- (NSString *)block:(NSString *)username; // blocks/create
- (NSString *)unblock:(NSString *)username; // blocks/destroy


// Help methods

- (NSString *)testService; // help/test

- (NSString *)getDowntimeSchedule; // help/downtime_schedule (undocumented)


#pragma mark Search API methods

// ======================================================================================================
// Twitter Search API methods
// See documentation at: http://apiwiki.twitter.com/Twitter-API-Documentation
// All methods below return a unique connection identifier.
// ======================================================================================================

#if YAJL_AVAILABLE

// Search method

- (NSString *)getSearchResultsForQuery:(NSString *)query;
- (NSString *)getSearchResultsForQuery:(NSString *)query sinceID:(unsigned long)sinceID startingAtPage:(int)pageNum count:(int)count; // search
- (NSString *)getSearchResultsForQuery:(NSString *)query sinceID:(unsigned long)sinceID startingAtPage:(int)pageNum count:(int)count geocode:(NSString *)geocode;

// Trends method

- (NSString *)getCurrentTrends; // current trends

#endif

@end
