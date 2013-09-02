//
//  PBGitRevisionCell.m
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRevisionCell.h"
#import "PBGitRef.h"
#import "RoundedRectangle.h"
#import "GitXTextFieldCell.h"

#import "NSColor+RGB.h"

const int COLUMN_WIDTH = 10;

@implementation PBGitRevisionCell


- (id) initWithCoder: (id) coder
{
	self = [super initWithCoder:coder];
	textCell = [[GitXTextFieldCell alloc] initWithCoder:coder];
	return self;
}

+ (NSArray *)laneColors
{
	static NSArray *laneColors = nil;
	if (!laneColors) {
		laneColors = @[
	 [NSColor colorWithR:181 G:137 B:0], // Solarized yellow
	 [NSColor colorWithR:203 G:75 B:22], // Solarized orange
	 [NSColor colorWithR:220 G:50 B:47], // Solarized red
	 [NSColor colorWithR:211 G:54 B:130], // Solarized magenta
	 [NSColor colorWithR:108 G:113 B:196], // Solarized violet
	 [NSColor colorWithR:38 G:139 B:210], // Solarized blue
	 [NSColor colorWithR:42 G:161 B:152], // Solarized cyan
	 [NSColor colorWithR:133 G:153 B:0], // Solarized green
	 ];

		NSMutableArray *oddColors = [NSMutableArray new];
		NSMutableArray *evenColors = [NSMutableArray new];

		for (NSUInteger i = 0; i < laneColors.count; ++i) {
			if (i % 2) {
				[oddColors addObject:laneColors[i]];
			} else {
				[evenColors addObject:laneColors[i]];
			}
		}

		laneColors = [evenColors arrayByAddingObjectsFromArray:oddColors];

	}

	return laneColors;
}

- (void) drawLineFromColumn: (int) from toColumn: (int) to inRect: (NSRect) r offset: (int) offset color: (int) c
{
	NSPoint origin = r.origin;
	
	NSPoint source = NSMakePoint(origin.x + COLUMN_WIDTH * from, origin.y + offset);
	NSPoint center = NSMakePoint( origin.x + COLUMN_WIDTH * to, origin.y + r.size.height * 0.5 + 0.5);

	NSShadow *shadow = nil;
	if (true)
	{
		[NSGraphicsContext saveGraphicsState];
		uint8_t l = 0x26;
		NSColor *shadowColor = [NSColor colorWithR:l G:l B:l];

		shadow = [NSShadow new];
		[shadow setShadowColor:shadowColor];
		[shadow setShadowOffset:NSMakeSize(1.0f, -1.f)];
		[shadow set];
	}
	NSArray* colors = [PBGitRevisionCell laneColors];
	[(NSColor*)[colors objectAtIndex: (c % [colors count])] set];
	
	NSBezierPath * path = [NSBezierPath bezierPath];
	[path setLineWidth:2];
	
	[path moveToPoint: source];
	[path lineToPoint: center];
	[path stroke];

	if (shadow) {
		[NSGraphicsContext restoreGraphicsState];
	}
}

- (BOOL) isCurrentCommit
{
	PBGitSHA *thisSha = [self.objectValue sha];

	PBGitRepository* repository = [self.objectValue repository];
	PBGitSHA *currentSha = [repository headSHA];

	return [currentSha isEqual:thisSha];
}

- (void) drawCircleInRect: (NSRect) r
{

	int c = cellInfo.position;
	NSPoint origin = r.origin;
	NSPoint columnOrigin = { origin.x + COLUMN_WIDTH * c, origin.y};

	NSRect oval = { columnOrigin.x - 5, columnOrigin.y + r.size.height * 0.5 - 5, 10, 10};

	
	NSBezierPath * path = [NSBezierPath bezierPathWithOvalInRect:oval];

	[[NSColor blackColor] set];
	[path fill];
	
	NSRect smallOval = { columnOrigin.x - 3, columnOrigin.y + r.size.height * 0.5 - 3, 6, 6};

	if ( [self isCurrentCommit ] ) {
		[[NSColor colorWithCalibratedRed: 0Xfc/256.0 green:0Xa6/256.0 blue: 0X4f/256.0 alpha: 1.0] set];
	} else {
		[[NSColor whiteColor] set];
	}

	path = [NSBezierPath bezierPathWithOvalInRect:smallOval];
	[path fill];	
}

