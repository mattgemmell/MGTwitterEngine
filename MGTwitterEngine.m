//
//  MGTwitterEngine.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngine.h"
#import "MGTwitterHTTPURLConnection.h"
#import "OAuthConsumer.h"

#import "NSData+Base64.h"

#ifndef USE_LIBXML
//  if you wish to use LibXML, add USE_LIBXML=1 to "Precompiler Macros" in Project Info for all targets
#   define USE_LIBXML 0
#endif

#if YAJL_AVAILABLE
	#define API_FORMAT @"json"

	#import "MGTwitterStatusesYAJLParser.h"
	#import "MGTwitterMessagesYAJLParser.h"
	#import "MGTwitterUsersYAJLParser.h"
	#import "MGTwitterMiscYAJLParser.h"
	#import "MGTwitterSearchYAJLParser.h"
#elif TOUCHJSON_AVAILABLE
	#define API_FORMAT @"json"

	#import "MGTwitterTouchJSONParser.h"
#else
	#define API_FORMAT @"xml"

	#if USE_LIBXML
		#import "MGTwitterStatusesLibXMLParser.h"
		#import "MGTwitterMessagesLibXMLParser.h"
		#import "MGTwitterUsersLibXMLParser.h"
		#import "MGTwitterMiscLibXMLParser.h"
		#import "MGTwitterSocialGraphLibXMLParser.h"
	#else
		#import "MGTwitterStatusesParser.h"
		#import "MGTwitterUsersParser.h"
		#import "MGTwitterMessagesParser.h"
		#import "MGTwitterMiscParser.h"
		#import "MGTwitterSocialGraphParser.h"
		#import "MGTwitterUserListsParser.h"
	#endif
#endif

#define TWITTER_DOMAIN          @"api.twitter.com/1"

#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
	#define TWITTER_SEARCH_DOMAIN	@"search.twitter.com"
#endif
#define HTTP_POST_METHOD        @"POST"
#define MAX_MESSAGE_LENGTH      140 // Twitter recommends tweets of max 140 chars
#define MAX_NAME_LENGTH			20
#define MAX_EMAIL_LENGTH		40
#define MAX_URL_LENGTH			100
#define MAX_LOCATION_LENGTH		30
#define MAX_DESCRIPTION_LENGTH	160

#define DEFAULT_CLIENT_NAME     @"MGTwitterEngine"
#define DEFAULT_CLIENT_VERSION  @"1.0"
#define DEFAULT_CLIENT_URL      @"http://mattgemmell.com/source"
#define DEFAULT_CLIENT_TOKEN	@"mgtwitterengine"

#define URL_REQUEST_TIMEOUT     25.0 // Twitter usually fails quickly if it's going to fail at all.

@interface NSDictionary (MGTwitterEngineExtensions)

-(NSDictionary *)MGTE_dictionaryByRemovingObjectForKey:(NSString *)key;

@end

@implementation NSDictionary (MGTwitterEngineExtensions)

-(NSDictionary *)MGTE_dictionaryByRemovingObjectForKey:(NSString *)key{
	NSDictionary *result = self;
	if(key){
		NSMutableDictionary *newParams = [[self mutableCopy] autorelease];
		[newParams removeObjectForKey:key];
		result = [[newParams copy] autorelease];
	}
	return result;
}

@end



@interface MGTwitterEngine (PrivateMethods)

// Utility methods
- (NSDateFormatter *)_HTTPDateFormatter;
- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed;
- (NSDate *)_HTTPToDate:(NSString *)httpDate;
- (NSString *)_dateToHTTP:(NSDate *)date;
- (NSString *)_encodeString:(NSString *)string;

// Connection/Request methods
- (NSString*)_sendRequest:(NSURLRequest *)theRequest withRequestType:(MGTwitterRequestType)requestType responseType:(MGTwitterResponseType)responseType;
- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params
                                body:(NSString *)body 
                         requestType:(MGTwitterRequestType)requestType 
                        responseType:(MGTwitterResponseType)responseType;

- (NSString *)_sendDataRequestWithMethod:(NSString *)method 
                                    path:(NSString *)path 
                         queryParameters:(NSDictionary *)params 
                                filePath:(NSString *)filePath
                                    body:(NSString *)body 
                             requestType:(MGTwitterRequestType)requestType 
                            responseType:(MGTwitterResponseType)responseType;

- (NSMutableURLRequest *)_baseRequestWithMethod:(NSString *)method 
                                           path:(NSString *)path 
                                    requestType:(MGTwitterRequestType)requestType 
                                queryParameters:(NSDictionary *)params;


// Parsing methods
- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection;

// Delegate methods
- (BOOL) _isValidDelegateForSelector:(SEL)selector;

@end


@implementation MGTwitterEngine


#pragma mark Constructors


+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)theDelegate
{
    return [[[self alloc] initWithDelegate:theDelegate] autorelease];
}


- (MGTwitterEngine *)initWithDelegate:(NSObject *)newDelegate
{
    if ((self = [super init])) {
        _delegate = newDelegate; // deliberately weak reference
        _connections = [[NSMutableDictionary alloc] initWithCapacity:0];
        _clientName = [DEFAULT_CLIENT_NAME retain];
        _clientVersion = [DEFAULT_CLIENT_VERSION retain];
        _clientURL = [DEFAULT_CLIENT_URL retain];
		_clientSourceToken = [DEFAULT_CLIENT_TOKEN retain];
		_APIDomain = [TWITTER_DOMAIN retain];
#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
		_searchDomain = [TWITTER_SEARCH_DOMAIN retain];
#endif

        _secureConnection = YES;
		_clearsCookies = NO;
#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
		_deliveryOptions = MGTwitterEngineDeliveryAllResultsOption;
#endif
    }
    
    return self;
}


