//
//  PSMTabGroupArrangementTest.m
//  iTerm2
//
//  Tests for tab group arrangement persistence.
//

#import <XCTest/XCTest.h>
#import "PSMTabGroup.h"
#import "PSMTabBarControl.h"

@interface PSMTabGroupArrangementTest : XCTestCase
@end

@implementation PSMTabGroupArrangementTest

#pragma mark - Encode Groups

- (void)testEncodeGroups {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"Work Tabs"
                                                    tabGUIDs:@[@"guid1", @"guid2", @"guid3"]] autorelease];
    group.collapsed = YES;

    NSDictionary *dict = [group arrangementRepresentation];

    XCTAssertNotNil(dict[@"identifier"]);
    XCTAssertEqualObjects(dict[@"title"], @"Work Tabs");
    XCTAssertEqualObjects(dict[@"collapsed"], @YES);
    XCTAssertEqualObjects(dict[@"tabGUIDs"], (@[@"guid1", @"guid2", @"guid3"]));
}

#pragma mark - Decode Groups

- (void)testDecodeGroups {
    NSDictionary *dict = @{
        @"identifier": @"test-id-123",
        @"title": @"Development",
        @"collapsed": @NO,
        @"tabGUIDs": @[@"tab-a", @"tab-b"]
    };

    PSMTabGroup *group = [PSMTabGroup groupFromArrangement:dict];

    XCTAssertNotNil(group);
    XCTAssertEqualObjects(group.identifier, @"test-id-123");
    XCTAssertEqualObjects(group.title, @"Development");
    XCTAssertFalse(group.collapsed);
    XCTAssertEqual(group.tabGUIDs.count, 2u);
    XCTAssertEqualObjects(group.tabGUIDs[0], @"tab-a");
    XCTAssertEqualObjects(group.tabGUIDs[1], @"tab-b");
}

#pragma mark - Empty Groups Array

- (void)testEmptyGroupsArrayProducesEmptyResult {
    PSMTabBarControl *tabBar = [[[PSMTabBarControl alloc] initWithFrame:NSMakeRect(0, 0, 200, 600)] autorelease];

    // No groups added
    NSArray<PSMTabGroup *> *groups = tabBar.tabGroups;
    XCTAssertEqual(groups.count, 0u);
}

#pragma mark - Unknown Keys Ignored

- (void)testUnknownKeysIgnored {
    NSDictionary *dict = @{
        @"identifier": @"id-1",
        @"title": @"Test",
        @"collapsed": @YES,
        @"tabGUIDs": @[@"x"],
        @"futureFeature": @YES,
        @"anotherKey": @{@"nested": @"value"}
    };

    PSMTabGroup *group = [PSMTabGroup groupFromArrangement:dict];
    XCTAssertNotNil(group);
    XCTAssertEqualObjects(group.title, @"Test");
    XCTAssertTrue(group.collapsed);
    XCTAssertEqual(group.tabGUIDs.count, 1u);
}

#pragma mark - Invalid Arrangement Data

- (void)testInvalidTitleType {
    NSDictionary *dict = @{
        @"title": @42,  // Wrong type
        @"tabGUIDs": @[@"a"]
    };
    PSMTabGroup *group = [PSMTabGroup groupFromArrangement:dict];
    XCTAssertNotNil(group);
    XCTAssertEqualObjects(group.title, @"");  // Falls back to empty string
}

- (void)testInvalidGUIDsType {
    NSDictionary *dict = @{
        @"title": @"Test",
        @"tabGUIDs": @"not an array"  // Wrong type
    };
    PSMTabGroup *group = [PSMTabGroup groupFromArrangement:dict];
    XCTAssertNotNil(group);
    XCTAssertEqual(group.tabGUIDs.count, 0u);  // Falls back to empty
}

#pragma mark - Multiple Groups Round-Trip

- (void)testMultipleGroupsRoundTrip {
    PSMTabGroup *g1 = [[[PSMTabGroup alloc] initWithTitle:@"Group A" tabGUIDs:@[@"a1", @"a2"]] autorelease];
    PSMTabGroup *g2 = [[[PSMTabGroup alloc] initWithTitle:@"Group B" tabGUIDs:@[@"b1", @"b2", @"b3"]] autorelease];
    g2.collapsed = YES;

    NSArray *dicts = @[[g1 arrangementRepresentation], [g2 arrangementRepresentation]];

    PSMTabGroup *r1 = [PSMTabGroup groupFromArrangement:dicts[0]];
    PSMTabGroup *r2 = [PSMTabGroup groupFromArrangement:dicts[1]];

    XCTAssertEqualObjects(r1.identifier, g1.identifier);
    XCTAssertEqualObjects(r1.title, @"Group A");
    XCTAssertEqual(r1.tabGUIDs.count, 2u);
    XCTAssertFalse(r1.collapsed);

    XCTAssertEqualObjects(r2.identifier, g2.identifier);
    XCTAssertEqualObjects(r2.title, @"Group B");
    XCTAssertEqual(r2.tabGUIDs.count, 3u);
    XCTAssertTrue(r2.collapsed);
}

#pragma mark - Copy Behavior

- (void)testCopyProducesIdenticalGroup {
    PSMTabGroup *original = [[[PSMTabGroup alloc] initWithTitle:@"Original" tabGUIDs:@[@"a", @"b"]] autorelease];
    original.collapsed = YES;

    PSMTabGroup *copy = [[original copy] autorelease];

    XCTAssertEqualObjects(copy.identifier, original.identifier);
    XCTAssertEqualObjects(copy.title, original.title);
    XCTAssertEqual(copy.collapsed, original.collapsed);
    XCTAssertEqualObjects(copy.tabGUIDs, original.tabGUIDs);

    // Verify they're independent
    [copy addTabGUID:@"c"];
    XCTAssertEqual(copy.tabGUIDs.count, 3u);
    XCTAssertEqual(original.tabGUIDs.count, 2u);
}

@end
