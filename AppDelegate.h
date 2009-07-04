//
//  AppDelegate.h
//  UKInterface
//
//  Created by Uli Kusterer on 28.09.08.
//  Copyright 2008 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UKTestObject;


@interface AppDelegate : NSObject
{
	IBOutlet NSWindow*	theWindow;
	IBOutlet NSMenu*	theMenu;
	UKTestObject*		buttonDelegate;
}

@property (retain) NSWindow*		theWindow;
@property (retain) NSMenu*			theMenu;
@property (retain) UKTestObject*	buttonDelegate;

@end