- (void)dealloc
{
    _delegate = nil;
    
    [[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_connections release];
    
    [_username release];
    [_password release];
    [_clientName release];
    [_clientVersion release];
    [_clientURL release];
    [_clientSourceToken release];
	[_APIDomain release];
#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
	[_searchDomain release];
#endif
    
    [super dealloc];
}


#pragma mark Configuration and Accessors


+ (NSString *)version
{
    // 1.0.0 = 22 Feb 2008
    // 1.0.1 = 26 Feb 2008
    // 1.0.2 = 04 Mar 2008
    // 1.0.3 = 04 Mar 2008
	// 1.0.4 = 11 Apr 2008
	// 1.0.5 = 06 Jun 2008
	// 1.0.6 = 05 Aug 2008
	// 1.0.7 = 28 Sep 2008
	// 1.0.8 = 01 Oct 2008
    return @"1.0.8";
}

- (NSString *)clientName
{
    return [[_clientName retain] autorelease];
}


- (NSString *)clientVersion
{
    return [[_clientVersion retain] autorelease];
}


- (NSString *)clientURL
{
    return [[_clientURL retain] autorelease];
}


- (NSString *)clientSourceToken
{
    return [[_clientSourceToken retain] autorelease];
}


- (void)setClientName:(NSString *)name version:(NSString *)version URL:(NSString *)url token:(NSString *)token;
{
    [_clientName release];
    _clientName = [name retain];
    [_clientVersion release];
    _clientVersion = [version retain];
    [_clientURL release];
    _clientURL = [url retain];
    [_clientSourceToken release];
    _clientSourceToken = [token retain];
}


- (NSString *)APIDomain
{
	return [[_APIDomain retain] autorelease];
}


- (void)setAPIDomain:(NSString *)domain
{
	[_APIDomain release];
	if (!domain || [domain length] == 0) {
		_APIDomain = [TWITTER_DOMAIN retain];
	} else {
		_APIDomain = [domain retain];
	}
}


#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE

- (NSString *)searchDomain
{
	return [[_searchDomain retain] autorelease];
}


- (void)setSearchDomain:(NSString *)domain
{
	[_searchDomain release];
	if (!domain || [domain length] == 0) {
		_searchDomain = [TWITTER_SEARCH_DOMAIN retain];
	} else {
		_searchDomain = [domain retain];
	}
}

#endif


- (BOOL)usesSecureConnection
{
    return _secureConnection;
}


- (void)setUsesSecureConnection:(BOOL)flag
{
    _secureConnection = flag;
}


- (BOOL)clearsCookies
{
	return _clearsCookies;
}


- (void)setClearsCookies:(BOOL)flag
{
	_clearsCookies = flag;
}

#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE

- (MGTwitterEngineDeliveryOptions)deliveryOptions
{
	return _deliveryOptions;
}

- (void)setDeliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions
{
	_deliveryOptions = deliveryOptions;
}

#endif

#pragma mark Connection methods


- (NSUInteger)numberOfConnections
{
    return [_connections count];
}


- (NSArray *)connectionIdentifiers
{
    return [_connections allKeys];
}


- (void)closeConnection:(NSString *)connectionIdentifier
{
    MGTwitterHTTPURLConnection *connection = [_connections objectForKey:connectionIdentifier];
    if (connection) {
        [connection cancel];
        [_connections removeObjectForKey:connectionIdentifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
			[_delegate connectionFinished:connectionIdentifier];
    }
}


- (void)closeAllConnections
{
    [[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_connections removeAllObjects];
}


#pragma mark Utility methods


- (NSDateFormatter *)_HTTPDateFormatter
{
    // Returns a formatter for dates in HTTP format (i.e. RFC 822, updated by RFC 1123).
    // e.g. "Sun, 06 Nov 1994 08:49:37 GMT"
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	//[dateFormatter setDateFormat:@"%a, %d %b %Y %H:%M:%S GMT"]; // won't work with -init, which uses new (unicode) format behaviour.
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss GMT"];
	return dateFormatter;
}


- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed
{
    // Append base if specified.
    NSMutableString *str = [NSMutableString stringWithCapacity:0];
    if (base) {
        [str appendString:base];
    }
    
    // Append each name-value pair.
    if (params) {
        NSUInteger i;
        NSArray *names = [params allKeys];
        for (i = 0; i < [names count]; i++) {
            if (i == 0 && prefixed) {
                [str appendString:@"?"];
            } else if (i > 0) {
                [str appendString:@"&"];
            }
            NSString *name = [names objectAtIndex:i];
            [str appendString:[NSString stringWithFormat:@"%@=%@", 
             name, [self _encodeString:[params objectForKey:name]]]];
        }
    }
    
    return str;
}


- (NSDate *)_HTTPToDate:(NSString *)httpDate
{
    NSDateFormatter *dateFormatter = [self _HTTPDateFormatter];
    return [dateFormatter dateFromString:httpDate];
}


- (NSString *)_dateToHTTP:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [self _HTTPDateFormatter];
    return [dateFormatter stringFromDate:date];
}


- (NSString *)_encodeString:(NSString *)string
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
                                                                 (CFStringRef)string, 
                                                                 NULL, 
                                                                 (CFStringRef)@";/?:@&=$+{}<>,",
                                                                 kCFStringEncodingUTF8);
    return [result autorelease];
}


- (NSString *)getImageAtURL:(NSString *)urlString
{
    // This is a method implemented for the convenience of the client, 
    // allowing asynchronous downloading of users' Twitter profile images.
	NSString *encodedUrlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:encodedUrlString];
    if (!url) {
        return nil;
    }
    
    // Construct an NSMutableURLRequest for the URL and set appropriate request method.
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:URL_REQUEST_TIMEOUT];
    
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:MGTwitterImageRequest 
                                                        responseType:MGTwitterImage];
    
    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
        [connection release];
    }
	
	if ([self _isValidDelegateForSelector:@selector(connectionStarted:)])
		[_delegate connectionStarted:[connection identifier]];
    
    return [connection identifier];
}


#pragma mark Request sending methods

#define SET_AUTHORIZATION_IN_HEADER 0

- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params 
                                body:(NSString *)body 
                         requestType:(MGTwitterRequestType)requestType 
                        responseType:(MGTwitterResponseType)responseType
{

    NSMutableURLRequest *theRequest = [self _baseRequestWithMethod:method 
                                                              path:path
													requestType:requestType 
                                                   queryParameters:params];
    
    // Set the request body if this is a POST request.
    BOOL isPOST = (method && [method isEqualToString:HTTP_POST_METHOD]);
    if (isPOST) {
        // Set request body, if specified (hopefully so), with 'source' parameter if appropriate.
        NSString *finalBody = @"";
		if (body) {
			finalBody = [finalBody stringByAppendingString:body];
		}

        // if using OAuth, Twitter already knows your application's name, so don't send it
        if (_clientSourceToken && _accessToken == nil) {
            finalBody = [finalBody stringByAppendingString:[NSString stringWithFormat:@"%@source=%@", 
                                                            (body) ? @"&" : @"" , 
                                                            _clientSourceToken]];
        }
        
        if (finalBody) {
            [theRequest setHTTPBody:[finalBody dataUsingEncoding:NSUTF8StringEncoding]];
#if DEBUG
			if (YES) {
				NSLog(@"MGTwitterEngine: finalBody = %@", finalBody);
			}
#endif
        }
    }
	
	return [self _sendRequest:theRequest withRequestType:requestType responseType:responseType];
}

-(NSString*)_sendRequest:(NSURLRequest *)theRequest withRequestType:(MGTwitterRequestType)requestType responseType:(MGTwitterResponseType)responseType;
{
    
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:requestType 
                                                        responseType:responseType];
    
    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
        [connection release];
    }
	
	if ([self _isValidDelegateForSelector:@selector(connectionStarted:)])
		[_delegate connectionStarted:[connection identifier]];
    
    return [connection identifier];
}


