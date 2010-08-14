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

#import "OAToken.h"


@interface MGTwitterEngine : NSObject <MGTwitterParserDelegate>
{
    __weak NSObject <MGTwitterEngineDelegate> *_delegate;
    NSMutableDictionary *_connections;   // MGTwitterHTTPURLConnection objects
    NSString *_clientName;
    NSString *_clientVersion;
    NSString *_clientURL;
    NSString *_clientSourceToken;
	NSString *_APIDomain;
#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
	NSString *_searchDomain;
#endif
    BOOL _secureConnection;
	BOOL _clearsCookies;
#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
	MGTwitterEngineDeliveryOptions _deliveryOptions;
#endif
	
	// OAuth
	NSString *_consumerKey;
	NSString *_consumerSecret;
	OAToken  *_accessToken;
	
	// basic auth - deprecated
	NSString *_username;
    NSString *_password;
}

#pragma mark Class management

// Constructors
+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)delegate;
- (MGTwitterEngine *)initWithDelegate:(NSObject *)delegate;

// Configuration and Accessors
+ (NSString *)version; // returns the version of MGTwitterEngine
- (NSString *)clientName; // see README.txt for info on clientName/Version/URL/SourceToken
- (NSString *)clientVersion;
- (NSString *)clientURL;
- (NSString *)clientSourceToken;
- (void)setClientName:(NSString *)name version:(NSString *)version URL:(NSString *)url token:(NSString *)token;
- (NSString *)APIDomain;
- (void)setAPIDomain:(NSString *)domain;
#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
- (NSString *)searchDomain;
- (void)setSearchDomain:(NSString *)domain;
#endif
- (BOOL)usesSecureConnection; // YES = uses HTTPS, default is YES
- (void)setUsesSecureConnection:(BOOL)flag;
- (BOOL)clearsCookies; // YES = deletes twitter.com cookies when setting username/password, default is NO (see README.txt)
- (void)setClearsCookies:(BOOL)flag;
#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
- (MGTwitterEngineDeliveryOptions)deliveryOptions;
- (void)setDeliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions;
#endif

// Connection methods
- (NSUInteger)numberOfConnections;
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

- (NSString *)getHomeTimelineSinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)pageNum count:(int)count; // statuses/home_timeline
- (NSString *)getHomeTimelineSinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)pageNum count:(int)count; // statuses/home_timeline

- (NSString *)getFollowedTimelineSinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)pageNum count:(int)count; // statuses/friends_timeline
- (NSString *)getFollowedTimelineSinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)pageNum count:(int)count; // statuses/friends_timeline

- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)pageNum count:(int)count; // statuses/user_timeline & statuses/user_timeline/user
- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)pageNum count:(int)count; // statuses/user_timeline & statuses/user_timeline/user

- (NSString *)getUpdate:(MGTwitterEngineID)updateID; // statuses/show
- (NSString *)sendUpdate:(NSString *)status; // statuses/update

- (NSString *)sendUpdate:(NSString *)status withLatitude:(MGTwitterEngineLocationDegrees)latitude longitude:(MGTwitterEngineLocationDegrees)longitude; // statuses/update
- (NSString *)sendUpdate:(NSString *)status inReplyTo:(MGTwitterEngineID)updateID; // statuses/update
- (NSString *)sendUpdate:(NSString *)status inReplyTo:(MGTwitterEngineID)updateID withLatitude:(MGTwitterEngineLocationDegrees)latitude longitude:(MGTwitterEngineLocationDegrees)longitude; // statuses/update
- (NSString *)sendRetweet:(MGTwitterEngineID)tweetID; // statuses/retweet

- (NSString *)getRepliesStartingAtPage:(int)pageNum; // statuses/mentions
- (NSString *)getRepliesSinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)pageNum count:(int)count; // statuses/mentions
- (NSString *)getRepliesSinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)pageNum count:(int)count; // statuses/mentions

- (NSString *)deleteUpdate:(MGTwitterEngineID)updateID; // statuses/destroy

- (NSString *)getFeaturedUsers; // statuses/features (undocumented, returns invalid JSON data)


// User methods

- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username startingAtPage:(int)pageNum; // statuses/friends & statuses/friends/user

- (NSString *)getFollowersIncludingCurrentStatus:(BOOL)flag; // statuses/followers

- (NSString *)getUserInformationFor:(NSString *)usernameOrID; // users/show
- (NSString *)getBulkUserInformationFor:(NSString *)userIDs;

- (NSString *)getUserInformationForEmail:(NSString *)email; // users/show

//	List Methods

