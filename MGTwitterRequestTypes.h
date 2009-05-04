//
//  MGTwitterEngineDelegate.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 17/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

typedef enum _MGTwitterRequestType {
	MGTwitterPublicTimelineRequest = 0,  // latest statuses from the public timeline
	MGTwitterFollowedTimelineRequest, // latest statuses from the people that the current users follows
	MGTwitterUserTimelineRequest, // statuses archive for the current user
	MGTwitterUserTimelineForUserRequest, // statuses archive for the specified user
	MGTwitterUpdateGetRequest, // get a status update for the specified id
	MGTwitterUpdateSendRequest, // send a new update for the current user
	MGTwitterUpdateDeleteRequest, // delete an update for the current user using the specified id
    MGTwitterRepliesRequest, // latest reply status for the current user
    MGTwitterFeaturedUsersRequest, // latest status from featured users
	MGTwitterFriendUpdatesRequest, // last status for the people that the current user follows
	MGTwitterFriendUpdatesForUserRequest, // last status for the people that the specified user follows
	MGTwitterFollowerUpdatesRequest, // last status for the people that follow the current user
	MGTwitterUserInformationRequest, // user information using the specified id or email
    MGTwitterDirectMessagesRequest, // latest direct messages to the current user
    MGTwitterDirectMessagesSentRequest, // latest direct messages from the current user
	MGTwitterDirectMessageSendRequest, // send a new direct message from the current user
	MGTwitterDirectMessageDeleteRequest, // delete a direct message to/from the current user
	MGTwitterUpdatesEnableRequest, // enable status updates for specified user (e.g. follow)
	MGTwitterUpdatesDisableRequest, // disable status updates for specified user (e.g. unfollow)
	MGTwitterUpdatesCheckRequest, // check if the specified user is following another user
	MGTwitterAccountRequest, // changing account information for the current user
 	MGTwitterAccountLocationRequest, // change location in account information for the current user
 	MGTwitterAccountDeliveryRequest, // change notification delivery in account information for the current user
 	MGTwitterAccountStatusRequest, // get rate limiting status for the current user
	MGTwitterFavoritesRequest, // latest favorites for the current user
	MGTwitterFavoritesForUserRequest, // latest favorites for the specified user
	MGTwitterFavoritesEnableRequest, // create a favorite for the current user using the specified id 
	MGTwitterFavoritesDisableRequest, // remove a favorite for the current user using the specified id 
	MGTwitterNotificationsEnableRequest, // enable notifications for the specified user
	MGTwitterNotificationsDisableRequest, // disable notifications for the specified user
	MGTwitterBlockEnableRequest, // enable block for the specified user
	MGTwitterBlockDisableRequest, // disable block for the specified user
    MGTwitterImageRequest, // requesting an image
#if YAJL_AVAILABLE
	MGTwitterSearchRequest, // performing a search
	MGTwitterSearchCurrentTrendsRequest, // getting the current trends
#endif
} MGTwitterRequestType;

typedef enum _MGTwitterResponseType {
    MGTwitterStatuses           = 0,    // one or more statuses
    MGTwitterStatus             = 1,    // exactly one status
    MGTwitterUsers              = 2,    // one or more user's information
    MGTwitterUser               = 3,    // info for exactly one user
    MGTwitterDirectMessages     = 4,    // one or more direct messages
    MGTwitterDirectMessage      = 5,    // exactly one direct message
    MGTwitterGeneric            = 6,    // a generic response not requiring parsing
	MGTwitterMiscellaneous		= 8,	// a miscellaneous response of key-value pairs
    MGTwitterImage              = 7,    // an image
#if YAJL_AVAILABLE
	MGTwitterSearchResults		= 9,	// search results
#endif
} MGTwitterResponseType;

// This key is added to each tweet or direct message returned,
// with an NSNumber value containing an MGTwitterRequestType.
// This is designed to help client applications aggregate updates.
#define TWITTER_SOURCE_REQUEST_TYPE @"source_api_request_type"