- (NSString *)_sendDataRequestWithMethod:(NSString *)method 
                                    path:(NSString *)path 
                         queryParameters:(NSDictionary *)params 
                                filePath:(NSString *)filePath
                                    body:(NSString *)body 
                             requestType:(MGTwitterRequestType)requestType 
                            responseType:(MGTwitterResponseType)responseType
{
    
    NSMutableURLRequest *theRequest = [self _baseRequestWithMethod:method 
                                                              path:path
                                                       requestType:requestType
                                                   queryParameters:params];

    BOOL isPOST = (method && [method isEqualToString:HTTP_POST_METHOD]);
    if (isPOST) {
        NSString *boundary = @"0xKhTmLbOuNdArY";  
        NSString *filename = [filePath lastPathComponent];
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        
        NSString *bodyPrefixString   = [NSString stringWithFormat:@"--%@\r\n", boundary];
        NSString *bodySuffixString   = [NSString stringWithFormat:@"\r\n--%@--\r\n", boundary];
        NSString *contentDisposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"image\"; filename=\"%@\"\r\n", filename];
        NSString *contentImageType   = [NSString stringWithFormat:@"Content-Type: image/%@\r\n", [filename pathExtension]];
        NSString *contentTransfer    = @"Content-Transfer-Encoding: binary\r\n\r\n";
        
        
        NSMutableData *postBody = [NSMutableData data];
        
        [postBody appendData:[bodyPrefixString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
        [postBody appendData:[contentDisposition dataUsingEncoding:NSUTF8StringEncoding ]];
        [postBody appendData:[contentImageType dataUsingEncoding:NSUTF8StringEncoding ]];
        [postBody appendData:[contentTransfer dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:imageData];
        [postBody appendData:[bodySuffixString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
        
        [theRequest setHTTPBody:postBody];
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary, nil];
        [theRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
    }
    
    MGTwitterHTTPURLConnection *connection;
    
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:requestType 
                                                        responseType:responseType];
    
    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
        [connection release];
    }
	
	if ([self _isValidDelegateForSelector:@selector(connectionStarted:)])
		[_delegate connectionStarted:[connection identifier]];
    
    return [connection identifier];
    
}

#pragma mark Base Request 
- (NSMutableURLRequest *)_baseRequestWithMethod:(NSString *)method 
                                           path:(NSString *)path 
                                    requestType:(MGTwitterRequestType)requestType 
                                queryParameters:(NSDictionary *)params 
{
	NSString *contentType = [params objectForKey:@"Content-Type"];
	if(contentType){
		params = [params MGTE_dictionaryByRemovingObjectForKey:@"Content-Type"];
	}else{
		contentType = @"application/x-www-form-urlencoded";
	}
	
    // Construct appropriate URL string.
    NSString *fullPath = [path stringByAddingPercentEscapesUsingEncoding:NSNonLossyASCIIStringEncoding];
    if (params && ![method isEqualToString:HTTP_POST_METHOD]) {
        fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
    }
    
#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
	NSString *domain = nil;
	NSString *connectionType = nil;
	if (requestType == MGTwitterSearchRequest || requestType == MGTwitterSearchCurrentTrendsRequest)
	{
		domain = _searchDomain;
		connectionType = @"http";
	}
	else
	{
		domain = _APIDomain;
		if (_secureConnection)
		{
			connectionType = @"https";
		}
		else
		{
			connectionType = @"http";
		}
	}
#else
	NSString *domain = _APIDomain;
	NSString *connectionType = nil;
	if (_secureConnection)
	{
		connectionType = @"https";
	}
	else
	{
		connectionType = @"http";
	}
#endif
	
#if 1 // SET_AUTHORIZATION_IN_HEADER
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@", 
                           connectionType,
                           domain, fullPath];
#else    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@@%@/%@", 
                           connectionType, 
                           [self _encodeString:_username], [self _encodeString:_password], 
                           domain, fullPath];
#endif
    
    NSURL *finalURL = [NSURL URLWithString:urlString];
    if (!finalURL) {
        return nil;
    }
    
#if DEBUG
    if (YES) {
		NSLog(@"MGTwitterEngine: finalURL = %@", finalURL);
	}
#endif

    // Construct an NSMutableURLRequest for the URL and set appropriate request method.
	NSMutableURLRequest *theRequest = nil;
    if(_accessToken){
		theRequest = [[[OAMutableURLRequest alloc] initWithURL:finalURL
													  consumer:[[[OAConsumer alloc] initWithKey:[self consumerKey]
																						 secret:[self consumerSecret]] autorelease]
														 token:_accessToken
														 realm:nil
											 signatureProvider:nil] autorelease];
		[theRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData ];
		[theRequest setTimeoutInterval:URL_REQUEST_TIMEOUT];
	}else{
		theRequest = [NSMutableURLRequest requestWithURL:finalURL 
											 cachePolicy:NSURLRequestReloadIgnoringCacheData 
										 timeoutInterval:URL_REQUEST_TIMEOUT];
	}
    if (method) {
        [theRequest setHTTPMethod:method];
    }
    
    [theRequest setHTTPShouldHandleCookies:NO];
    
    // Set headers for client information, for tracking purposes at Twitter.
    [theRequest setValue:_clientName    forHTTPHeaderField:@"X-Twitter-Client"];
    [theRequest setValue:_clientVersion forHTTPHeaderField:@"X-Twitter-Client-Version"];
    [theRequest setValue:_clientURL     forHTTPHeaderField:@"X-Twitter-Client-URL"];
	
    [theRequest setValue:contentType    forHTTPHeaderField:@"Content-Type"];
    
#if SET_AUTHORIZATION_IN_HEADER
	if ([self username] && [self password]) {
		// Set header for HTTP Basic authentication explicitly, to avoid problems with proxies and other intermediaries
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", [self username], [self password]];
		NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
		NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:80]];
		[theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
	}
#endif
	
    return theRequest;
}

#pragma mark Parsing methods

