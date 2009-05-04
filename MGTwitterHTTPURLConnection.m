//
//  MGTwitterHTTPURLConnection.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 16/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterHTTPURLConnection.h"
#import "NSString+UUID.h"


@implementation MGTwitterHTTPURLConnection


#pragma mark Initializer


- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate 
          requestType:(MGTwitterRequestType)requestType responseType:(MGTwitterResponseType)responseType
{
    if (self = [super initWithRequest:request delegate:delegate]) {
        _data = [[NSMutableData alloc] initWithCapacity:0];
        _identifier = [[NSString stringWithNewUUID] retain];
        _requestType = requestType;
        _responseType = responseType;
		_URL = [[request URL] retain];
    }
    
    return self;
}


- (void)dealloc
{
    [_data release];
    [_identifier release];
	[_URL release];
    [super dealloc];
}


#pragma mark Data helper methods


- (void)resetDataLength
{
    [_data setLength:0];
}


- (void)appendData:(NSData *)data
{
    [_data appendData:data];
}


#pragma mark Accessors


- (NSString *)identifier
{
    return [[_identifier retain] autorelease];
}


- (NSData *)data
{
    return [[_data retain] autorelease];
}


- (NSURL *)URL
{
    return [[_URL retain] autorelease];
}


- (MGTwitterRequestType)requestType
{
    return _requestType;
}


- (MGTwitterResponseType)responseType
{
    return _responseType;
}


- (NSString *)description
{
    NSString *description = [super description];
    
    return [description stringByAppendingFormat:@" (requestType = %d, identifier = %@)", _requestType, _identifier];
}


@end
