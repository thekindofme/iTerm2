//
//  PSMTabGroupHeaderCell.h
//  PSMTabBarControl
//
//  Renders a group header row in the vertical tab bar: disclosure triangle,
//  bold title, and optional member count badge when collapsed.
//

#import <Cocoa/Cocoa.h>

@class PSMTabGroup;

@interface PSMTabGroupHeaderCell : NSActionCell

@property (nonatomic, retain) PSMTabGroup *group;
@property (nonatomic, assign) NSRect frame;

- (instancetype)initWithGroup:(PSMTabGroup *)group;

// Returns the rect for the disclosure triangle within the given cell frame.
- (NSRect)disclosureRectForFrame:(NSRect)cellFrame;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

@end