#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection
{
    NSData *jsonData = [[[connection data] copy] autorelease];
    NSString *identifier = [[[connection identifier] copy] autorelease];
    MGTwitterRequestType requestType = [connection requestType];
    MGTwitterResponseType responseType = [connection responseType];

	NSURL *URL = [connection URL];

#if DEBUG
	if (NO) {
		NSLog(@"MGTwitterEngine: jsonData = %@ from %@", [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease], URL);
	}
#endif

#if YAJL_AVAILABLE
    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
            [MGTwitterStatusesYAJLParser parserWithJSON:jsonData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
            [MGTwitterUsersYAJLParser parserWithJSON:jsonData delegate:self 
                           connectionIdentifier:identifier requestType:requestType 
                                   responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
            [MGTwitterMessagesYAJLParser parserWithJSON:jsonData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
            break;
		case MGTwitterMiscellaneous:
			[MGTwitterMiscYAJLParser parserWithJSON:jsonData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
			break;
        case MGTwitterSearchResults:
 			[MGTwitterSearchYAJLParser parserWithJSON:jsonData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
			break;
		case MGTwitterOAuthToken:;
			OAToken *token = [[[OAToken alloc] initWithHTTPResponseBody:[[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease]] autorelease];
			[self parsingSucceededForRequest:identifier ofResponseType:requestType
						   withParsedObjects:[NSArray arrayWithObject:token]];
			break;
       default:
            break;
    }
#elif TOUCHJSON_AVAILABLE
	switch (responseType) {
		case MGTwitterOAuthToken:;
			OAToken *token = [[[OAToken alloc] initWithHTTPResponseBody:[[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease]] autorelease];
			[self parsingSucceededForRequest:identifier ofResponseType:requestType
						   withParsedObjects:[NSArray arrayWithObject:token]];
			break;
		default:
			[MGTwitterTouchJSONParser parserWithJSON:jsonData delegate:self
								connectionIdentifier:identifier requestType:requestType
										responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
			break;
	}
#endif
	
}
#else
- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection
{
    NSString *identifier = [[[connection identifier] copy] autorelease];
    NSData *xmlData = [[[connection data] copy] autorelease];
    MGTwitterRequestType requestType = [connection requestType];
    MGTwitterResponseType responseType = [connection responseType];
    
#if USE_LIBXML
	NSURL *URL = [connection URL];

    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
            [MGTwitterStatusesLibXMLParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType URL:URL];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
            [MGTwitterUsersLibXMLParser parserWithXML:xmlData delegate:self 
                           connectionIdentifier:identifier requestType:requestType 
                                   responseType:responseType URL:URL];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
            [MGTwitterMessagesLibXMLParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType URL:URL];
            break;
		case MGTwitterMiscellaneous:
			[MGTwitterMiscLibXMLParser parserWithXML:xmlData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType URL:URL];
			break;
		case MGTwitterSocialGraph:
			[MGTwitterSocialGraphLibXMLParser parserWithXML:xmlData delegate:self 
							connectionIdentifier:identifier requestType:requestType 
								responseType:responseType URL:URL];
			break;
		case MGTwitterOAuthToken:;
			OAToken *token = [[[OAToken alloc] initWithHTTPResponseBody:[[[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding] autorelease]] autorelease];
			[self parsingSucceededForRequest:identifier ofResponseType:requestType
						   withParsedObjects:[NSArray arrayWithObject:token]];
        default:
            break;
    }
#else
    // Determine which type of parser to use.
    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
            [MGTwitterStatusesParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
            [MGTwitterUsersParser parserWithXML:xmlData delegate:self 
                           connectionIdentifier:identifier requestType:requestType 
                                   responseType:responseType];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
            [MGTwitterMessagesParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType];
            break;
		case MGTwitterMiscellaneous:
			[MGTwitterMiscParser parserWithXML:xmlData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType];
			break;
		case MGTwitterUserLists:
			NSLog(@"response type: %d", responseType);
			[MGTwitterUserListsParser parserWithXML:xmlData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType];
			break;
			
		case MGTwitterSocialGraph:
			[MGTwitterSocialGraphParser parserWithXML:xmlData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType];
		case MGTwitterOAuthToken:;
			OAToken *token = [[[OAToken alloc] initWithHTTPResponseBody:[[[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding] autorelease]] autorelease];
			[self parsingSucceededForRequest:identifier ofResponseType:requestType
						   withParsedObjects:[NSArray arrayWithObject:token]];
        default:
            break;
    }
#endif
}
#endif

#pragma mark Delegate methods

- (BOOL) _isValidDelegateForSelector:(SEL)selector
{
	return ((_delegate != nil) && [_delegate respondsToSelector:selector]);
}

#pragma mark MGTwitterParserDelegate methods

- (void)parsingSucceededForRequest:(NSString *)identifier 
                    ofResponseType:(MGTwitterResponseType)responseType 
                 withParsedObjects:(NSArray *)parsedObjects
{
    // Forward appropriate message to _delegate, depending on responseType.
	NSLog(@"here at parsingSucceededForRequest");
    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
			if ([self _isValidDelegateForSelector:@selector(statusesReceived:forRequest:)])
				[_delegate statusesReceived:parsedObjects forRequest:identifier];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
			if ([self _isValidDelegateForSelector:@selector(userInfoReceived:forRequest:)])
				[_delegate userInfoReceived:parsedObjects forRequest:identifier];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
			if ([self _isValidDelegateForSelector:@selector(directMessagesReceived:forRequest:)])
				[_delegate directMessagesReceived:parsedObjects forRequest:identifier];
            break;
		case MGTwitterMiscellaneous:
			if ([self _isValidDelegateForSelector:@selector(miscInfoReceived:forRequest:)])
				[_delegate miscInfoReceived:parsedObjects forRequest:identifier];
			break;
#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE
		case MGTwitterSearchResults:
			if ([self _isValidDelegateForSelector:@selector(searchResultsReceived:forRequest:)])
				[_delegate searchResultsReceived:parsedObjects forRequest:identifier];
			break;
#endif
		case MGTwitterSocialGraph:
			if ([self _isValidDelegateForSelector:@selector(socialGraphInfoReceived:forRequest:)])
				[_delegate socialGraphInfoReceived: parsedObjects forRequest:identifier];
			break;
		case MGTwitterUserLists:
			if ([self _isValidDelegateForSelector:@selector(userListsReceived:forRequest:)])
				[_delegate userListsReceived: parsedObjects forRequest:identifier];
			break;			
		case MGTwitterOAuthTokenRequest:
			if ([self _isValidDelegateForSelector:@selector(accessTokenReceived:forRequest:)] && [parsedObjects count] > 0)
				[_delegate accessTokenReceived:[parsedObjects objectAtIndex:0]
									forRequest:identifier];
			break;
        default:
            break;
    }
}

- (void)parsingFailedForRequest:(NSString *)requestIdentifier 
                 ofResponseType:(MGTwitterResponseType)responseType 
                      withError:(NSError *)error
{
	if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
		[_delegate requestFailed:requestIdentifier withError:error];
}

#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE

- (void)parsedObject:(NSDictionary *)dictionary forRequest:(NSString *)requestIdentifier 
                 ofResponseType:(MGTwitterResponseType)responseType
{
	if ([self _isValidDelegateForSelector:@selector(receivedObject:forRequest:)])
		[_delegate receivedObject:dictionary forRequest:requestIdentifier];
}

#endif


#pragma mark NSURLConnection delegate methods


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if (_username && _password && [challenge previousFailureCount] == 0 && ![challenge proposedCredential]) {
		NSURLCredential *credential = [NSURLCredential credentialWithUser:_username password:_password 
															  persistence:NSURLCredentialPersistenceForSession];
		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
	} else {
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it has enough information to create the NSURLResponse.
    // it can be called multiple times, for example in the case of a redirect, so each time we reset the data.
    [connection resetDataLength];
    
    // Get response code.
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    [connection setResponse:resp];
    NSInteger statusCode = [resp statusCode];
    
    if (statusCode == 304 || [connection responseType] == MGTwitterGeneric) {
        // Not modified, or generic success.
		if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
			[_delegate requestSucceeded:[connection identifier]];
        if (statusCode == 304) {
            [self parsingSucceededForRequest:[connection identifier] 
                              ofResponseType:[connection responseType] 
                           withParsedObjects:[NSArray array]];
        }
        
        // Destroy the connection.
        [connection cancel];
		NSString *connectionIdentifier = [connection identifier];
		[_connections removeObjectForKey:connectionIdentifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
			[_delegate connectionFinished:connectionIdentifier];
    }
    
#if DEBUG
    if (NO) {
        // Display headers for debugging.
        NSHTTPURLResponse *respDebug = (NSHTTPURLResponse *)response;
        NSLog(@"MGTwitterEngine: (%ld) [%@]:\r%@", 
              (long)[resp statusCode], 
              [NSHTTPURLResponse localizedStringForStatusCode:[respDebug statusCode]], 
              [respDebug allHeaderFields]);
    }
#endif
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to the receivedData.
    [connection appendData:data];
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didFailWithError:(NSError *)error
{
	NSString *connectionIdentifier = [connection identifier];
	
    // Inform delegate.
	if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)]){
		[_delegate requestFailed:connectionIdentifier
					   withError:error];
	}
    
    // Release the connection.
    [_connections removeObjectForKey:connectionIdentifier];
	if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
		[_delegate connectionFinished:connectionIdentifier];
}


- (void)connectionDidFinishLoading:(MGTwitterHTTPURLConnection *)connection
{

    NSInteger statusCode = [[connection response] statusCode];

    if (statusCode >= 400) {
        // Assume failure, and report to delegate.
        NSData *receivedData = [connection data];
        NSString *body = [receivedData length] ? [NSString stringWithUTF8String:[receivedData bytes]] : @"";

        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [connection response], @"response",
                                  body, @"body",
                                  nil];
        NSError *error = [NSError errorWithDomain:@"HTTP" code:statusCode userInfo:userInfo];
		if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
			[_delegate requestFailed:[connection identifier] withError:error];

        // Destroy the connection.
        [connection cancel];
		NSString *connectionIdentifier = [connection identifier];
		[_connections removeObjectForKey:connectionIdentifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
			[_delegate connectionFinished:connectionIdentifier];
        return;
    }

    NSString *connID = nil;
	MGTwitterResponseType responseType = 0;
	connID = [connection identifier];
	responseType = [connection responseType];
	
    // Inform delegate.
	if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
		[_delegate requestSucceeded:connID];
    
    NSData *receivedData = [connection data];
    if (receivedData) {
#if DEBUG
        if (NO) {
            // Dump data as string for debugging.
            NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
            NSLog(@"MGTwitterEngine: Succeeded! Received %lu bytes of data:\r\r%@", (unsigned long)[receivedData length], dataString);
        }
        
        if (NO) {
            // Dump XML to file for debugging.
            NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
            [dataString writeToFile:[[NSString stringWithFormat:@"~/Desktop/twitter_messages.%@", API_FORMAT] stringByExpandingTildeInPath] 
                         atomically:NO encoding:NSUnicodeStringEncoding error:NULL];
        }
#endif
        
        if (responseType == MGTwitterImage) {
			// Create image from data.
#if TARGET_OS_IPHONE
            UIImage *image = [[[UIImage alloc] initWithData:[connection data]] autorelease];
#else
            NSImage *image = [[[NSImage alloc] initWithData:[connection data]] autorelease];
#endif
            
            // Inform delegate.
			if ([self _isValidDelegateForSelector:@selector(imageReceived:forRequest:)])
				[_delegate imageReceived:image forRequest:[connection identifier]];
        } else {
            // Parse data from the connection (either XML or JSON.)
            [self _parseDataForConnection:connection];
        }
    }
    
    // Release the connection.
    [_connections removeObjectForKey:connID];
	if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
		[_delegate connectionFinished:connID];
}

#pragma mark -
#pragma mark REST API methods
#pragma mark -

#pragma mark Status methods


- (NSString *)getPublicTimeline
{
    NSString *path = [NSString stringWithFormat:@"statuses/public_timeline.%@", API_FORMAT];
    
	return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterPublicTimelineRequest 
                           responseType:MGTwitterStatuses];
}


#pragma mark -

- (NSString *)getHomeTimelineSinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)page count:(int)count; // statuses/home_timeline
{
  return [self getHomeTimelineSinceID:sinceID withMaximumID:0 startingAtPage:page count:count];
}

- (NSString *)getHomeTimelineSinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)page count:(int)count; // statuses/home_timeline
{
  NSString *path = [NSString stringWithFormat:@"statuses/home_timeline.%@", API_FORMAT];
  
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
  if (sinceID > 0) {
    [params setObject:[NSString stringWithFormat:@"%llu", sinceID] forKey:@"since_id"];
  }
  if (maxID > 0) {
    [params setObject:[NSString stringWithFormat:@"%llu", maxID] forKey:@"max_id"];
  }
  if (page > 0) {
    [params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
  }
  if (count > 0) {
    [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
  }
  
  return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                          requestType:MGTwitterHomeTimelineRequest 
                         responseType:MGTwitterStatuses];
  
}

#pragma mark -

- (NSString *)getFollowedTimelineSinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)page count:(int)count
{
    return [self getFollowedTimelineSinceID:sinceID withMaximumID:0 startingAtPage:page count:count];
}

- (NSString *)getFollowedTimelineSinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)page count:(int)count
{
	NSString *path = [NSString stringWithFormat:@"statuses/friends_timeline.%@", API_FORMAT];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (sinceID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", sinceID] forKey:@"since_id"];
    }
    if (maxID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", maxID] forKey:@"max_id"];
    }
    if (page > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterFollowedTimelineRequest 
                           responseType:MGTwitterStatuses];
}


#pragma mark -


- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)page count:(int)count
{
    return [self getUserTimelineFor:username sinceID:sinceID withMaximumID:0 startingAtPage:0 count:count];
}

- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)page count:(int)count
{
	NSString *path = [NSString stringWithFormat:@"statuses/user_timeline.%@", API_FORMAT];
    MGTwitterRequestType requestType = MGTwitterUserTimelineRequest;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (sinceID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", sinceID] forKey:@"since_id"];
    }
    if (maxID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", maxID] forKey:@"max_id"];
    }
	if (page > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"statuses/user_timeline/%@.%@", username, API_FORMAT];
		requestType = MGTwitterUserTimelineForUserRequest;
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:requestType 
                           responseType:MGTwitterStatuses];
}


