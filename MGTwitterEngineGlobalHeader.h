//
//  MGTwitterEngineGlobalHeader.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 09/08/2008.
//  Copyright 2008 Instinctive Code.
//

/*
 The first section of this global header allows you to make MGTwitterEngine work with 
 target platforms other than Mac OS X. To do so, your target platform should be supported 
 for development on Mac OS X, and should have a preset definition to indicate that it 
 is currently being compiled for.
 
 Your target platform should also include an image-object class which is API-compatible with 
 the NSImage class from Cocoa's AppKit framework. You can create a wrapper class if needed.
 
 To compile for that platform, you would:
 
 1. Ensure appropriate frameworks etc are linked in your Xcode project.
 
 2. Change "TARGET_OS_MG_NEW_COOL_PLATFORM" below to the platform's actual target definition.
 
 3. Change the "MGBaseFramework" and "MGAppFramework" imports below to reflect actual frameworks.
 
 4. Change "MGImage" below to the actual class-name of the NSImage-like image class on your platform.
 
 5. If your platform includes LibXML and you plan to use it, ensure that libxml is appropriately linked,
	and that appropriate Header Search Paths are set in your project.
*/

#if TARGET_OS_MG_NEW_COOL_PLATFORM						// for example
	#import <MGBaseFramework/MGBaseFramework.h>			// for example
	#import <MGAppFramework/MGAppFramework.h>			// for example
	#define MG_ALT_PLATFORM_IMAGE_CLASS	"MGImage"		// for example

	#define MG_ALT_PLATFORM						1		// DO NOT CHANGE
#else
	#import <Cocoa/Cocoa.h>
#endif
