//
//  AppDelegate.m
//  UKInterface
//
//  Created by Uli Kusterer on 28.09.08.
//  Copyright 2008 The Void Software. All rights reserved.
//

#import "AppDelegate.h"
#import "UKInterface.h"


@implementation AppDelegate

@synthesize theWindow;
@synthesize theMenu;
@synthesize buttonDelegate;


-(void)	applicationDidFinishLaunching: (NSNotification*)sender
{
	UKInterface	* nib = [UKInterface interfaceNamed: @"TestUI"];
	[nib loadWithOwner: self];
	
	//NSLog(@"%@", theMenu);
	//NSLog(@"%@", theWindow);
	//NSLog(@"%@", buttonDelegate);
}

@end