#pragma mark -


- (NSString *)getUpdate:(MGTwitterEngineID)updateID
{
    NSString *path = [NSString stringWithFormat:@"statuses/show/%llu.%@", updateID, API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterUpdateGetRequest
                           responseType:MGTwitterStatus];
}


- (NSString *)sendUpdate:(NSString *)status
{
    return [self sendUpdate:status inReplyTo:0];
}

- (NSString *)sendUpdate:(NSString *)status withLatitude:(MGTwitterEngineLocationDegrees)latitude longitude:(MGTwitterEngineLocationDegrees)longitude
{
    return [self sendUpdate:status inReplyTo:0 withLatitude:latitude longitude:longitude];
}

- (NSString *)sendUpdate:(NSString *)status inReplyTo:(MGTwitterEngineID)updateID
{
	return [self sendUpdate:status inReplyTo:updateID withLatitude:DBL_MAX longitude:DBL_MAX]; // DBL_MAX denotes invalid/unused location
}

- (NSString *)sendUpdate:(NSString *)status inReplyTo:(MGTwitterEngineID)updateID withLatitude:(MGTwitterEngineLocationDegrees)latitude longitude:(MGTwitterEngineLocationDegrees)longitude
{
    if (!status) {
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"statuses/update.%@", API_FORMAT];
    
	// Convert the status to Unicode Normalized Form C to conform to Twitter's character counting requirement. See http://apiwiki.twitter.com/Counting-Characters .
	NSString *trimmedText = [status precomposedStringWithCanonicalMapping];
    if ([trimmedText length] > MAX_MESSAGE_LENGTH) {
        trimmedText = [trimmedText substringToIndex:MAX_MESSAGE_LENGTH];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:trimmedText forKey:@"status"];
    if (updateID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", updateID] forKey:@"in_reply_to_status_id"];
    }
	if (latitude >= -90.0 && latitude <= 90.0 &&
		longitude >= -180.0 && longitude <= 180.0) {
		[params setObject:[NSString stringWithFormat:@"%.8f", latitude] forKey:@"lat"];
		[params setObject:[NSString stringWithFormat:@"%.8f", longitude] forKey:@"long"];
	}
	
    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:params body:body 
                            requestType:MGTwitterUpdateSendRequest
                           responseType:MGTwitterStatus];
}

