//
//  UKWidthEqualizingContainer.h
//  UKInterface
//
//  Created by Uli Kusterer on 28.09.08.
//  Copyright 2008 The Void Software. All rights reserved.
//

/*
	This view takes the width of its largest subview and makes all others the
	same width, and thendistributes them one next to other inside itself. This
	is handy for making pretty button pairs, e.g. 'OK' and 'Cancel' in a window,
	that fit their localized text perfectly.
*/

#import <Cocoa/Cocoa.h>


@interface UKWidthEqualizingContainer : NSView
{
	CGFloat		marginAroundView;
	CGFloat		distanceBetweenViews;
}

@end
