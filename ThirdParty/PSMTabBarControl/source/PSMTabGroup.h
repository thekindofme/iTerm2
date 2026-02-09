//
//  PSMTabGroup.h
//  PSMTabBarControl
//
//  Lightweight model representing a named group of tabs in a vertical tab bar.
//  References tabs by GUID (NSString) to avoid retaining tab objects.
//

#import <Cocoa/Cocoa.h>

@interface PSMTabGroup : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL collapsed;
@property (nonatomic, copy) NSColor *color;
@property (nonatomic, readonly) NSArray<NSString *> *tabGUIDs;

- (instancetype)initWithTitle:(NSString *)title;
- (instancetype)initWithTitle:(NSString *)title tabGUIDs:(NSArray<NSString *> *)guids;

- (void)addTabGUID:(NSString *)guid;
- (void)removeTabGUID:(NSString *)guid;
- (BOOL)containsTabGUID:(NSString *)guid;
- (NSUInteger)indexOfTabGUID:(NSString *)guid;

// Arrangement serialization
- (NSDictionary *)arrangementRepresentation;
+ (instancetype)groupFromArrangement:(NSDictionary *)arrangement;

@end
