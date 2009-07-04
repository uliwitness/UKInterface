//
//  UKInterface.m
//  UKInterface
//
//  Created by Uli Kusterer on 28.09.08.
//  Copyright 2008 The Void Software. All rights reserved.
//

#import "UKInterface.h"


NSRect		UKRectFromString( NSString* str )
{
	NSRect		theBox = NSZeroRect;
	NSArray*	parts = [str componentsSeparatedByString: @","];
	
	theBox.origin.x = [[parts objectAtIndex: 0] floatValue];
	theBox.origin.y = [[parts objectAtIndex: 1] floatValue];
	theBox.size.width = [[parts objectAtIndex: 2] floatValue];
	theBox.size.height = [[parts objectAtIndex: 3] floatValue];
	
	return theBox;
}


@implementation UKInterface

+(id)	interfaceNamed: (NSString*)filename
{
	return [[[UKInterface alloc] initWithName: filename] autorelease];
}

-(id)	initWithName: (NSString*)filename
{
	self = [self initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: filename ofType: @"uki"]];
	return self;
}

-(id)	initWithContentsOfFile: (NSString*)filename
{
	if(( self = [super init] ))
	{
		currentTagStack = [[NSMutableArray alloc] init];
		NSData*			xmlData = [NSData dataWithContentsOfFile: filename];
		NSXMLParser*	parser = [[[NSXMLParser alloc] initWithData: xmlData] autorelease];
		[parser setDelegate: self];
		[parser parse];
	}
	
	return self;
}


-(void)	dealloc
{
	[objectDescriptions release];
	objectDescriptions = nil;
	
	[currentTagStack release];
	currentTagStack = nil;

	[idToObjectMappings release];
	idToObjectMappings = nil;

	[connections release];
	connections = nil;
	
	[super dealloc];
}

-(void)	parser: (NSXMLParser *)parser didStartElement: (NSString *)elementName
			namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
			attributes: (NSDictionary *)attributeDict
{
	NSMutableDictionary*		currDict = [NSMutableDictionary dictionaryWithDictionary: attributeDict];
	[currDict setObject: elementName forKey: @"tag_kind"];
	
	if( !objectDescriptions )	// Topmost element?
		objectDescriptions = [currDict retain];		// Make this the root dictionary.
	else	// Otherwise, add it to the current dictionary, with its tag name as the key:
	{
		NSMutableDictionary*	containerDict = [currentTagStack lastObject];
		NSMutableArray*			objects = [containerDict objectForKey: @"sub_objects"];
		if( !objects )
			[containerDict setObject: [NSMutableArray arrayWithObject: currDict] forKey: @"sub_objects"];
		else
			[objects addObject: currDict];
	}
	
	[currentTagStack addObject: currDict];
}


-(void)	parser: (NSXMLParser *)parser didEndElement: (NSString *)elementName
			namespaceURI: (NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	[currentTagStack removeLastObject];
}

-(void)	parser: (NSXMLParser *)parser foundCharacters: (NSString *)string
{
	// Add the text to whatever is the current tag:
	NSMutableDictionary*	currDict = [currentTagStack lastObject];
	NSMutableString*		bodyText = [currDict objectForKey: @"tag_text"];
	if( !bodyText )
	{
		bodyText = [[string mutableCopy] autorelease];
		[currDict setObject: bodyText forKey: @"tag_text"];
	}
	else
		[bodyText appendString: string];
}


