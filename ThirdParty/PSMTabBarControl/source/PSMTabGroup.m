//
//  PSMTabGroup.m
//  PSMTabBarControl
//

#import "PSMTabGroup.h"

static NSString *const kPSMTabGroupIdentifier = @"identifier";
static NSString *const kPSMTabGroupTitle = @"title";
static NSString *const kPSMTabGroupCollapsed = @"collapsed";
static NSString *const kPSMTabGroupTabGUIDs = @"tabGUIDs";

@implementation PSMTabGroup {
    NSMutableArray<NSString *> *_tabGUIDs;
}

- (instancetype)initWithTitle:(NSString *)title {
    return [self initWithTitle:title tabGUIDs:@[]];
}

- (instancetype)initWithTitle:(NSString *)title tabGUIDs:(NSArray<NSString *> *)guids {
    self = [super init];
    if (self) {
        _identifier = [[[NSUUID UUID] UUIDString] copy];
        _title = [title copy];
        _collapsed = NO;
        _tabGUIDs = [[NSMutableArray alloc] initWithArray:guids ?: @[]];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    PSMTabGroup *copy = [[PSMTabGroup alloc] initWithTitle:_title tabGUIDs:_tabGUIDs];
    copy->_collapsed = _collapsed;
    // Copy gets its own new identifier by default from initWithTitle:tabGUIDs:.
    // For a true copy, override it.
    copy->_identifier = [_identifier copy];
    return copy;
}

- (NSArray<NSString *> *)tabGUIDs {
    return [_tabGUIDs copy];
}

- (void)addTabGUID:(NSString *)guid {
    if (!guid) {
        return;
    }
    if ([_tabGUIDs containsObject:guid]) {
        return;
    }
    [_tabGUIDs addObject:guid];
}

- (void)removeTabGUID:(NSString *)guid {
    [_tabGUIDs removeObject:guid];
}

- (BOOL)containsTabGUID:(NSString *)guid {
    return [_tabGUIDs containsObject:guid];
}

- (NSUInteger)indexOfTabGUID:(NSString *)guid {
    return [_tabGUIDs indexOfObject:guid];
}

#pragma mark - Arrangement

- (NSDictionary *)arrangementRepresentation {
    return @{
        kPSMTabGroupIdentifier: _identifier ?: @"",
        kPSMTabGroupTitle: _title ?: @"",
        kPSMTabGroupCollapsed: @(_collapsed),
        kPSMTabGroupTabGUIDs: [_tabGUIDs copy] ?: @[]
    };
}

+ (instancetype)groupFromArrangement:(NSDictionary *)arrangement {
    if (!arrangement || ![arrangement isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *title = arrangement[kPSMTabGroupTitle];
    NSArray *guids = arrangement[kPSMTabGroupTabGUIDs];
    if (![title isKindOfClass:[NSString class]]) {
        title = @"";
    }
    if (![guids isKindOfClass:[NSArray class]]) {
        guids = @[];
    }

    PSMTabGroup *group = [[PSMTabGroup alloc] initWithTitle:title tabGUIDs:guids];

    NSString *identifier = arrangement[kPSMTabGroupIdentifier];
    if ([identifier isKindOfClass:[NSString class]] && identifier.length > 0) {
        group->_identifier = [identifier copy];
    }

    NSNumber *collapsed = arrangement[kPSMTabGroupCollapsed];
    if ([collapsed isKindOfClass:[NSNumber class]]) {
        group->_collapsed = [collapsed boolValue];
    }

    return group;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p id=%@ title=%@ collapsed=%@ tabs=%@>",
            NSStringFromClass([self class]), self, _identifier, _title, @(_collapsed), _tabGUIDs];
}

@end
