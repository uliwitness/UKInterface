//
//  UKAvailableSpaceFillingContainerView.m
//  UKInterface
//
//  Created by Uli Kusterer on 28.09.08.
//  Copyright 2008 The Void Software. All rights reserved.
//

#import "UKAvailableSpaceFillingContainerView.h"


@implementation UKAvailableSpaceFillingContainerView

@synthesize tuckUnderSuperEdges;

-(id)	initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if( self )
	{
        tuckUnderSuperEdges = YES;
    }
    return self;
}

-(void)	viewDidMoveToSuperview
{
	// Build two sets containing all available ranges:
	NSEnumerator*		enny = [[[self superview] subviews] objectEnumerator];
	NSView*				peer = nil;
	NSSize				mySize = [self bounds].size;
	NSMutableIndexSet*	hIndexes = [NSMutableIndexSet indexSetWithIndexesInRange: NSMakeRange( 0, mySize.width)];
	NSMutableIndexSet*	vIndexes = [NSMutableIndexSet indexSetWithIndexesInRange: NSMakeRange( 0, mySize.height)];
	
	while(( peer = [enny nextObject] ))
	{
		NSRect		box = [peer frame];
		if( peer != self )
		{
			[hIndexes removeIndexesInRange: NSMakeRange( box.origin.x, box.size.width)];
			[vIndexes removeIndexesInRange: NSMakeRange( box.origin.y, box.size.height)];
		}
	}
	
	// Now find largest range in each set:
	NSRange		hRange = [self rangeOfLargestIndex: hIndexes];
	NSRange		vRange = [self rangeOfLargestIndex: vIndexes];
	NSRect		expandedBox = [self frame];
	
	if( vRange.length > hRange.length )
	{
		expandedBox.origin.x = hRange.location;
		expandedBox.size.width = hRange.length;
	}
	else
	{
		expandedBox.origin.y = vRange.location;
		expandedBox.size.height = vRange.length;
	}
	expandedBox.origin.x = truncf(expandedBox.origin.x);
	expandedBox.origin.y = truncf(expandedBox.origin.y);
	expandedBox.size.width = truncf(expandedBox.size.width);
	expandedBox.size.height = truncf(expandedBox.size.height);
	
	if( tuckUnderSuperEdges )
	{
		NSRect		superBox = [[self superview] frame];
		if( expandedBox.origin.x == superBox.origin.x )
		{
			expandedBox.origin.x = superBox.origin.x -1;
			expandedBox.size.width += 1;
		}
		if( expandedBox.origin.y == superBox.origin.y )
		{
			expandedBox.origin.y = superBox.origin.y -1;
			expandedBox.size.height += 1;
		}
		if( NSMaxX(expandedBox) == NSMaxX(superBox) )
			expandedBox.size.width += 1;
		if( NSMaxY(expandedBox) == NSMaxY(superBox) )
			expandedBox.size.height += 1;
	}
	
	[self setFrame: expandedBox];
}

-(NSRange)	rangeOfLargestIndex: (NSIndexSet*)ids
{
	NSUInteger	currIdx = [ids firstIndex];
	NSRange		currRange = NSMakeRange( currIdx, 0 );
	NSRange		biggestRange = NSMakeRange(0,0);
	while( currIdx != NSNotFound )
	{
		if( currIdx == (currRange.location +currRange.length) )
			currRange.length++;
		else
		{
			if( biggestRange.length < currRange.length )
				biggestRange = currRange;
			currRange.location = currIdx;
			currRange.length = 1;
		}
		currIdx = [ids indexGreaterThanIndex: currIdx];
	}
	
	if( biggestRange.length < currRange.length )
		biggestRange = currRange;

	return biggestRange;
}

-(void)	drawRect: (NSRect)dirtyBox
{
	[[NSColor blueColor] set];
	NSFrameRectWithWidth( [self bounds], 1 );
}


@end