- (NSString *)sendRetweet:(MGTwitterEngineID)tweetID {    
    NSString *path = [NSString stringWithFormat:@"statuses/retweet/%llu.%@", tweetID, API_FORMAT];
		
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:nil body:nil 
                            requestType:MGTwitterRetweetSendRequest
                           responseType:MGTwitterStatus];
}

#pragma mark -


- (NSString *)getRepliesStartingAtPage:(int)page
{
    return [self getRepliesSinceID:0 startingAtPage:page count:0]; // zero means default
}

- (NSString *)getRepliesSinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)page count:(int)count
{
    return [self getRepliesSinceID:sinceID withMaximumID:0 startingAtPage:page count:count];
}

- (NSString *)getRepliesSinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)page count:(int)count
{
// NOTE: identi.ca can't handle mentions URL yet...
//	NSString *path = [NSString stringWithFormat:@"statuses/mentions.%@", API_FORMAT];
	NSString *path = [NSString stringWithFormat:@"statuses/replies.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (sinceID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", sinceID] forKey:@"since_id"];
    }
    if (maxID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", maxID] forKey:@"max_id"];
    }
    if (page > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterRepliesRequest 
                           responseType:MGTwitterStatuses];
}


#pragma mark -


- (NSString *)deleteUpdate:(MGTwitterEngineID)updateID
{
    NSString *path = [NSString stringWithFormat:@"statuses/destroy/%llu.%@", updateID, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterUpdateDeleteRequest
                           responseType:MGTwitterStatus];
}


#pragma mark -


- (NSString *)getFeaturedUsers
{
    NSString *path = [NSString stringWithFormat:@"statuses/featured.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterFeaturedUsersRequest 
                           responseType:MGTwitterUsers];
}


#pragma mark User methods


- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username startingAtPage:(int)page
{
    NSString *path = [NSString stringWithFormat:@"statuses/friends.%@", API_FORMAT];
    MGTwitterRequestType requestType = MGTwitterFriendUpdatesRequest;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (username) {
        path = [NSString stringWithFormat:@"statuses/friends/%@.%@", username, API_FORMAT];
		requestType = MGTwitterFriendUpdatesForUserRequest;
    }
    if (page > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:requestType 
                           responseType:MGTwitterUsers];
}


#pragma mark -


- (NSString *)getFollowersIncludingCurrentStatus:(BOOL)flag
{
    NSString *path = [NSString stringWithFormat:@"statuses/followers.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (!flag) {
        [params setObject:@"true" forKey:@"lite"]; // slightly bizarre, but correct.
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterFollowerUpdatesRequest
                           responseType:MGTwitterUsers];
}


#pragma mark -


- (NSString *)getUserInformationFor:(NSString *)usernameOrID
{
    if (!usernameOrID) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"users/show/%@.%@", usernameOrID, API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterUserInformationRequest 
                           responseType:MGTwitterUser];
}

- (NSString *)getBulkUserInformationFor:(NSString *)userIDs
{
    if (!userIDs) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"users/lookup.%@?user_id=%@", API_FORMAT, userIDs];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];


    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterBulkUserInformationRequest 
                           responseType:MGTwitterUsers];
}


- (NSString *)getUserInformationForEmail:(NSString *)email
{
    NSString *path = [NSString stringWithFormat:@"users/show.%@", API_FORMAT];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (email) {
        [params setObject:email forKey:@"email"];
    } else {
        return nil;
    }

    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInformationRequest 
                           responseType:MGTwitterUser];
}


#pragma mark Direct Message methods


- (NSString *)getDirectMessagesSinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)page
{
    return [self getDirectMessagesSinceID:sinceID withMaximumID:0 startingAtPage:page count:0];
}

- (NSString *)getDirectMessagesSinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)page count:(int)count
{
    NSString *path = [NSString stringWithFormat:@"direct_messages.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (sinceID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", sinceID] forKey:@"since_id"];
    }
    if (maxID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", maxID] forKey:@"max_id"];
    }
    if (page > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}


#pragma mark -

- (NSString *)getSentDirectMessagesSinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)page
{
    return [self getSentDirectMessagesSinceID:sinceID withMaximumID:0 startingAtPage:page count:0];
}

- (NSString *)getSentDirectMessagesSinceID:(MGTwitterEngineID)sinceID withMaximumID:(MGTwitterEngineID)maxID startingAtPage:(int)page count:(int)count
{
    NSString *path = [NSString stringWithFormat:@"direct_messages/sent.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (sinceID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", sinceID] forKey:@"since_id"];
    }
    if (maxID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", maxID] forKey:@"max_id"];
    }
    if (page > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesSentRequest 
                           responseType:MGTwitterDirectMessages];
}


#pragma mark -


- (NSString *)sendDirectMessage:(NSString *)message to:(NSString *)username
{
    if (!message || !username) {
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"direct_messages/new.%@", API_FORMAT];
    
    NSString *trimmedText = message;
    if ([trimmedText length] > MAX_MESSAGE_LENGTH) {
        trimmedText = [trimmedText substringToIndex:MAX_MESSAGE_LENGTH];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:trimmedText forKey:@"text"];
    [params setObject:username forKey:@"user"];
    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:params body:body 
                            requestType:MGTwitterDirectMessageSendRequest
                           responseType:MGTwitterDirectMessage];
}


- (NSString *)deleteDirectMessage:(MGTwitterEngineID)updateID
{
    NSString *path = [NSString stringWithFormat:@"direct_messages/destroy/%llu.%@", updateID, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterDirectMessageDeleteRequest 
                           responseType:MGTwitterDirectMessage];
}

#pragma mark Lists
 
- (NSString *)getListsForUser:(NSString *)username
{
	NSString *path = [NSString stringWithFormat:@"%@/lists.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterUserListsRequest 
                           responseType:MGTwitterUserLists];
}

- (NSString *)createListForUser:(NSString *)username withName:(NSString *)listName withOptions:(NSDictionary *)options;
{
	if (!username || !listName) {
		NSLog(@"returning nil");
		return nil;
	}
	
	NSString *path = [NSString stringWithFormat:@"%@/lists.%@", username, API_FORMAT];
	
    NSMutableDictionary *queryParameters = [NSMutableDictionary dictionaryWithCapacity:0];
	if ([options objectForKey:@"mode"]) {
		[queryParameters setObject:[options objectForKey:@"mode"] forKey:@"mode"];
	}
	if ([options objectForKey:@"description"]) {
		[queryParameters setObject:[options objectForKey:@"description"] forKey:@"description"];
	}
	[queryParameters setObject:listName forKey:@"name"];
    NSString *body = [self _queryStringWithBase:nil parameters:queryParameters prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:queryParameters body:body 
                            requestType:MGTwitterUserListCreate
                           responseType:MGTwitterUserLists];
}

