//
//  UKInterface.h
//  UKInterface
//
//  Created by Uli Kusterer on 28.09.08.
//  Copyright 2008 The Void Software. All rights reserved.
//

/*
	A class that replaces NSNib and provides an XML-based way of specifying
	the contents of a window. Like Matisse or similar tools, the idea is to
	specify a UI without having to provide coordinates, and to instead specify
	the alignments and sizings of the individual views only.
*/

#import <Cocoa/Cocoa.h>


@interface UKInterface : NSObject
{
	NSMutableDictionary*	objectDescriptions;
	NSMutableArray*			currentTagStack;
	NSMutableDictionary*	idToObjectMappings;
	NSMutableArray*			connections;
	int						dynamicIDSeed;
}

+(id)			interfaceNamed: (NSString*)filename;

-(id)			initWithName: (NSString*)filename;				// Fetch it from resources.
-(id)			initWithContentsOfFile: (NSString*)filename;	// Full file path.

-(void)			loadWithOwner: (id)owner;

// private:
-(NSMenu*)		loadMenu: (NSDictionary*)dict withOwner: (id)owner;
-(NSMenuItem*)	loadMenuItem: (NSDictionary*)dict withOwner: (id)owner;
-(NSWindow*)	loadWindow: (NSDictionary*)dict withOwner: (id)owner;
-(id)			loadObject: (NSDictionary*)dict withOwner: (id)owner;

-(void)			loadSubviews: (NSArray*)objects intoView: (NSView*)superView withOwner: (id)owner;
-(NSView*)		loadView: (NSDictionary*)currDict withSuperview: (NSView*)container withOwner: (id)owner;
-(NSAttributedString*) loadHTMLStyledText: (NSString*)originalHtmlString;

-(void)			rememberConnection: (NSDictionary*)dict;

@end
