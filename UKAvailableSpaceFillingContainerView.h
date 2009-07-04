//
//  UKAvailableSpaceFillingContainerView.h
//  UKInterface
//
//  Created by Uli Kusterer on 28.09.08.
//  Copyright 2008 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UKAvailableSpaceFillingContainerView : NSView
{
	BOOL		tuckUnderSuperEdges;
}

@property (assign) BOOL		tuckUnderSuperEdges;

-(NSRange)	rangeOfLargestIndex: (NSIndexSet*)ids;

@end