- (NSString *)updateListForUser:(NSString *)username withID:(MGTwitterEngineID)listID withOptions:(NSDictionary *)options
{
	if (!username || !listID) {
		NSLog(@"returning nil");
		return nil;
	}
	NSString *path = [NSString stringWithFormat:@"%@/lists/%llu.%@", username, listID, API_FORMAT];
	
    NSMutableDictionary *queryParameters = [NSMutableDictionary dictionaryWithCapacity:0];
	if ([options objectForKey:@"name"]) {
		[queryParameters setObject:[options objectForKey:@"name"] forKey:@"name"];
	}
	if ([options objectForKey:@"mode"]) {
		[queryParameters setObject:[options objectForKey:@"mode"] forKey:@"mode"];
	}
	if ([options objectForKey:@"description"]) {
		[queryParameters setObject:[options objectForKey:@"description"] forKey:@"description"];
	}
	
    NSString *body = [self _queryStringWithBase:nil parameters:queryParameters prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:queryParameters body:body 
                            requestType:MGTwitterUserListCreate
                           responseType:MGTwitterUserLists];
}

- (NSString *)getListForUser:(NSString *)username withID:(MGTwitterEngineID)listID
{
	if (!username || !listID) {
		NSLog(@"returning nil");
		return nil;
	}
	NSString *path = [NSString stringWithFormat:@"%@/lists/%llu.%@", username, listID, API_FORMAT];
	
    NSString *body = [self _queryStringWithBase:nil parameters:nil prefixed:NO];
    
    return [self _sendRequestWithMethod:nil path:path 
                        queryParameters:nil body:body 
                            requestType:MGTwitterUserListCreate
                           responseType:MGTwitterUserLists];
}

#pragma mark Friendship methods


- (NSString *)enableUpdatesFor:(NSString *)username
{
    // i.e. follow
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"friendships/create/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterUpdatesEnableRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)disableUpdatesFor:(NSString *)username
{
    // i.e. no longer follow
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"friendships/destroy/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterUpdatesDisableRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)isUser:(NSString *)username1 receivingUpdatesFor:(NSString *)username2
{
	if (!username1 || !username2) {
        return nil;
    }
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:username1 forKey:@"user_a"];
	[params setObject:username2 forKey:@"user_b"];
	
    NSString *path = [NSString stringWithFormat:@"friendships/exists.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUpdatesCheckRequest 
                           responseType:MGTwitterMiscellaneous];
}


#pragma mark Account methods


- (NSString *)checkUserCredentials
{
    NSString *path = [NSString stringWithFormat:@"account/verify_credentials.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)endUserSession
{
    NSString *path = @"account/end_session"; // deliberately no format specified
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterGeneric];
}


- (NSString *)setProfileImageWithImageAtPath:(NSString *)pathToFile
{
    NSString *path = [NSString stringWithFormat:@"account/update_profile_image.%@", API_FORMAT];
    
    return [self _sendDataRequestWithMethod:HTTP_POST_METHOD 
                                       path:path 
                            queryParameters:nil
                                   filePath:pathToFile
                                       body:nil 
                                requestType:MGTwitterAccountRequest 
                               responseType:MGTwitterGeneric];
}


- (NSString *)setProfileBackgroundImageWithImageAtPath:(NSString *)pathToFile andTitle:(NSString *)title
{
    NSString *path = [NSString stringWithFormat:@"account/update_profile_background_image.%@", API_FORMAT];
 
    NSMutableDictionary *params = nil;
    if (title) {
        params = [NSMutableDictionary dictionaryWithCapacity:0];
        [params setObject:title forKey:@"title"];
    }
    
    
    return [self _sendDataRequestWithMethod:HTTP_POST_METHOD 
                                       path:path 
                            queryParameters:params
                                   filePath:pathToFile
                                       body:nil 
                                requestType:MGTwitterAccountRequest 
                               responseType:MGTwitterGeneric];
}

#pragma mark -


// TODO: this API is deprecated, change to account/update_profile
- (NSString *)setLocation:(NSString *)location
{
	if (!location) {
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"account/update_location.%@", API_FORMAT];
    
    NSString *trimmedLocation = location;
    if ([trimmedLocation length] > MAX_LOCATION_LENGTH) {
        trimmedLocation = [trimmedLocation substringToIndex:MAX_LOCATION_LENGTH];
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:trimmedLocation forKey:@"location"];
    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:params body:body 
                            requestType:MGTwitterAccountLocationRequest 
                           responseType:MGTwitterUser];
}



#pragma mark -


- (NSString *)setNotificationsDeliveryMethod:(NSString *)method
{
	NSString *deliveryMethod = method;
	if (!method || [method length] == 0) {
		deliveryMethod = @"none";
	}
	
	NSString *path = [NSString stringWithFormat:@"account/update_delivery_device.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (deliveryMethod) {
        [params setObject:deliveryMethod forKey:@"device"];
    }
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:params body:nil 
                            requestType:MGTwitterAccountDeliveryRequest
                           responseType:MGTwitterUser];
}


#pragma mark -


- (NSString *)getRateLimitStatus
{
	NSString *path = [NSString stringWithFormat:@"account/rate_limit_status.%@", API_FORMAT];
	
	return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountStatusRequest 
                           responseType:MGTwitterMiscellaneous];
}


#pragma mark Favorite methods


- (NSString *)getFavoriteUpdatesFor:(NSString *)username startingAtPage:(int)page
{
    NSString *path = [NSString stringWithFormat:@"favorites.%@", API_FORMAT];
    MGTwitterRequestType requestType = MGTwitterFavoritesRequest;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (page > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"favorites/%@.%@", username, API_FORMAT];
		requestType = MGTwitterFavoritesForUserRequest;
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:requestType 
                           responseType:MGTwitterStatuses];
}


#pragma mark -


- (NSString *)markUpdate:(MGTwitterEngineID)updateID asFavorite:(BOOL)flag
{
	NSString *path = nil;
	MGTwitterRequestType requestType;
	if (flag)
	{
		path = [NSString stringWithFormat:@"favorites/create/%llu.%@", updateID, API_FORMAT];
		requestType = MGTwitterFavoritesEnableRequest;
    }
	else {
		path = [NSString stringWithFormat:@"favorites/destroy/%llu.%@", updateID, API_FORMAT];
		requestType = MGTwitterFavoritesDisableRequest;
	}
	
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:requestType 
                           responseType:MGTwitterStatus];
}


#pragma mark Notification methods


- (NSString *)enableNotificationsFor:(NSString *)username
{
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"notifications/follow/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterNotificationsEnableRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)disableNotificationsFor:(NSString *)username
{
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"notifications/leave/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterNotificationsDisableRequest 
                           responseType:MGTwitterUser];
}


#pragma mark Block methods


- (NSString *)block:(NSString *)username
{
	if (!username) {
		return nil;
	}
	
	NSString *path = [NSString stringWithFormat:@"blocks/create/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterBlockEnableRequest
                           responseType:MGTwitterUser];
}


- (NSString *)unblock:(NSString *)username
{
	if (!username) {
		return nil;
	}
	
	NSString *path = [NSString stringWithFormat:@"blocks/destroy/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterBlockDisableRequest
                           responseType:MGTwitterUser];
}