- (void) drawTriangleInRect: (NSRect) r sign: (char) sign
{
	int c = cellInfo.position;
	int columnHeight = 10;
	int columnWidth = 8;

	NSPoint top;
	if (sign == '<')
		top.x = round(r.origin.x) + 10 * c + 4;
	else {
		top.x = round(r.origin.x) + 10 * c - 4;
		columnWidth *= -1;
	}
	top.y = r.origin.y + (r.size.height - columnHeight) / 2;

	NSBezierPath * path = [NSBezierPath bezierPath];
	// Start at top
	[path moveToPoint: NSMakePoint(top.x, top.y)];
	// Go down
	[path lineToPoint: NSMakePoint(top.x, top.y + columnHeight)];
	// Go left top
	[path lineToPoint: NSMakePoint(top.x - columnWidth, top.y + columnHeight / 2)];
	// Go to top again
	[path closePath];

	[[NSColor whiteColor] set];
	[path fill];
	[[NSColor blackColor] set];
	[path setLineWidth: 2];
	[path stroke];
}

- (NSMutableDictionary*) attributesForRefLabelSelected: (BOOL) selected
{
	NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:2];
	NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	
	[style setAlignment:NSCenterTextAlignment];
	[attributes setObject:style forKey:NSParagraphStyleAttributeName];
	[attributes setObject:[NSFont fontWithName:@"Helvetica" size:9] forKey:NSFontAttributeName];

	//if (selected)
	//	[attributes setObject:[NSColor alternateSelectedControlTextColor] forKey:NSForegroundColorAttributeName];

	return attributes;
}

- (NSColor*) colorForRef: (PBGitRef*) ref
{
	BOOL isHEAD = [ref.ref isEqualToString:[[[controller repository] headRef] simpleRef]];

	if (isHEAD)
		return [NSColor colorWithCalibratedRed: 0Xfc/256.0 green:0Xa6/256.0 blue: 0X4f/256.0 alpha: 1.0];

	NSString* type = [ref type];
	if ([type isEqualToString:@"head"])
		return [NSColor colorWithCalibratedRed: 0Xaa/256.0 green:0Xf2/256.0 blue: 0X54/256.0 alpha: 1.0];
	else if ([type isEqualToString:@"remote"])
		return [NSColor colorWithCalibratedRed: 0xb2/256.0 green:0Xdf/256.0 blue: 0Xff/256.0 alpha: 1.0];
	else if ([type isEqualToString:@"tag"])
		return [NSColor colorWithCalibratedRed: 0Xfc/256.0 green:0Xed/256.0 blue: 0X4f/256.0 alpha: 1.0];
	
	return [NSColor yellowColor];
}

-(NSArray *)rectsForRefsinRect:(NSRect) rect;
{
	NSMutableArray *array = [NSMutableArray array];
	
	static const int ref_padding = 10;
	static const int ref_spacing = 2;
	
	NSRect lastRect = rect;
	lastRect.origin.x = round(lastRect.origin.x) + 0.5;
	lastRect.origin.y = round(lastRect.origin.y) + 0.5;
	
	for (PBGitRef *ref in self.objectValue.refs) {
		NSMutableDictionary* attributes = [self attributesForRefLabelSelected:NO];
		NSSize textSize = [[ref shortName] sizeWithAttributes:attributes];
		
		NSRect newRect = lastRect;
		newRect.size.width = textSize.width + ref_padding;
		newRect.size.height = textSize.height;
		newRect.origin.y = rect.origin.y + (rect.size.height - newRect.size.height) / 2;
		
		if (NSContainsRect(rect, newRect)) {
			[array addObject:[NSValue valueWithRect:newRect]];
			lastRect = newRect;
			lastRect.origin.x += (int)lastRect.size.width + ref_spacing;
		}
	}
	
	return array;
}

- (void) drawLabelAtIndex:(int)index inRect:(NSRect)rect
{
	NSArray *refs = self.objectValue.refs;
	PBGitRef *ref = [refs objectAtIndex:index];
	
	NSMutableDictionary* attributes = [self attributesForRefLabelSelected:[self isHighlighted]];
	NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:rect cornerRadius: 2.0];
	[[self colorForRef:ref] set];
	[border fill];
	
	[[ref shortName] drawInRect:rect withAttributes:attributes];
	[border stroke];	
}

