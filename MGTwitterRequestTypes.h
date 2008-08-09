//
//  MGTwitterEngineDelegate.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 17/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

typedef enum _MGTwitterRequestType {
    MGTwitterStatusesRequest        = 0, // all status requests, excluding replies and direct messages
    MGTwitterRepliesRequest         = 1, // status requests which are specifically for replies
    MGTwitterDirectMessagesRequest  = 2, // all direct message requests, including sent messages
    MGTwitterAccountRequest         = 3, // credentials, session, follow/leave, notifications, favorites, deletions
    MGTwitterUserInfoRequest        = 4, // requests for one or more users' info, including featured users
    MGTwitterStatusSend             = 5, // sending a new status
    MGTwitterDirectMessageSend      = 6, // sending a new direct message
    MGTwitterImageRequest           = 7, // requesting an image
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
} MGTwitterResponseType;

// This key is added to each tweet or direct message returned,
// with an NSNumber value containing an MGTwitterRequestType.
// This is designed to help client applications aggregate updates.
#define TWITTER_SOURCE_REQUEST_TYPE @"source_api_request_type"
