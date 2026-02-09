//
//  PSMTabGroupTest.m
//  iTerm2
//
//  Unit tests for PSMTabGroup model.
//

#import <XCTest/XCTest.h>
#import "PSMTabGroup.h"

@interface PSMTabGroupTest : XCTestCase
@end

@implementation PSMTabGroupTest

#pragma mark - Creation

- (void)testInitWithTitle {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"Test Group"] autorelease];
    XCTAssertNotNil(group);
    XCTAssertEqualObjects(group.title, @"Test Group");
    XCTAssertNotNil(group.identifier);
    XCTAssertTrue(group.identifier.length > 0);
    XCTAssertFalse(group.collapsed);
    XCTAssertEqual(group.tabGUIDs.count, 0u);
}

- (void)testInitWithTitleAndGUIDs {
    NSArray *guids = @[@"guid-1", @"guid-2", @"guid-3"];
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"My Group" tabGUIDs:guids] autorelease];
    XCTAssertEqualObjects(group.title, @"My Group");
    XCTAssertEqual(group.tabGUIDs.count, 3u);
    XCTAssertEqualObjects(group.tabGUIDs[0], @"guid-1");
    XCTAssertEqualObjects(group.tabGUIDs[1], @"guid-2");
    XCTAssertEqualObjects(group.tabGUIDs[2], @"guid-3");
}

#pragma mark - Add/Remove

- (void)testAddTabGUID {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G"] autorelease];
    [group addTabGUID:@"a"];
    [group addTabGUID:@"b"];
    [group addTabGUID:@"c"];
    XCTAssertEqual(group.tabGUIDs.count, 3u);
    XCTAssertEqualObjects(group.tabGUIDs[0], @"a");
    XCTAssertEqualObjects(group.tabGUIDs[1], @"b");
    XCTAssertEqualObjects(group.tabGUIDs[2], @"c");
}

- (void)testRemoveTabGUID {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G" tabGUIDs:@[@"a", @"b", @"c"]] autorelease];
    [group removeTabGUID:@"b"];
    XCTAssertEqual(group.tabGUIDs.count, 2u);
    XCTAssertEqualObjects(group.tabGUIDs[0], @"a");
    XCTAssertEqualObjects(group.tabGUIDs[1], @"c");
}

- (void)testRemoveNonexistentGUID {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G" tabGUIDs:@[@"a"]] autorelease];
    [group removeTabGUID:@"z"];
    XCTAssertEqual(group.tabGUIDs.count, 1u);
}

- (void)testOrderingPreserved {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G"] autorelease];
    [group addTabGUID:@"first"];
    [group addTabGUID:@"second"];
    [group addTabGUID:@"third"];
    XCTAssertEqualObjects(group.tabGUIDs[0], @"first");
    XCTAssertEqualObjects(group.tabGUIDs[1], @"second");
    XCTAssertEqualObjects(group.tabGUIDs[2], @"third");
}

#pragma mark - Lookup

- (void)testContainsTabGUID {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G" tabGUIDs:@[@"a", @"b"]] autorelease];
    XCTAssertTrue([group containsTabGUID:@"a"]);
    XCTAssertTrue([group containsTabGUID:@"b"]);
    XCTAssertFalse([group containsTabGUID:@"c"]);
}

- (void)testIndexOfTabGUID {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G" tabGUIDs:@[@"x", @"y", @"z"]] autorelease];
    XCTAssertEqual([group indexOfTabGUID:@"x"], 0u);
    XCTAssertEqual([group indexOfTabGUID:@"y"], 1u);
    XCTAssertEqual([group indexOfTabGUID:@"z"], 2u);
    XCTAssertEqual([group indexOfTabGUID:@"missing"], (NSUInteger)NSNotFound);
}

#pragma mark - Collapse

- (void)testCollapseState {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G"] autorelease];
    XCTAssertFalse(group.collapsed);
    group.collapsed = YES;
    XCTAssertTrue(group.collapsed);
    group.collapsed = NO;
    XCTAssertFalse(group.collapsed);
}

#pragma mark - Duplicate Prevention

- (void)testDuplicateGUIDPrevention {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G"] autorelease];
    [group addTabGUID:@"a"];
    [group addTabGUID:@"a"];
    [group addTabGUID:@"a"];
    XCTAssertEqual(group.tabGUIDs.count, 1u);
}

- (void)testAddNilGUID {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"G"] autorelease];
    [group addTabGUID:nil];
    XCTAssertEqual(group.tabGUIDs.count, 0u);
}

#pragma mark - Arrangement Round-Trip

- (void)testArrangementRoundTrip {
    PSMTabGroup *group = [[[PSMTabGroup alloc] initWithTitle:@"My Group" tabGUIDs:@[@"a", @"b", @"c"]] autorelease];
    group.collapsed = YES;

    NSDictionary *dict = [group arrangementRepresentation];
    XCTAssertNotNil(dict);

    PSMTabGroup *restored = [PSMTabGroup groupFromArrangement:dict];
    XCTAssertNotNil(restored);
    XCTAssertEqualObjects(restored.identifier, group.identifier);
    XCTAssertEqualObjects(restored.title, @"My Group");
    XCTAssertTrue(restored.collapsed);
    XCTAssertEqualObjects(restored.tabGUIDs, group.tabGUIDs);
}

- (void)testArrangementWithMissingKeys {
    PSMTabGroup *restored = [PSMTabGroup groupFromArrangement:@{}];
    XCTAssertNotNil(restored);
    XCTAssertEqualObjects(restored.title, @"");
    XCTAssertEqual(restored.tabGUIDs.count, 0u);
    XCTAssertFalse(restored.collapsed);
}

- (void)testArrangementFromNilDictionary {
    PSMTabGroup *restored = [PSMTabGroup groupFromArrangement:nil];
    XCTAssertNil(restored);
}

- (void)testArrangementFromNonDictionary {
    PSMTabGroup *restored = [PSMTabGroup groupFromArrangement:(NSDictionary *)@"not a dict"];
    XCTAssertNil(restored);
}

- (void)testArrangementWithExtraKeys {
    NSDictionary *dict = @{
        @"identifier": @"some-id",
        @"title": @"Test",
        @"collapsed": @NO,
        @"tabGUIDs": @[@"x"],
        @"unknownKey": @"unknownValue",
        @"anotherUnknown": @42
    };
    PSMTabGroup *restored = [PSMTabGroup groupFromArrangement:dict];
    XCTAssertNotNil(restored);
    XCTAssertEqualObjects(restored.title, @"Test");
}

@end