-(void)	loadWithOwner: (id)owner
{
	if( idToObjectMappings )
	{
		[idToObjectMappings release];
		idToObjectMappings = nil;
	}
	if( connections )
	{
		[connections release];
		connections = nil;
	}
	
	idToObjectMappings = [[NSMutableDictionary alloc] init];
	[idToObjectMappings setObject: owner forKey: @"owner"];
	connections = [[NSMutableArray alloc] init];
	
	// Load all top-level objects:
	NSArray*				objects = [objectDescriptions objectForKey: @"sub_objects"];
	NSEnumerator*			enny = [objects objectEnumerator];
	NSMutableDictionary*	currDict = nil;
	
	while(( currDict = [enny nextObject] ))
	{
		NSString*	tagKind = [currDict objectForKey: @"tag_kind"];
		if( [tagKind isEqualToString: @"menu"] )
		{
			[self loadMenu: currDict withOwner: owner];
		}
		else if( [tagKind isEqualToString: @"window"] )
		{
			[self loadWindow: currDict withOwner: owner];
		}
		else if( [tagKind isEqualToString: @"panel"] )
		{
			NSString*		theClass = [currDict objectForKey: @"class"];
			if( !theClass )
				[currDict setObject: @"NSPanel" forKey: @"class"];
			
			[self loadWindow: currDict withOwner: owner];
		}
		else if( [tagKind isEqualToString: @"connection"] )
		{
			[self rememberConnection: currDict];
		}
		else if( [tagKind isEqualToString: @"object"] )
		{
			[self loadObject: currDict withOwner: owner];
		}
	}
	
	// Actually establish all those connections:
	enny = [connections objectEnumerator];
	while(( currDict = [enny nextObject] ))
	{
		id			fromObj = [idToObjectMappings objectForKey: [currDict objectForKey: @"from"]];
		NSString*	fromFieldName = [currDict objectForKey: @"fromFieldName"];
		id			toObj = [idToObjectMappings objectForKey: [currDict objectForKey: @"to"]];
		NSString*	toFieldName = [currDict objectForKey: @"toFieldName"];
		
		if( [toFieldName length] > 0 )
			toObj = [toObj valueForKey: toFieldName];
		[fromObj setValue: toObj forKey: fromFieldName];
	}

	if( idToObjectMappings )
	{
		[idToObjectMappings release];
		idToObjectMappings = nil;
	}
	if( connections )
	{
		[connections release];
		connections = nil;
	}
}


-(id)	loadObject: (NSDictionary*)dict withOwner: (id)owner
{
	NSString*		cls = [dict objectForKey: @"class"];
	if( !cls )
		cls = @"NSObject";
	NSObject*		obj = [[[NSClassFromString(cls) alloc] init] autorelease];
	NSString*		theID = [dict objectForKey: @"id"];
	if( theID )
		[idToObjectMappings setObject: obj forKey: theID];
	NSString*	theOutlet = [dict objectForKey: @"outlet"];
	if( theOutlet )
		[owner setValue: obj forKey: theOutlet];
	
	return obj;
}


-(NSMenu*)	loadMenu: (NSDictionary*)dict withOwner: (id)owner
{
	NSMenu*		theMenu = [[[NSMenu alloc] initWithTitle: [dict objectForKey: @"title"]] autorelease];
	NSString*	theID = [dict objectForKey: @"id"];
	if( theID )
		[idToObjectMappings setObject: theMenu forKey: theID];
	NSString*	theOutlet = [dict objectForKey: @"outlet"];
	if( theOutlet )
		[owner setValue: theMenu forKey: theOutlet];
	
	NSArray*		objects = [dict objectForKey: @"sub_objects"];
	NSEnumerator*	enny = [objects objectEnumerator];
	NSDictionary*	currDict = nil;
	while(( currDict = [enny nextObject] ))
	{
		NSString*	tagKind = [currDict objectForKey: @"tag_kind"];
		if( [tagKind isEqualToString: @"item"] )
		{
			[theMenu addItem: [self loadMenuItem: currDict withOwner: owner]];
		}
		else if( [tagKind isEqualToString: @"separator"] )
		{
			[theMenu addItem: [NSMenuItem separatorItem]];
		}
		else if( [tagKind isEqualToString: @"connection"] )
		{
			[self rememberConnection: currDict];
		}
	}
	
	return theMenu;
}


