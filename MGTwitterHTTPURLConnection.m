//
//  MGTwitterHTTPURLConnection.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 16/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterHTTPURLConnection.h"
#import "NSString+UUID.h"



@interface NSURLRequest (OAuthExtensions)
-(void)prepare;
@end

@implementation NSURLRequest (OAuthExtensions)

-(void)prepare{
	// do nothing
}

@end



@implementation MGTwitterHTTPURLConnection


@synthesize response = _response;

#pragma mark Initializer


- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate 
          requestType:(MGTwitterRequestType)requestType responseType:(MGTwitterResponseType)responseType
{
	// OAuth requests need to have -prepare called on them first. handle that case before the NSURLConnection sends it
	[request prepare];
	
    if ((self = [super initWithRequest:request delegate:delegate])) {
        _data = [[NSMutableData alloc] initWithCapacity:0];
        _identifier = [NSString stringWithNewUUID];
        _requestType = requestType;
        _responseType = responseType;
		_URL = [request URL];
    }
    
    return self;
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
    return _identifier;
}


- (NSData *)data
{
    return _data;
}


- (NSURL *)URL
{
    return _URL;
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