//	List the lists of the specified user. Private lists will be included if the 
//	authenticated users is the same as the user who's lists are being returned.
- (NSString *)getListsForUser:(NSString *)username;

//	Creates a new list for the authenticated user. Accounts are limited to 20 lists.
//	Options include:
//	mode - Whether your list is public or private. Values can be public or private. 
//		If no mode is specified the list will be public.
//	description - The description to give the list.
- (NSString *)createListForUser:(NSString *)username withName:(NSString *)listName withOptions:(NSDictionary *)options;

//	update an existing list
- (NSString *)updateListForUser:(NSString *)username withID:(MGTwitterEngineID)listID withOptions:(NSDictionary *)options;

//	Show the specified list. Private lists will only be shown if the authenticated user owns the specified list.
- (NSString *)getListForUser:(NSString *)username withID:(MGTwitterEngineID)listID;

// Direct Message methods

- (NSString *)getDirectMessagesSinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)pageNum; // direct_messages
- (NSString *)getDirectMessagesSinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)pageNum count:(int)count; // direct_messages

- (NSString *)getSentDirectMessagesSinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)pageNum; // direct_messages/sent
- (NSString *)getSentDirectMessagesSinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)pageNum count:(int)count; // direct_messages/sent

- (NSString *)sendDirectMessage:(NSString *)message to:(NSString *)username; // direct_messages/new
- (NSString *)deleteDirectMessage:(MGTwitterEngineID)updateID;// direct_messages/destroy


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
- (NSString *)setProfileImageWithImageAtPath:(NSString *)pathToFile;
- (NSString *)setProfileBackgroundImageWithImageAtPath:(NSString *)pathToFile andTitle:(NSString *)title;

- (NSString *)getRateLimitStatus; // account/rate_limit_status

// TODO: Add: account/update_profile

// - (NSString *)getUserUpdatesArchiveStartingAtPage:(int)pageNum; // account/archive (removed, use /statuses/user_timeline instead)


// Favorite methods

- (NSString *)getFavoriteUpdatesFor:(NSString *)username startingAtPage:(int)pageNum; // favorites

- (NSString *)markUpdate:(MGTwitterEngineID)updateID asFavorite:(BOOL)flag; // favorites/create, favorites/destroy


// Notification methods

- (NSString *)enableNotificationsFor:(NSString *)username; // notifications/follow
- (NSString *)disableNotificationsFor:(NSString *)username; // notifications/leave


// Block methods

- (NSString *)block:(NSString *)username; // blocks/create
- (NSString *)unblock:(NSString *)username; // blocks/destroy


// Help methods

- (NSString *)testService; // help/test

- (NSString *)getDowntimeSchedule; // help/downtime_schedule (undocumented)


// Social Graph methods
- (NSString *)getFriendIDsFor:(NSString *)username startingFromCursor:(MGTwitterEngineCursorID)cursor; // friends/ids
- (NSString *)getFollowerIDsFor:(NSString *)username startingFromCursor:(MGTwitterEngineCursorID)cursor; // followers/ids


#pragma mark Search API methods

// ======================================================================================================
// Twitter Search API methods
// See documentation at: http://apiwiki.twitter.com/Twitter-API-Documentation
// All methods below return a unique connection identifier.
// ======================================================================================================

#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE

// Search method

- (NSString *)getSearchResultsForQuery:(NSString *)query;
- (NSString *)getSearchResultsForQuery:(NSString *)query sinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)pageNum count:(int)count; // search
- (NSString *)getSearchResultsForQuery:(NSString *)query sinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)pageNum count:(int)count geocode:(NSString *)geocode;

// Trends method

- (NSString *)getCurrentTrends; // current trends

#endif

@end

@interface MGTwitterEngine (BasicAuth)

- (NSString *)username;
- (void)setUsername:(NSString *) newUsername;

- (NSString *)password DEPRECATED_ATTRIBUTE;
- (void)setUsername:(NSString *)username password:(NSString *)password DEPRECATED_ATTRIBUTE;

@end

@interface MGTwitterEngine (OAuth)

- (void)setConsumerKey:(NSString *)key secret:(NSString *)secret;
- (NSString *)consumerKey;
- (NSString *)consumerSecret;

- (void)setAccessToken: (OAToken *)token;
- (OAToken *)accessToken;

// XAuth login - NOTE: You MUST email Twitter with your application's OAuth key/secret to
// get OAuth access. This will not work if you don't do this.
- (NSString *)getXAuthAccessTokenForUsername:(NSString *)username 
									password:(NSString *)password;

@end