-(NSAttributedString*) loadHTMLStyledText: (NSString*)originalHtmlString
{
	//int					txSize = [NSFont systemFontSize];
	NSString*			htmlString = originalHtmlString; //[NSString stringWithFormat: @"<span style=\"font-family: 'Lucida Grande'; font-size: %dpx;\">%@</font>", txSize, originalHtmlString];
	NSData*				htmlData = [htmlString dataUsingEncoding: NSUTF8StringEncoding];
	NSAttributedString*	astr = [[[NSAttributedString alloc] initWithHTML: htmlData documentAttributes: nil] autorelease];
	return astr;
}


-(NSMenuItem*)	loadMenuItem: (NSDictionary*)dict withOwner: (id)owner
{
	NSString*	tl = [dict objectForKey: @"title"];
	if( !tl )
		tl = @"";
	NSString*	sc = [dict objectForKey: @"shortcut"];
	if( !sc )
		sc = @"";
	NSString*	atl = [dict objectForKey: @"attributedtitle"];
	NSString*	tg = [dict objectForKey: @"tag"];
	NSMenuItem*	theItem = [[[NSMenuItem alloc] initWithTitle: tl
								action: NSSelectorFromString( [dict objectForKey: @"action"] )
								keyEquivalent: sc] autorelease];
	if( [[tg stringByTrimmingCharactersInSet: [NSCharacterSet decimalDigitCharacterSet]] length] != 0 && [tg length] == 4 )
	{
		UInt32		n = 0;
		[tg getBytes: &n maxLength: sizeof(n) usedLength: nil encoding: NSMacOSRomanStringEncoding options: 0 range: NSMakeRange(0,4) remainingRange: nil];
		n = NSSwapLittleIntToHost( n );
		[theItem setTag: n];
	}
	else
		[theItem setTag: [tg integerValue]];
	NSString*	theID = [dict objectForKey: @"id"];
	NSString*	theTarget = [dict objectForKey: @"target"];
	if( theTarget && !theID )
		theID = [NSString stringWithFormat: @"__dyn_%d__", ++dynamicIDSeed];
	if( theID )
		[idToObjectMappings setObject: theItem forKey: theID];
	NSString*	theOutlet = [dict objectForKey: @"outlet"];
	if( theOutlet )
		[owner setValue: theItem forKey: theOutlet];
	[connections addObject: [NSDictionary dictionaryWithObjectsAndKeys:
								theID, @"from",
								@"target", @"fromFieldName",
								theTarget, @"to",
							nil]];
	
	NSArray*		objects = [dict objectForKey: @"sub_objects"];
	NSEnumerator*	enny = [objects objectEnumerator];
	NSDictionary*	currDict = nil;
	while(( currDict = [enny nextObject] ))
	{
		NSString*	tagKind = [currDict objectForKey: @"tag_kind"];
		if( [tagKind isEqualToString: @"menu"] )
		{
			[theItem setSubmenu: [self loadMenu: currDict withOwner: owner]];
		}
		else if( [tagKind isEqualToString: @"connection"] )
		{
			[self rememberConnection: currDict];
		}
	}
	
	if( atl )
	{
		NSAttributedString*	astr = [self loadHTMLStyledText: atl];
		if( [theItem respondsToSelector: @selector(setAttributedTitle:)] )
			[theItem setAttributedTitle: astr];
	}

	
	return theItem;
}


