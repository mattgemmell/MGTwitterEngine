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
 Set this if the YAJL JSON parser is available. More information about this parser here:

 http://lloydforge.org/projects/yajl/

 There are some speed advantages to using JSON instead of XML. Also, the Twitter Search API
 uses JSON, so adding this library to your project makes additional methods available to your
 application.
*/

#define YAJL_AVAILABLE 0

