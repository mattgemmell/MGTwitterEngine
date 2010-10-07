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
#define TOUCHJSON_AVAILABLE 1

#ifndef __MGTWITTERENGINEID__
#define __MGTWITTERENGINEID__
typedef unsigned long long MGTwitterEngineID;
typedef long long MGTwitterEngineCursorID;
#endif

#ifndef __MGTWITTERENGINELOCATIONDEGREES__
#define __MGTWITTERENGINELOCATIONDEGREES__
typedef double MGTwitterEngineLocationDegrees;
#endif
