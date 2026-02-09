//
//  PSMTabBarControlGroupTest.m
//  iTerm2
//
//  Tests for PSMTabBarControl group layout integration.
//

#import <XCTest/XCTest.h>
#import "PSMTabBarControl.h"
#import "PSMTabBarCell.h"
#import "PSMTabGroup.h"
#import "PSMTabGroupHeaderCell.h"

// Minimal mock identifier that responds to stringUniqueIdentifier
@interface PSMTestTabIdentifier : NSObject
@property (nonatomic, copy) NSString *stringUniqueIdentifier;
@end

@implementation PSMTestTabIdentifier
- (void)dealloc {
    [_stringUniqueIdentifier release];
    [super dealloc];
}
@end

// Expose private methods for testing
@interface PSMTabBarControl (Testing)
- (NSMutableArray *)cells;
- (void)update:(BOOL)animate;
- (void)addTabViewItem:(NSTabViewItem *)item;
@end

@interface PSMTabBarControlGroupTest : XCTestCase
@end

@implementation PSMTabBarControlGroupTest

- (PSMTabBarControl *)makeVerticalTabBar {
    PSMTabBarControl *tabBar = [[[PSMTabBarControl alloc] initWithFrame:NSMakeRect(0, 0, 200, 600)] autorelease];
    tabBar.orientation = PSMTabBarVerticalOrientation;
    return tabBar;
}

/// Create a vertical tab bar wired to an NSTabView with the given number of tabs.
/// Each tab view item gets a PSMTestTabIdentifier with stringUniqueIdentifier "guid-0", "guid-1", etc.
- (PSMTabBarControl *)makeVerticalTabBarWithTabCount:(int)count {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];

    NSTabView *tabView = [[[NSTabView alloc] initWithFrame:NSMakeRect(0, 0, 200, 600)] autorelease];
    tabView.delegate = (id)tabBar;
    tabBar.tabView = tabView;

    for (int i = 0; i < count; i++) {
        PSMTestTabIdentifier *ident = [[[PSMTestTabIdentifier alloc] init] autorelease];
        ident.stringUniqueIdentifier = [NSString stringWithFormat:@"guid-%d", i];
        NSTabViewItem *item = [[[NSTabViewItem alloc] initWithIdentifier:ident] autorelease];
        item.label = [NSString stringWithFormat:@"Tab %d", i];
        [tabView addTabViewItem:item];
        [tabBar addTabViewItem:item];
    }

    return tabBar;
}

#pragma mark - Group Addition and Lookup

- (void)testAddTabGroup {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"Group 1" tabGUIDs:@[@"guid-a", @"guid-b"]] autorelease];

    [tabBar addTabGroup:group];

    XCTAssertEqual(tabBar.tabGroups.count, 1u);
    XCTAssertEqualObjects([tabBar groupForTabGUID:@"guid-a"], group);
    XCTAssertEqualObjects([tabBar groupForTabGUID:@"guid-b"], group);
}

- (void)testGroupForUnknownGUID {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];
    XCTAssertNil([tabBar groupForTabGUID:@"nonexistent"]);
    XCTAssertNil([tabBar groupForTabGUID:nil]);
}

- (void)testRemoveTabGroup {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G" tabGUIDs:@[@"guid-a"]] autorelease];
    [tabBar addTabGroup:group];
    XCTAssertEqual(tabBar.tabGroups.count, 1u);

    [tabBar removeTabGroup:group];
    XCTAssertEqual(tabBar.tabGroups.count, 0u);
    XCTAssertNil([tabBar groupForTabGUID:@"guid-a"]);
}

- (void)testToggleGroupCollapsed {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G" tabGUIDs:@[@"guid-a"]] autorelease];
    [tabBar addTabGroup:group];

    XCTAssertFalse(group.collapsed);
    [tabBar toggleGroupCollapsed:group];
    XCTAssertTrue(group.collapsed);
    [tabBar toggleGroupCollapsed:group];
    XCTAssertFalse(group.collapsed);
}

#pragma mark - GUID-to-Group Cache Consistency

- (void)testCacheConsistencyAfterAddRemove {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];

    PSMTabGroup *g1 = [[[PSMTabGroup alloc] initWithTitle:@"G1" tabGUIDs:@[@"a", @"b"]] autorelease];
    PSMTabGroup *g2 = [[[PSMTabGroup alloc] initWithTitle:@"G2" tabGUIDs:@[@"c", @"d"]] autorelease];

    [tabBar addTabGroup:g1];
    [tabBar addTabGroup:g2];

    XCTAssertEqualObjects([tabBar groupForTabGUID:@"a"], g1);
    XCTAssertEqualObjects([tabBar groupForTabGUID:@"c"], g2);

    [tabBar removeTabGroup:g1];
    XCTAssertNil([tabBar groupForTabGUID:@"a"]);
    XCTAssertNil([tabBar groupForTabGUID:@"b"]);
    XCTAssertEqualObjects([tabBar groupForTabGUID:@"c"], g2);
}

#pragma mark - Multiple Groups

- (void)testMultipleGroups {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];
    PSMTabGroup *g1 = [[[PSMTabGroup alloc] initWithTitle:@"G1" tabGUIDs:@[@"a", @"b"]] autorelease];
    PSMTabGroup *g2 = [[[PSMTabGroup alloc] initWithTitle:@"G2" tabGUIDs:@[@"c", @"d"]] autorelease];

    [tabBar addTabGroup:g1];
    [tabBar addTabGroup:g2];

    XCTAssertEqual(tabBar.tabGroups.count, 2u);
    XCTAssertEqualObjects([tabBar groupForTabGUID:@"a"], g1);
    XCTAssertEqualObjects([tabBar groupForTabGUID:@"d"], g2);
}