-(void)	rememberConnection: (NSDictionary*)dict
{
	NSString*	fromName = [dict objectForKey: @"from"];
	NSString*	toName = [dict objectForKey: @"to"];
	NSArray*	cmps = nil;
	NSString*	fromFieldName = @"";
	NSString*	toFieldName = @"";
	cmps = [fromName componentsSeparatedByString: @"."];
	if( [cmps count] > 1 )
	{
		fromFieldName = [cmps objectAtIndex: 1];
		fromName = [cmps objectAtIndex: 0];
	}
	cmps = [toName componentsSeparatedByString: @"."];
	if( [cmps count] > 1 )
	{
		toFieldName = [cmps objectAtIndex: 1];
		toName = [cmps objectAtIndex: 0];
	}
	[connections addObject: [NSDictionary dictionaryWithObjectsAndKeys:
								fromName, @"from",
								fromFieldName, @"fromFieldName",
								toName, @"to",
								toFieldName, @"toFieldName",
							nil]];
}


-(NSDictionary*)	borderTypeMappings
{
	static NSDictionary*	sBorderTypes = nil;
	if( !sBorderTypes )
	{
		sBorderTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSNumber numberWithInteger: NSNoBorder], @"none",
			[NSNumber numberWithInteger: NSLineBorder], @"line",
			[NSNumber numberWithInteger: NSBezelBorder], @"bezel",
			[NSNumber numberWithInteger: NSGrooveBorder], @"groove",
			nil];
	}
	return sBorderTypes;
}


-(NSDictionary*)	levelNameMappings
{
	static NSDictionary*	sLevelNames = nil;
	if( !sLevelNames )
	{
		sLevelNames = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSNumber numberWithInteger: NSNormalWindowLevel], @"normal",
			[NSNumber numberWithInteger: NSFloatingWindowLevel], @"floating",
			[NSNumber numberWithInteger: NSSubmenuWindowLevel], @"submenu",
			[NSNumber numberWithInteger: NSTornOffMenuWindowLevel], @"tornoffmenu",
			[NSNumber numberWithInteger: NSMainMenuWindowLevel], @"mainmenu",
			[NSNumber numberWithInteger: NSStatusWindowLevel], @"status",
			[NSNumber numberWithInteger: NSDockWindowLevel], @"dock",
			[NSNumber numberWithInteger: NSModalPanelWindowLevel], @"modalpanel",
			[NSNumber numberWithInteger: NSPopUpMenuWindowLevel], @"popupmenu",
			[NSNumber numberWithInteger: NSScreenSaverWindowLevel], @"screensaver",
			nil];
	}
	return sLevelNames;
}


-(NSDictionary*)	tagToClassMappings
{
	static NSDictionary*	sTagToClassMappings = nil;
	if( !sTagToClassMappings )
	{
		sTagToClassMappings = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"NSButton", @"button",
			@"NSSlider", @"slider",
			@"NSTextField", @"textfield",
			@"NSTextView", @"textview",
			@"NSSecureTextField", @"securefield",
			@"NSSecureTextField", @"securetextfield",
			@"NSSecureTextField", @"passwordfield",
			@"NSSearchField", @"searchfield",
			@"NSTokenField", @"tokenfield",
			@"NSBox", @"box",
			@"NSImageView", @"imageview",
			@"NSImageWell", @"imagewell",
			@"NSDatePicker", @"datepicker",
			@"NSComboBox", @"combobox",
			@"NSStepper", @"stepper",
			@"NSPopUpButton", @"popupbutton",
			@"NSPopUpButton", @"popup",
			@"NSSegmentedControl", @"segmentedcontrol",
			@"NSColorWell", @"colorwell",
			@"NSPathControl", @"pathcontrol",
			@"NSProgressIndicator", @"progressindicator",
			@"NSLevelIndicator", @"levelindicator",
			@"NSSplitView", @"splitview",
			@"NSScrollView", @"scrollview",
			@"NSTableView", @"table",
			@"NSOutlineView", @"outline",
			@"QTMovieView", @"movieview",
			nil];
	}
	
	return sTagToClassMappings;
}


