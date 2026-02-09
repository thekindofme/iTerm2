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

@interface PSMTabBarControlGroupTest : XCTestCase
@end

@implementation PSMTabBarControlGroupTest

- (PSMTabBarControl *)makeVerticalTabBar {
    PSMTabBarControl *tabBar = [[[PSMTabBarControl alloc] initWithFrame:NSMakeRect(0, 0, 200, 600)] autorelease];
    tabBar.orientation = PSMTabBarVerticalOrientation;
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

@end