#pragma mark - Prune Empty Groups

- (void)testPruneEmptyGroups {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G" tabGUIDs:@[@"a"]] autorelease];
    [tabBar addTabGroup:group];

    // Group has only 1 member, should be pruned
    [tabBar pruneEmptyGroups];
    XCTAssertEqual(tabBar.tabGroups.count, 0u);
}

- (void)testPruneKeepsGroupsWithTwoOrMore {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G" tabGUIDs:@[@"a", @"b"]] autorelease];
    [tabBar addTabGroup:group];

    [tabBar pruneEmptyGroups];
    XCTAssertEqual(tabBar.tabGroups.count, 1u);
}

#pragma mark - Selection for Grouping

- (void)testCellsSelectedForGrouping {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];

    // Create cells manually for testing
    PSMTabBarCell *cell1 = [[[PSMTabBarCell alloc] initWithControlView:tabBar] autorelease];
    PSMTabBarCell *cell2 = [[[PSMTabBarCell alloc] initWithControlView:tabBar] autorelease];
    PSMTabBarCell *cell3 = [[[PSMTabBarCell alloc] initWithControlView:tabBar] autorelease];

    cell1.selectedForGrouping = YES;
    cell3.selectedForGrouping = YES;

    // Note: we can't easily add cells to the control in a test without
    // a full tab view setup. The method will return empty since _cells is empty.
    // This test primarily validates the property works.
    XCTAssertTrue(cell1.selectedForGrouping);
    XCTAssertFalse(cell2.selectedForGrouping);
    XCTAssertTrue(cell3.selectedForGrouping);
}

- (void)testClearGroupingSelection {
    PSMTabBarControl *tabBar = [self makeVerticalTabBar];
    // Just verify it doesn't crash on empty state
    [tabBar clearGroupingSelection];
}

#pragma mark - Collapsed Group Layout Regression

// Regression test: collapsing a group must not corrupt the shared cellRect
// used for laying out subsequent tabs. Previously, _setupCells: assigned
// NSZeroRect to cellRect for collapsed members, which zeroed size.height.
// The next visible cell would then get a frame with height 0.
- (void)testCollapsedGroupDoesNotZeroHeightOfFollowingCell {
    PSMTabBarControl *tabBar = [self makeVerticalTabBarWithTabCount:5];
    NSArray *cells = [tabBar cells];
    XCTAssertEqual(cells.count, 5u);

    // Group the first 3 tabs (guid-0, guid-1, guid-2)
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"TestGroup"
                                                    tabGUIDs:@[@"guid-0", @"guid-1", @"guid-2"]] autorelease];
    [tabBar addTabGroup:group];

    // Layout with group expanded - all cells should have non-zero height
    [tabBar update:NO];
    for (int i = 0; i < 5; i++) {
        PSMTabBarCell *cell = cells[i];
        XCTAssertGreaterThan(NSHeight([cell frame]), 0,
                             @"Expanded: cell %d should have non-zero height", i);
    }

    // Collapse the group
    group.collapsed = YES;
    [tabBar update:NO];

    // Collapsed members (0, 1, 2) should be hidden (zero frame)
    for (int i = 0; i < 3; i++) {
        PSMTabBarCell *cell = cells[i];
        XCTAssertTrue(NSIsEmptyRect([cell frame]),
                      @"Collapsed member cell %d should have empty frame", i);
    }

    // Cells AFTER the group (3, 4) must retain full height — this is the regression.
    for (int i = 3; i < 5; i++) {
        PSMTabBarCell *cell = cells[i];
        XCTAssertGreaterThan(NSHeight([cell frame]), 0,
                             @"Cell %d after collapsed group must have non-zero height", i);
        XCTAssertGreaterThan(NSWidth([cell frame]), 0,
                             @"Cell %d after collapsed group must have non-zero width", i);
    }
}

// Verify that cells after a collapsed group are positioned correctly
// (not overlapping with the group header).
- (void)testCollapsedGroupCellsPositionedAfterHeader {
    PSMTabBarControl *tabBar = [self makeVerticalTabBarWithTabCount:4];
    NSArray *cells = [tabBar cells];

    // Group the first 2 tabs
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G"
                                                    tabGUIDs:@[@"guid-0", @"guid-1"]] autorelease];
    [tabBar addTabGroup:group];
    group.collapsed = YES;
    [tabBar update:NO];

    // The group header should exist
    XCTAssertEqual(tabBar.groupHeaderCells.count, 1u);
    NSRect headerFrame = [tabBar.groupHeaderCells[0] frame];
    XCTAssertGreaterThan(NSHeight(headerFrame), 0);

    // Cell after the collapsed group must start at or below the header bottom
    PSMTabBarCell *firstAfter = cells[2];
    XCTAssertGreaterThanOrEqual(NSMinY([firstAfter frame]), NSMaxY(headerFrame),
                                @"First cell after collapsed group must not overlap the group header");
}

// Verify that expanding after collapsing restores all cell heights.
- (void)testExpandAfterCollapseRestoresHeights {
    PSMTabBarControl *tabBar = [self makeVerticalTabBarWithTabCount:5];
    NSArray *cells = [tabBar cells];

    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G"
                                                    tabGUIDs:@[@"guid-0", @"guid-1", @"guid-2"]] autorelease];
    [tabBar addTabGroup:group];

    // Collapse then expand
    group.collapsed = YES;
    [tabBar update:NO];
    group.collapsed = NO;
    [tabBar update:NO];

    // All cells should have non-zero height after re-expanding
    for (int i = 0; i < 5; i++) {
        PSMTabBarCell *cell = cells[i];
        XCTAssertGreaterThan(NSHeight([cell frame]), 0,
                             @"After re-expanding, cell %d should have non-zero height", i);
    }
}

@end
