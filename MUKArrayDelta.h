#import <Foundation/Foundation.h>

/**
 Type of match between two items
 */
typedef NS_ENUM(NSInteger, MUKArrayDeltaMatchType) {
    /**
     No match: items are different
     */
    MUKArrayDeltaMatchTypeNone,
    /**
     Partial match: items are not equal because they change from source array
     to destination array
     */
    MUKArrayDeltaMatchTypeChange,
    /**
     Complete match
     */
    MUKArrayDeltaMatchTypeEqual
};

/**
 Comparator which takes two items and returns match type
 */
typedef MUKArrayDeltaMatchType (^MUKArrayDeltaMatchTest)(id object1, id object2);

/**
 An object which tells you diffs between two arrays
 */
@interface MUKArrayDelta : NSObject
/**
 Source array
 */
@property (nonatomic, copy, readonly) NSArray *sourceArray;
/**
 Destination array
 */
@property (nonatomic, copy, readonly) NSArray *destinationArray;
/**
 Inserted indexes. Indexes refer to destinationArray.
 */
@property (nonatomic, readonly) NSIndexSet *insertedIndexes;
/**
 Deleted indexes. Indexes refer to sourceArray.
 */
@property (nonatomic, readonly) NSIndexSet *deletedIndexes;
/**
 Changed indexes. Indexes refer to sourceArray.
 */
@property (nonatomic, readonly) NSIndexSet *changedIndexes;
/**
 Array of MUKArrayDeltaMovement objects
 */
@property (nonatomic, readonly) NSArray *movements;
/**
 Designated initializer.
 @param sourceArray         Source array
 @param destinationArray    Destination array
 @param matchTest           A block to compare source and destination items.
                            It may be nil but you lose changes detection.
 @returns A fully initialized delta between sourceArray and destinationArray
 */
- (instancetype)initWithSourceArray:(NSArray *)sourceArray destinationArray:(NSArray *)destinationArray matchTest:(MUKArrayDeltaMatchTest)matchTest;
/**
 @returns YES when two deltas are equal
 */
- (BOOL)isEqualToArrayDelta:(MUKArrayDelta *)arrayDelta;
@end

/**
 A movement from source array to destination array
 */
@interface MUKArrayDeltaMovement : NSObject
/**
 Index of moved item in source array
 */
@property (nonatomic, readonly) NSUInteger sourceIndex;
/**
 Index of moved item in destination array
 */
@property (nonatomic, readonly) NSUInteger destinationIndex;
/**
 Designated initializer
 */
- (instancetype)initWithSourceIndex:(NSUInteger)sourceIndex destinationIndex:(NSUInteger)destinationIndex;
/**
 @returns A movement with flipped sourceIndex and destinationIndex
 */
- (instancetype)inverseMovement;
/**
 @returns YES when two movements are equal
 */
- (BOOL)isEqualToArrayDeltaMovement:(MUKArrayDeltaMovement *)movement;
@end