- (void) drawRefsInRect: (NSRect *)refRect
{
	[[NSColor blackColor] setStroke];

	NSRect lastRect = NSMakeRect(0, 0, 0, 0);
	int index = 0;
	for (NSValue *rectValue in [self rectsForRefsinRect:*refRect])
	{
		NSRect rect = [rectValue rectValue];
		[self drawLabelAtIndex:index inRect:rect];
		lastRect = rect;
		++index;
	}

    // Only update rect to account for drawn refs if necessary to push
    // subsequent content to the right.
    if (index > 0) {
        refRect->size.width -= lastRect.origin.x - refRect->origin.x + lastRect.size.width;
        refRect->origin.x    = lastRect.origin.x + lastRect.size.width;
    }
}

- (void) drawWithFrame: (NSRect) rect inView:(NSView *)view
{
	cellInfo = [self.objectValue lineInfo];
	
	if (cellInfo && ![controller hasNonlinearPath]) {
		float pathWidth = 10 + COLUMN_WIDTH * cellInfo.numColumns;

		NSRect ownRect;
		NSDivideRect(rect, &ownRect, &rect, pathWidth, NSMinXEdge);

		int i;
		struct PBGitGraphLine *lines = cellInfo.lines;
		for (i = 0; i < cellInfo.nLines; i++) {
			if (lines[i].upper == 0)
				[self drawLineFromColumn: lines[i].from toColumn: lines[i].to inRect:ownRect offset: ownRect.size.height color: lines[i].colorIndex];
			else
				[self drawLineFromColumn: lines[i].from toColumn: lines[i].to inRect:ownRect offset: 0 color:lines[i].colorIndex];
		}

		if (cellInfo.sign == '<' || cellInfo.sign == '>')
			[self drawTriangleInRect: ownRect sign: cellInfo.sign];
		else
			[self drawCircleInRect: ownRect];
	}


	if ([self.objectValue refs] && [[self.objectValue refs] count])
		[self drawRefsInRect:&rect];

	// Still use this superclass because of hilighting differences
	//_contents = [self.objectValue subject];
	//[super drawWithFrame:rect inView:view];
	[textCell setObjectValue: [self.objectValue subject]];
	[textCell setHighlighted: [self isHighlighted]];
	[textCell drawWithFrame:rect inView: view];
}

- (void) setObjectValue: (PBGitCommit*)object {
	[super setObjectValue:[NSValue valueWithNonretainedObject:object]];
}

- (PBGitCommit*) objectValue {
    return [[super objectValue] nonretainedObjectValue];
}

- (int) indexAtX:(float)x
{
	cellInfo = [self.objectValue lineInfo];
	float pathWidth = 0;
	if (cellInfo && ![controller hasNonlinearPath])
		pathWidth = 10 + 10 * cellInfo.numColumns;

	int index = 0;
	NSRect refRect = NSMakeRect(pathWidth, 0, 1000, 10000);
	for (NSValue *rectValue in [self rectsForRefsinRect:refRect])
	{
		NSRect rect = [rectValue rectValue];
		if (x >= rect.origin.x && x <= (rect.origin.x + rect.size.width))
			return index;
		++index;
	}

	return -1;
}

- (NSRect) rectAtIndex:(int)index
{
	cellInfo = [self.objectValue lineInfo];
	float pathWidth = 0;
	if (cellInfo && ![controller hasNonlinearPath])
		pathWidth = 10 + 10 * cellInfo.numColumns;
	NSRect refRect = NSMakeRect(pathWidth, 0, 1000, 10000);

	return [[[self rectsForRefsinRect:refRect] objectAtIndex:index] rectValue];
}

# pragma mark context menu delegate methods

- (NSMenu *) menuForEvent:(NSEvent *)event inRect:(NSRect)rect ofView:(NSView *)view
{
	if (!contextMenuDelegate)
		return [self menu];

	int i = [self indexAtX:[view convertPoint:[event locationInWindow] fromView:nil].x - rect.origin.x];

	id ref = nil;
	if (i >= 0)
		ref = [[[self objectValue] refs] objectAtIndex:i];

	NSArray *items = nil;
	if (ref)
		items = [contextMenuDelegate menuItemsForRef:ref];
	else
		items = [contextMenuDelegate menuItemsForCommit:[self objectValue]];

	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	for (NSMenuItem *item in items)
		[menu addItem:item];
	return menu;
}
@end
