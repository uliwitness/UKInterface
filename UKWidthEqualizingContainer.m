//
//  UKWidthEqualizingContainer.m
//  UKInterface
//
//  Created by Uli Kusterer on 28.09.08.
//  Copyright 2008 The Void Software. All rights reserved.
//

#import "UKWidthEqualizingContainer.h"


@implementation UKWidthEqualizingContainer

-(id)	initWithFrame: (NSRect)box
{
	if(( self = [super initWithFrame: box] ))
	{
		distanceBetweenViews = 0.0;
		marginAroundView = 8.0;
	}
	return self;
}

-(void)	didAddSubview: (NSView*)subview
{
	[super didAddSubview: subview];
		
	// Determine highest height and widest width:
	CGFloat			maxWidth = 0, maxHeight = 0;
	NSEnumerator*	enny = [[self subviews] objectEnumerator];
	NSView*			currView = nil;
	while(( currView = [enny nextObject] ))
	{
		NSRect	box = [currView frame];
		if( box.size.width > maxWidth )
			maxWidth = box.size.width;
		if( box.size.height > maxHeight )
			maxHeight = box.size.height;
	}
	
	// Make all views that wide:
	enny = [[self subviews] objectEnumerator];
	NSRect		currBox = NSMakeRect( marginAroundView, marginAroundView, 0, 0 );
	while(( currView = [enny nextObject] ))
	{
		currBox.size = [currView frame].size;
		currBox.size.width = maxWidth;
		[currView setFrame: currBox];
		currBox.origin.x += currBox.size.width +distanceBetweenViews;
	}
	
	// Make this view fit around its subviews:
	NSUInteger	sizingFlags = [self autoresizingMask];
	NSRect		newFrame = [self frame];
	NSSize		oldSize = newFrame.size;
	newFrame.size.height = maxHeight +marginAroundView *2;
	if( !(sizingFlags & NSViewWidthSizable) )
	{
		newFrame.size.width = currBox.origin.x +marginAroundView -distanceBetweenViews;
		if( sizingFlags & NSViewMinXMargin )
			newFrame.origin.x -= newFrame.size.width -oldSize.width;
	}
	[self setFrame: newFrame];
}


-(void)	drawRect: (NSRect)dirtyBox
{
//	[[NSColor redColor] set];
//	NSFrameRectWithWidth( [self bounds], 1 );
}

@end
