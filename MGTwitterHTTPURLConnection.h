//
//  MGTwitterHTTPURLConnection.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 16/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

#import "MGTwitterRequestTypes.h"


@interface MGTwitterHTTPURLConnection : NSURLConnection
{
    NSMutableData *_data;                   // accumulated data received on this connection
    MGTwitterRequestType _requestType;      // general type of this request, mostly for error handling
    MGTwitterResponseType _responseType;    // type of response data expected (if successful)
    NSString *_identifier;
	NSURL *_URL;							// the URL used for the connection (needed as a base URL when parsing with libxml)
    NSHTTPURLResponse * _response;          // the response.
}

// Initializer
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate 
           requestType:(MGTwitterRequestType)requestType responseType:(MGTwitterResponseType)responseType;

// Data helper methods
- (void)resetDataLength;
- (void)appendData:(NSData *)data;

// Accessors
- (NSString *)identifier;
- (NSData *)data;
- (NSURL *)URL;
- (MGTwitterRequestType)requestType;
- (MGTwitterResponseType)responseType;
- (NSString *)description;

@property (nonatomic, retain) NSHTTPURLResponse *response;

@end
