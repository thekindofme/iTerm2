//
//  PSMTabGroupHeaderCell.m
//  PSMTabBarControl
//

#import "PSMTabGroupHeaderCell.h"
#import "PSMTabGroup.h"

static const CGFloat kDisclosureSize = 12.0;
static const CGFloat kDisclosureLeftMargin = 6.0;
static const CGFloat kTitleLeftMargin = 4.0;
static const CGFloat kBadgeRightMargin = 8.0;

@implementation PSMTabGroupHeaderCell

- (instancetype)initWithGroup:(PSMTabGroup *)group {
    self = [super init];
    if (self) {
        _group = group;
        _frame = NSZeroRect;
    }
    return self;
}

- (NSRect)disclosureRectForFrame:(NSRect)cellFrame {
    CGFloat y = NSMidY(cellFrame) - kDisclosureSize / 2.0;
    return NSMakeRect(NSMinX(cellFrame) + kDisclosureLeftMargin, y, kDisclosureSize, kDisclosureSize);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    // Draw background
    NSColor *bgColor;
    if (@available(macOS 10.14, *)) {
        bgColor = [NSColor controlBackgroundColor];
    } else {
        bgColor = [NSColor colorWithCalibratedWhite:0.92 alpha:1.0];
    }
    [bgColor set];
    NSRectFill(cellFrame);

    // Draw a subtle separator line at bottom
    NSColor *separatorColor;
    if (@available(macOS 10.14, *)) {
        separatorColor = [NSColor separatorColor];
    } else {
        separatorColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
    }
    [separatorColor set];
    NSRect separatorRect = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame) - 1, NSWidth(cellFrame), 1);
    NSRectFill(separatorRect);

    // Draw disclosure triangle
    NSRect disclosureRect = [self disclosureRectForFrame:cellFrame];
    NSImage *disclosureImage;
    if (_group.collapsed) {
        disclosureImage = [NSImage imageWithSystemSymbolName:@"chevron.right"
                                   accessibilityDescription:@"collapsed"];
    } else {
        disclosureImage = [NSImage imageWithSystemSymbolName:@"chevron.down"
                                   accessibilityDescription:@"expanded"];
    }

    if (disclosureImage) {
        [disclosureImage drawInRect:disclosureRect
                           fromRect:NSZeroRect
                          operation:NSCompositingOperationSourceOver
                           fraction:0.6
                     respectFlipped:YES
                              hints:nil];
    }

    // Draw title
    NSString *title = _group.title ?: @"Group";
    CGFloat titleX = NSMaxX(disclosureRect) + kTitleLeftMargin;
    CGFloat maxTitleWidth = NSMaxX(cellFrame) - titleX - kBadgeRightMargin;

    if (_group.collapsed) {
        // Reserve space for count badge
        NSString *countStr = [NSString stringWithFormat:@"(%lu)", (unsigned long)_group.tabGUIDs.count];
        NSDictionary *countAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:11],
            NSForegroundColorAttributeName: [NSColor secondaryLabelColor]
        };
        NSSize countSize = [countStr sizeWithAttributes:countAttrs];
        maxTitleWidth -= countSize.width + 4;

        // Draw count badge
        CGFloat countX = NSMaxX(cellFrame) - kBadgeRightMargin - countSize.width;
        CGFloat countY = NSMidY(cellFrame) - countSize.height / 2.0;
        [countStr drawAtPoint:NSMakePoint(countX, countY) withAttributes:countAttrs];
    }

    NSDictionary *titleAttrs = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:11],
        NSForegroundColorAttributeName: [NSColor labelColor]
    };
    NSSize titleSize = [title sizeWithAttributes:titleAttrs];
    CGFloat titleY = NSMidY(cellFrame) - titleSize.height / 2.0;

    NSRect titleRect = NSMakeRect(titleX, titleY, MIN(titleSize.width, maxTitleWidth), titleSize.height);
    [title drawInRect:titleRect withAttributes:titleAttrs];
}

@end