#pragma mark Help methods


- (NSString *)testService
{
	NSString *path = [NSString stringWithFormat:@"help/test.%@", API_FORMAT];
	
	return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterMiscellaneous];
}


- (NSString *)getDowntimeSchedule
{
	NSString *path = [NSString stringWithFormat:@"help/downtime_schedule.%@", API_FORMAT];
	
	return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterMiscellaneous];
}

#pragma mark Social Graph methods


- (NSString *)getFriendIDsFor:(NSString *)username startingFromCursor:(MGTwitterEngineCursorID)cursor
{
	//NSLog(@"getFriendIDsFor:%@ atCursor:%lld", username, cursor);
	if (cursor == 0 || [username isEqualToString:@""])
		return nil;

    NSString *path = [NSString stringWithFormat:@"friends/ids.%@", API_FORMAT];
	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (username) {
        path = [NSString stringWithFormat:@"friends/ids/%@.%@", username, API_FORMAT];
    }
	
	[params setObject:[NSString stringWithFormat:@"%lld", cursor] forKey:@"cursor"];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterFriendIDsRequest 
                           responseType:MGTwitterSocialGraph];	
}


- (NSString *)getFollowerIDsFor:(NSString *)username startingFromCursor:(MGTwitterEngineCursorID)cursor
{
	//NSLog(@"getFollowerIDsFor:%@ atCursor:%lld", username, cursor);
	if (cursor == 0 || [username isEqualToString:@""])
		return nil;
	
	NSString *path = [NSString stringWithFormat:@"followers/ids.%@", API_FORMAT];
	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (username) {		
        path = [NSString stringWithFormat:@"followers/ids/%@.%@", username, API_FORMAT];
    }
	
	[params setObject:[NSString stringWithFormat:@"%lld", cursor] forKey:@"cursor"];
	
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterFollowerIDsRequest 
                           responseType:MGTwitterSocialGraph];	
}


#if YAJL_AVAILABLE || TOUCHJSON_AVAILABLE

#pragma mark -
#pragma mark Search API methods
#pragma mark -


#pragma mark Search

- (NSString *)getSearchResultsForQuery:(NSString *)query
{
    return [self getSearchResultsForQuery:query sinceID:0 startingAtPage:0 count:0]; // zero means default
}


- (NSString *)getSearchResultsForQuery:(NSString *)query sinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)page count:(int)count
{
    return [self getSearchResultsForQuery:query sinceID:sinceID startingAtPage:page count:count geocode:nil]; // zero means default
}

- (NSString *)getSearchResultsForQuery:(NSString *)query sinceID:(MGTwitterEngineID)sinceID startingAtPage:(int)page count:(int)count geocode:(NSString *)geocode
{
    NSString *path = [NSString stringWithFormat:@"search.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
	if (query) {
		[params setObject:query forKey:@"q"];
	}
    if (sinceID > 0) {
        [params setObject:[NSString stringWithFormat:@"%llu", sinceID] forKey:@"since_id"];
    }
	if (page > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"rpp"];
    }
    if (geocode) {
        [params setObject:geocode forKey:@"geocode"];
    }
	
	/*
	NOTE: These parameters are also available but not implemented yet:
	
		lang: restricts tweets to the given language, given by an ISO 639-1 code.

			Ex: http://search.twitter.com/search.atom?lang=en&q=devo

		geocode: returns tweets by users located within a given radius of the given latitude/longitude, where the user's
			location is taken from their Twitter profile. The parameter value is specified by "latitide,longitude,radius",
			where radius units must be specified as either "mi" (miles) or "km" (kilometers).

			Note that you cannot use the near operator via the API to geocode arbitrary locations; however you can use this
			geocode parameter to search near geocodes directly.

			Ex: http://search.twitter.com/search.atom?geocode=40.757929%2C-73.985506%2C25km
	*/

	
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterSearchRequest 
                           responseType:MGTwitterSearchResults];
}


- (NSString *)getCurrentTrends
{
    NSString *path = [NSString stringWithFormat:@"trends/current.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterSearchCurrentTrendsRequest 
                           responseType:MGTwitterSearchResults];
}


#endif

@end

@implementation MGTwitterEngine (BasicAuth)

- (NSString *)username
{
    return [[_username retain] autorelease];
}

- (void)setUsername:(NSString *)newUsername
{
    // Set new credentials.
    [_username release];
    _username = [newUsername retain];
}

- (NSString *)password
{
    return [[_password retain] autorelease];
}


- (void)setUsername:(NSString *)newUsername password:(NSString *)newPassword
{
    // Set new credentials.
    [_username release];
    _username = [newUsername retain];
    [_password release];
    _password = [newPassword retain];
    
	if ([self clearsCookies]) {
		// Remove all cookies for twitter, to ensure next connection uses new credentials.
		NSString *urlString = [NSString stringWithFormat:@"%@://%@", 
							   (_secureConnection) ? @"https" : @"http", 
							   _APIDomain];
		NSURL *url = [NSURL URLWithString:urlString];
		
		NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		NSEnumerator *enumerator = [[cookieStorage cookiesForURL:url] objectEnumerator];
		NSHTTPCookie *cookie = nil;
		while ((cookie = [enumerator nextObject])) {
			[cookieStorage deleteCookie:cookie];
		}
	}
}

@end

@implementation MGTwitterEngine (OAuth)

- (void)setConsumerKey:(NSString *)key secret:(NSString *)secret{
	[_consumerKey autorelease];
	_consumerKey = [key copy];
	
	[_consumerSecret autorelease];
	_consumerSecret = [secret copy];
}

- (NSString *)consumerKey{
	return _consumerKey;
}

- (NSString *)consumerSecret{
	return _consumerSecret;
}

- (void)setAccessToken: (OAToken *)token{
	[_accessToken autorelease];
	_accessToken = [token retain];
}

- (OAToken *)accessToken{
	return _accessToken;
}

- (NSString *)getXAuthAccessTokenForUsername:(NSString *)username 
									password:(NSString *)password{
	OAConsumer *consumer = [[[OAConsumer alloc] initWithKey:[self consumerKey] secret:[self consumerSecret]] autorelease];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"]
																   consumer:consumer
																	  token:nil // xAuth needs no request token?
																	  realm:nil   // our service provider doesn't specify a realm
														  signatureProvider:nil]; // use the default method, HMAC-SHA1
	
	[request setHTTPMethod:@"POST"];
	
	[request setParameters:[NSArray arrayWithObjects:
							[OARequestParameter requestParameter:@"x_auth_mode" value:@"client_auth"],
							[OARequestParameter requestParameter:@"x_auth_username" value:username],
							[OARequestParameter requestParameter:@"x_auth_password" value:password],
							nil]];		
	
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:request
                                                            delegate:self 
                                                         requestType:MGTwitterOAuthTokenRequest
                                                        responseType:MGTwitterOAuthToken];

    [request release], request = nil;

    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
        [connection release];
    }
	
	if ([self _isValidDelegateForSelector:@selector(connectionStarted:)])
		[_delegate connectionStarted:[connection identifier]];
    
    return [connection identifier];
}

@end