-(NSWindow*)	loadWindow: (NSDictionary*)dict withOwner: (id)owner
{
	NSString*	cls = [dict objectForKey: @"class"];
	if( !cls )
		cls = @"NSWindow";
	NSString*	tl = [dict objectForKey: @"title"];
	NSString*	bl = [dict objectForKey: @"borderless"];
	NSString*	cb = [dict objectForKey: @"closable"];
	if( !cb )
		cb = [dict objectForKey: @"closeable"];
	NSString*	mn = [dict objectForKey: @"miniaturizable"];
	NSString*	rs = [dict objectForKey: @"resizable"];
	if( !rs )
		rs = [dict objectForKey: @"resizeable"];
	NSString*	tx = [dict objectForKey: @"textured"];
	NSString*	vs = [dict objectForKey: @"visible"];
	NSString*	fl = [dict objectForKey: @"floating"];
	NSString*	hud = [dict objectForKey: @"hud"];
	NSString*	ut = [dict objectForKey: @"utility"];
	NSString*	dm = [dict objectForKey: @"docmodal"];
	if( !dm )
		dm = [dict objectForKey: @"sheet"];
	NSString*	na = [dict objectForKey: @"nonactivating"];
	NSString*	lv = [dict objectForKey: @"level"];
	NSString*	hod = [dict objectForKey: @"hidesondeactivate"];
	NSString*	bx = [dict objectForKey: @"frame"];
	NSRect		box = NSMakeRect( 100, 100, 512, 342 );
	if( bx )
		box = UKRectFromString( bx );
	NSString*	theID = [dict objectForKey: @"id"];
	NSString*	theDelegate = [dict objectForKey: @"delegate"];
	if( theDelegate && !theID )
		theID = [NSString stringWithFormat: @"__dyn_%d__", ++dynamicIDSeed];
	[connections addObject: [NSDictionary dictionaryWithObjectsAndKeys:
								theID, @"from",
								@"delegate", @"fromFieldName",
								theDelegate, @"to",
							nil]];

	NSUInteger	styleMask = 0;
	if( ![bl isEqualToString: @"yes"] )
		styleMask |= NSTitledWindowMask;
	if( ![cb isEqualToString: @"no"] )
		styleMask |= NSClosableWindowMask;
	if( ![mn isEqualToString: @"no"] )
		styleMask |= NSMiniaturizableWindowMask;
	if( [rs isEqualToString: @"yes"] )
		styleMask |= NSResizableWindowMask;
	if( [tx isEqualToString: @"yes"] )
		styleMask |= NSTexturedBackgroundWindowMask;
	if( [hud isEqualToString: @"yes"] )
		styleMask |= NSHUDWindowMask;
	if( [ut isEqualToString: @"yes"] )
		styleMask |= NSUtilityWindowMask;
	if( [dm isEqualToString: @"yes"] )
		styleMask |= NSDocModalWindowMask;
	if( [na isEqualToString: @"yes"] )
		styleMask |= NSNonactivatingPanelMask;
	
	NSWindow*	theWindow = [[[NSClassFromString( cls ) alloc] initWithContentRect: box
								styleMask: styleMask
								backing: NSBackingStoreBuffered defer: YES] autorelease];
	if( theID )
		[idToObjectMappings setObject: theWindow forKey: theID];
	if( tl )
		[theWindow setTitle: tl];
	if( [vs isEqualToString: @"yes"] )
		[theWindow makeKeyAndOrderFront: self];
	if( [fl isEqualToString: @"yes"] )
		[(NSPanel*)theWindow setFloatingPanel: YES];
	if( hod )
		[(NSPanel*)theWindow setHidesOnDeactivate: [hod isEqualToString: @"yes"]];
	if( lv )
	{
		NSNumber*	levelNumObj = [[self levelNameMappings] objectForKey: lv];
		if( levelNumObj )
			[(NSPanel*)theWindow setLevel: [levelNumObj integerValue]];
	}
	
	NSString*	theOutlet = [dict objectForKey: @"outlet"];
	if( theOutlet )
		[owner setValue: theWindow forKey: theOutlet];
	
	[self loadSubviews: [dict objectForKey: @"sub_objects"] intoView: [theWindow contentView] withOwner: owner];
		
	return theWindow;
}


