//
//  MGTwitterEngineGlobalHeader.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 09/08/2008.
//  Copyright 2008 Instinctive Code.
//

/*
 This file conditionally includes the correct headers for either Mac OS X or iPhone deployment.
*/

#if TARGET_OS_IPHONE
	#import <Foundation/Foundation.h>
	#import <UIKit/UIKit.h>
#else
	#import <Cocoa/Cocoa.h>
#endif

/*
 Set YAJL_AVAILABLE to 1 if the YAJL JSON parser is available and you'd like MGTwitterEngine to use it.
 
 More information about this parser here:

 http://lloydforge.org/projects/yajl/

 There are some speed advantages to using JSON instead of XML. Also, the Twitter Search API
 uses JSON, so adding this library to your project makes additional methods available to your
 application.
 
 Be aware, however, that the data types in the dictionaries returned by JSON may be different
 than the ones returned by XML. There is more type information in a JSON stream, so you may find
 that you get an NSNumber value instead of an NSString value for some keys in the dictionary.
 Make sure to test the new result sets in your application after switching from XML to JSON.
 
 Likewise, some keys may differ between the XML and JSON parsers. An example is the hourly limit
 returned by the getRateLimitStatus: method. For JSON, the key is "hourly_limit", for XML it is
 "hourly-limit".
 
 The event driven nature of the YAJL parser also allows delivery options to be specified. By
 default, all results are returned as an array of dictionaries. In some environments, such as the
 iPhone, the memory overhead of putting all the data into the array can be avoided by choosing
 the individual results option. This allows your application to process and store results without
 instantatiating a large collection and then enumerating over the items.
 
 If you want to use YAJL, change the following definition and make sure that the
 MGTwitterEngine*YAJLParser.m files are added to the Compile Sources phase of the MGTwitterEngine
 target.
*/

#define YAJL_AVAILABLE 0
#define TOUCHJSON_AVAILABLE 0

#if YAJL_AVAILABLE
	/*
	 When enabled, this definition artificially adds 0x7ffffff to each tweet ID that is read from the API. It
	 also subtracts 0x7fffffff from anything it sends back to the API. This allows you to test your application
	 code and make sure it works well with large unsigned longs. This is important because tweet IDs that are
	 treated as signed integers will become negative after 2^32 - 1 (0x7fffffff). This will happen sometime
	 around the end of May 2009.
	 
	 A future release of MGTwitterEngine will use 64-bit integers for the tweet IDs. The current change is
	 meant as a stopgap measure that will affect existing applications as little as possible.
	*/

	#define LARGE_ID_TEST 0
#else
	/*
	 This option is only available when you are using the YAJL parser. Do not change the following definition.
	*/
	#define LARGE_ID_TEST 0
#endif

#ifndef __MGTWITTERENGINEID__
#define __MGTWITTERENGINEID__
typedef unsigned long long MGTwitterEngineID;
typedef long long MGTwitterEngineCursorID;
#endif

#ifndef __MGTWITTERENGINELOCATIONDEGREES__
#define __MGTWITTERENGINELOCATIONDEGREES__
typedef double MGTwitterEngineLocationDegrees;
#endif