-(void)	loadSubviews: (NSArray*)objects intoView: (NSView*)superView withOwner: (id)owner
{
	NSEnumerator*			enny = [objects objectEnumerator];
	NSMutableDictionary*	currDict = nil;
	while(( currDict = [enny nextObject] ))
	{
		NSString*	tagKind = [currDict objectForKey: @"tag_kind"];
		if( [tagKind isEqualToString: @"view"] )
		{
			NSView*	vw = [self loadView: currDict withSuperview: superView withOwner: owner];
			[superView addSubview: vw];
		}
		else if( [tagKind isEqualToString: @"connection"] )
		{
			[self rememberConnection: currDict];
		}
		else
		{
			NSString*	viewClassForTagKind = [[self tagToClassMappings] objectForKey: tagKind];
			NSString*	cls = [currDict objectForKey: @"class"];
			if( !cls )
				cls = viewClassForTagKind;
			if( cls )
			{
				[currDict setObject: cls forKey: @"class"];
				NSView*	vw = [self loadView: currDict withSuperview: superView withOwner: owner];
				[superView addSubview: vw];
			}
		} 
	}
}


-(NSView*)	loadView: (NSDictionary*)dict withSuperview: (NSView*)container withOwner: (id)owner
{
	NSString*	cls = [dict objectForKey: @"class"];
	if( !cls )
		cls = @"NSView";
	NSString*	ac = [dict objectForKey: @"action"];
	NSString*	theTarget = [dict objectForKey: @"target"];
	NSString*	sc = [dict objectForKey: @"shortcut"];
	NSString*	atl = [dict objectForKey: @"attributedtitle"];
	NSString*	hd = [dict objectForKey: @"hidden"];
	NSString*	scr = [dict objectForKey: @"scroller"];
	NSString*	sp = [dict objectForKey: @"sizing"];
	if( !sp )
		sp = @"tl";
	NSString*	bd = [dict objectForKey: @"border"];
	int			sizingFlags = NSViewNotSizable;
	if( [sp rangeOfString: @"r"].location != NSNotFound )
		sizingFlags |= NSViewMinXMargin;
	if( [sp rangeOfString: @"b"].location != NSNotFound )
		sizingFlags |= NSViewMaxYMargin;
	if( [sp rangeOfString: @"l"].location != NSNotFound )
		sizingFlags |= NSViewMaxXMargin;
	if( [sp rangeOfString: @"t"].location != NSNotFound )
		sizingFlags |= NSViewMinYMargin;
	if( [sp rangeOfString: @"w"].location != NSNotFound )
		sizingFlags |= NSViewWidthSizable;
	if( [sp rangeOfString: @"h"].location != NSNotFound )
		sizingFlags |= NSViewHeightSizable;
	NSString*	bx = [dict objectForKey: @"frame"];
	NSRect		box = [container bounds];
	if( bx )
		box = UKRectFromString( bx );
	NSView*		theView = [[NSClassFromString( cls ) alloc] initWithFrame: box];
	[theView setAutoresizingMask: sizingFlags];
	NSString*	theID = [dict objectForKey: @"id"];
	if( theTarget && !theID )
		theID = [NSString stringWithFormat: @"__dyn_%d__", ++dynamicIDSeed];
	if( theID )
		[idToObjectMappings setObject: theView forKey: theID];
	
	if( bd )
	{
		NSNumber*	n = [[self borderTypeMappings] objectForKey: bd];
		if( n )
			[(NSScrollView*)theView setBorderType: [n intValue]];
	}
	
	[self loadSubviews: [dict objectForKey: @"sub_objects"] intoView: theView withOwner: owner];
	
	NSString*	tl = [dict objectForKey: @"title"];
	if( tl )
	{
		if( [theView respondsToSelector: @selector(setTitle:)] )
			[(NSButton*)theView setTitle: tl];
		else if( [theView respondsToSelector: @selector(setString:)] )
			[(NSTextView*)theView setString: tl];
		else if( [theView respondsToSelector: @selector(setStringValue:)] )
			[(NSTextField*)theView setStringValue: tl];
	}
	if( hd )
		[theView setHidden: [hd isEqualToString: @"yes"]];
	if( scr )
	{
		if( [scr rangeOfString: @"h"].location != NSNotFound )
			[(NSScrollView*)theView setHasHorizontalScroller: YES];
		if( [scr rangeOfString: @"v"].location != NSNotFound )
			[(NSScrollView*)theView setHasVerticalScroller: YES];
	}
	
	if( ac && [theView respondsToSelector: @selector(setAction:)] )
		[(NSControl*)theView setAction: NSSelectorFromString(ac)];
	if( theTarget && [theView respondsToSelector: @selector(setTarget:)] )
		[connections addObject: [NSDictionary dictionaryWithObjectsAndKeys:
								theID, @"from",
								@"target", @"fromFieldName",
								theTarget, @"to",
							nil]];
	
	NSString*	theOutlet = [dict objectForKey: @"outlet"];
	if( theOutlet )
		[owner setValue: theView forKey: theOutlet];
	
	NSString*		tagKind = [dict objectForKey: @"tag_kind"];

	// Load objects inside this one's tag:
	//	right now those are only connections (which we allow everywhere) and
	//	a menu to set as this view's menu.
	NSArray*		objects = [dict objectForKey: @"sub_objects"];
	NSEnumerator*	enny = [objects objectEnumerator];
	NSDictionary*	currDict = nil;
	while(( currDict = [enny nextObject] ))
	{
		NSString*	tagKind = [currDict objectForKey: @"tag_kind"];
		if( [tagKind isEqualToString: @"menu"] )
		{
			[theView setMenu: [self loadMenu: currDict withOwner: owner]];
		}
		else if( [tagKind isEqualToString: @"connection"] )
		{
			[self rememberConnection: currDict];
		}
		else if( [tagKind isEqualToString: @"attributedtext"] )
		{
			NSAttributedString*	astr = [self loadHTMLStyledText: [currDict objectForKey: @"tag_text"]];
			if( [theView respondsToSelector: @selector(textStorage)] )
				[[(NSTextView*)theView textStorage] setAttributedString: astr];
		}
	}
	
	if( atl )
	{
		NSAttributedString*	astr = [self loadHTMLStyledText: atl];
		if( [theView respondsToSelector: @selector(setAttributedTitle:)] )
			[(NSButton*)theView setAttributedTitle: astr];
	}
	
	if( [tagKind isEqualToString: @"button"] )
	{
		[(NSButton*)theView setFont: [NSFont systemFontOfSize: [NSFont systemFontSize]]];
		[(NSButton*)theView setBezelStyle: NSRoundedBezelStyle];
		if( !bx )
		{
			[(NSButton*)theView sizeToFit];
			NSSize	sz = [theView frame].size;
			sz.width += 20;
			[theView setFrameSize: sz];
		}
		
		if( sc )
		{
			if( [sc isEqualToString: @"\\r"] || [sc isEqualToString: @"\\n"]
				|| [sc isEqualToString: @"return"] || [sc isEqualToString: @"enter"] )
				sc = @"\r";
			else if( [sc isEqualToString: @"Cmd-."] || [sc isEqualToString: @"\\033"]
				|| [sc isEqualToString: @"esc"] || [sc isEqualToString: @"escape"] )
				sc = @"\033";
				
			[(NSButton*)theView setKeyEquivalent: sc];
		}
	}
	else if( !bx && [theView respondsToSelector: @selector(sizeToFit)] )
		[(NSControl*)theView sizeToFit];
	
	return theView;
}


@end
