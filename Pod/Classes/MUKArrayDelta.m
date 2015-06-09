//
//  MUKArrayDelta.m
//  
//
//  Created by Marco on 08/06/15.
//
//

#import "MUKArrayDelta.h"

@interface MUKArrayDeltaIndexedArray : NSObject
@property (nonatomic, readonly, copy) NSArray *array;
@property (nonatomic, readonly, copy) NSIndexSet *indexes;
@end

@implementation MUKArrayDeltaIndexedArray

- (instancetype)initWithArray:(NSArray *)array indexes:(NSIndexSet *)indexes {
    self = [super init];
    if (self) {
        _array = [array copy];
        _indexes = [indexes copy];
    }
    
    return self;
}

- (instancetype)initWithArray:(NSArray *)array {
    return [self initWithArray:array indexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, array.count)]];
}

- (instancetype)initWithArray:(NSArray *)array excludingIndexes:(NSIndexSet *)excludedIndexes
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, array.count)];
    [indexes removeIndexes:excludedIndexes];
    return [self initWithArray:array indexes:indexes];
}

@end

#pragma mark -

@implementation MUKArrayDeltaMovement

- (instancetype)initWithSourceIndex:(NSUInteger)sourceIndex destinationIndex:(NSUInteger)destinationIndex
{
    self = [super init];
    if (self) {
        _sourceIndex = sourceIndex;
        _destinationIndex = destinationIndex;
    }
    
    return self;
}

- (BOOL)isEqualToArrayDeltaMovement:(MUKArrayDeltaMovement *)movement {
    return self.sourceIndex == movement.sourceIndex && self.destinationIndex == movement.destinationIndex;
}

- (instancetype)inverseMovement {
    return [[[self class] alloc] initWithSourceIndex:self.destinationIndex destinationIndex:self.sourceIndex];
}

#pragma mark Overrides

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if ([object isKindOfClass:[self class]]) {
        return [self isEqualToArrayDeltaMovement:object];
    }
    
    return NO;
}

- (NSUInteger)hash {
    return 67829043 ^ self.sourceIndex ^ self.destinationIndex;
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@" (%ld -> %ld)", self.sourceIndex, self.destinationIndex];
}

@end

#pragma mark -

@implementation MUKArrayDelta

- (instancetype)initWithSourceArray:(NSArray *)sourceArray destinationArray:(NSArray *)destinationArray matchTest:(MUKArrayDeltaMatchTest)matchTest
{
    self = [super init];
    if (self) {
        _sourceArray = [sourceArray copy];
        _destinationArray = [destinationArray copy];
        
        // Ensure a match test
        BOOL usesDefaultMatchTest = NO;
        if (!matchTest) {
            matchTest = [[self class] defaultMatchTest];
            usesDefaultMatchTest = YES;
        }
        
        // Movements
        {
            MUKArrayDeltaIndexedArray *const source = [[MUKArrayDeltaIndexedArray alloc] initWithArray:sourceArray];
            MUKArrayDeltaIndexedArray *const destination = [[MUKArrayDeltaIndexedArray alloc] initWithArray:destinationArray];
            _movements = [[self class] movementsFromSourceArray:source toDestinationArray:destination matchTest:matchTest];
        }
        
        // Inserted indexes
        {
            MUKArrayDeltaIndexedArray *const source = [[MUKArrayDeltaIndexedArray alloc] initWithArray:sourceArray excludingIndexes:[[self class] sourceIndexesFromMovements:_movements]];
            MUKArrayDeltaIndexedArray *const destination = [[MUKArrayDeltaIndexedArray alloc] initWithArray:destinationArray excludingIndexes:[[self class] destinationIndexesFromMovements:_movements]];
            _insertedIndexes = [[self class] insertedIndexesFromSourceArray:source toDestinationArray:destination matchTest:matchTest];
        }
        
        // Deleted indexes
        {
            MUKArrayDeltaIndexedArray *const source = [[MUKArrayDeltaIndexedArray alloc] initWithArray:sourceArray excludingIndexes:[[self class] sourceIndexesFromMovements:_movements]];

            NSMutableIndexSet *const indexSet = [[[self class] destinationIndexesFromMovements:_movements] mutableCopy];
            [indexSet addIndexes:_insertedIndexes];
            MUKArrayDeltaIndexedArray *const destination = [[MUKArrayDeltaIndexedArray alloc] initWithArray:destinationArray excludingIndexes:indexSet];
            
            _deletedIndexes = [[self class] deletedIndexesFromSourceArray:source toDestinationArray:destination matchTest:matchTest];
        }
        
        // Clean movements
        _movements = [[self class] movementsByCleaningMovements:_movements fromInsertedIndexes:_insertedIndexes deletedIndexes:_deletedIndexes];
        
        // Changed indexes (default match test can't spot changes)
        if (!usesDefaultMatchTest) {
            MUKArrayDeltaIndexedArray *const source = [[MUKArrayDeltaIndexedArray alloc] initWithArray:sourceArray excludingIndexes:_deletedIndexes];
            MUKArrayDeltaIndexedArray *const destination = [[MUKArrayDeltaIndexedArray alloc] initWithArray:destinationArray excludingIndexes:_insertedIndexes];
            
            _changedIndexes = [[self class] changedIndexesFromSourceArray:source toDestinationArray:destination matchTest:matchTest];
        }
    }

    return self;
}

#pragma mark Private

+ (MUKArrayDeltaMatchTest)defaultMatchTest {
    return ^(id obj1, id obj2) {
        if ([obj1 isEqual:obj2]) {
            return MUKArrayDeltaMatchTypeEqual;
        }
        
        return MUKArrayDeltaMatchTypeNone;
    };
}

+ (NSIndexSet *)insertedIndexesFromSourceArray:(MUKArrayDeltaIndexedArray *)source toDestinationArray:(MUKArrayDeltaIndexedArray *)destination matchTest:(MUKArrayDeltaMatchTest)matchTest
{
    return [destination.array indexesOfObjectsAtIndexes:destination.indexes options:0 passingTest:^BOOL(id dstObj, NSUInteger dstIdx, BOOL *stop)
    {
        NSUInteger const srcIdx = [source.array indexOfObjectAtIndexes:source.indexes options:0 passingTest:^BOOL(id srcObj, NSUInteger srcIdx, BOOL *stop)
        {
            MUKArrayDeltaMatchType const matchType = matchTest(srcObj, dstObj);
            
            if (matchType != MUKArrayDeltaMatchTypeNone) {
                // Complete or partial match
                *stop = YES;
                return YES;
            }
            
            return NO;
        }]; // indexOfObjectPassingTest:
        
        if (srcIdx == NSNotFound) {
            // No matching source object means it's a new object
            return YES;
        }
        
        return NO;
    }]; // indexesOfObjectsPassingTest:
}

+ (NSIndexSet *)deletedIndexesFromSourceArray:(MUKArrayDeltaIndexedArray *)source toDestinationArray:(MUKArrayDeltaIndexedArray *)destination matchTest:(MUKArrayDeltaMatchTest)matchTest
{
    return [source.array indexesOfObjectsAtIndexes:source.indexes options:0 passingTest:^BOOL(id srcObj, NSUInteger srcIdx, BOOL *stop)
    {
        NSUInteger const dstIdx = [destination.array indexOfObjectAtIndexes:destination.indexes options:0 passingTest:^BOOL(id dstObj, NSUInteger dstIdx, BOOL *stop)
        {
            MUKArrayDeltaMatchType const matchType = matchTest(srcObj, dstObj);
            
            if (matchType != MUKArrayDeltaMatchTypeNone) {
                // Complete or partial match
                *stop = YES;
                return YES;
            }
            
            return NO;
        }]; // indexOfObjectPassingTest:
        
        if (dstIdx == NSNotFound) {
            // No matching destination object means it's a deleted object
            return YES;
        }
        
        return NO;
    }]; // indexesOfObjectsPassingTest:
}

+ (NSIndexSet *)changedIndexesFromSourceArray:(MUKArrayDeltaIndexedArray *)source toDestinationArray:(MUKArrayDeltaIndexedArray *)destination matchTest:(MUKArrayDeltaMatchTest)matchTest
{
    return [source.array indexesOfObjectsAtIndexes:source.indexes options:0 passingTest:^BOOL(id srcObj, NSUInteger srcIdx, BOOL *stop)
    {
        NSUInteger const dstIdx = [destination.array indexOfObjectAtIndexes:destination.indexes options:0 passingTest:^BOOL(id dstObj, NSUInteger dstIdx, BOOL *stop)
        {
            MUKArrayDeltaMatchType const matchType = matchTest(srcObj, dstObj);
            
            if (matchType == MUKArrayDeltaMatchTypeChange) {
                // Partial match
                *stop = YES;
                return YES;
            }
            
            return NO;
        }]; // indexOfObjectPassingTest:
        
        if (dstIdx != NSNotFound) {
            return YES;
        }
        
        return NO;
    }]; // indexesOfObjectsPassingTest:
}

+ (NSArray *)movementsFromSourceArray:(MUKArrayDeltaIndexedArray *)source toDestinationArray:(MUKArrayDeltaIndexedArray *)destination matchTest:(MUKArrayDeltaMatchTest)matchTest
{
    NSMutableArray *const movements = [NSMutableArray array];
    NSMutableIndexSet *const consumedDestinationIndexes = [NSMutableIndexSet indexSet];
    
    NSUInteger const (^normalizeDestinationIndex)(NSUInteger) = ^(NSUInteger idx) {
        NSUInteger normalizedIndex = idx;
        
        for (MUKArrayDeltaMovement *const movement in movements) {
            if (movement.sourceIndex < idx && movement.destinationIndex > idx) {
                normalizedIndex++;
            }
            else if (movement.sourceIndex > idx && movement.destinationIndex < idx)
            {
                normalizedIndex--;
            }
        } // for
        
        return normalizedIndex;
    };
    
    [source.array enumerateObjectsAtIndexes:source.indexes options:0 usingBlock:^(id srcObj, NSUInteger srcIdx, BOOL *stop)
    {
        NSUInteger const dstIdx = [destination.array indexOfObjectAtIndexes:destination.indexes options:0 passingTest:^BOOL(id dstObj, NSUInteger dstIdx, BOOL *stop)
        {
            if ([consumedDestinationIndexes containsIndex:dstIdx]) {
                // Already visited
                return NO;
            }
            
            if (srcIdx == dstIdx) {
                // Not a movement
                return NO;
            }
            
            // Calculate temporary destination index after these movements
            NSUInteger const normalizedDestinationIndex = normalizeDestinationIndex(dstIdx);
            if (srcIdx == normalizedDestinationIndex) {
                // Not a movement
                return NO;
            }
            
            MUKArrayDeltaMatchType const matchType = matchTest(srcObj, dstObj);
            if (matchType != MUKArrayDeltaMatchTypeNone) {
                *stop = YES;
                return YES;
            }
            
            return NO;
        }]; // indexOfObjectPassingTest:
        
        if (dstIdx != NSNotFound) {
            MUKArrayDeltaMovement *const movement = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:srcIdx destinationIndex:dstIdx];
            if (![movements containsObject:[movement inverseMovement]]) {
                [movements addObject:movement];
                [consumedDestinationIndexes addIndex:dstIdx];
            }
        }
    }]; // enumerateObjectsUsingBlock:
    
    return [movements copy];
}

+ (NSArray *)movementsByCleaningMovements:(NSArray *)originalMovements fromInsertedIndexes:(NSIndexSet *)insertedIndexes deletedIndexes:(NSIndexSet *)deletedIndexes
{
    NSMutableArray *const movements = [NSMutableArray arrayWithCapacity:originalMovements.count];
    NSMutableArray *const normalizedMovements = [NSMutableArray arrayWithCapacity:originalMovements.count];
    
    [originalMovements enumerateObjectsUsingBlock:^(MUKArrayDeltaMovement *movement, NSUInteger idx, BOOL *stop)
    {
        NSInteger normalizedSourceIndex = movement.sourceIndex;
        NSInteger normalizedDestinationIndex = movement.destinationIndex;
        
        // Check modifications
        normalizedSourceIndex -= [deletedIndexes countOfIndexesInRange:NSMakeRange(0, movement.sourceIndex + 1)];
        normalizedDestinationIndex -= [insertedIndexes countOfIndexesInRange:NSMakeRange(0, movement.destinationIndex + 1)];
  
        if (normalizedSourceIndex != normalizedDestinationIndex) {
            MUKArrayDeltaMovement *const normalizedMovement = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:normalizedSourceIndex destinationIndex:normalizedDestinationIndex];
            
            if (![normalizedMovements containsObject:[normalizedMovement inverseMovement]])
            {
                [movements addObject:movement];
                [normalizedMovements addObject:normalizedMovement];
            }
        }
    }]; // enumerateObjectsUsingBlock:
    
    return [movements copy];
}

+ (NSIndexSet *)sourceIndexesFromMovements:(NSArray *)movements {
    NSMutableIndexSet *const indexSet = [NSMutableIndexSet indexSet];
    
    for (MUKArrayDeltaMovement *movement in movements) {
        [indexSet addIndex:movement.sourceIndex];
    } // for
    
    return [indexSet copy];
}

+ (NSIndexSet *)destinationIndexesFromMovements:(NSArray *)movements {
    NSMutableIndexSet *const indexSet = [NSMutableIndexSet indexSet];
    
    for (MUKArrayDeltaMovement *movement in movements) {
        [indexSet addIndex:movement.destinationIndex];
    } // for
    
    return [indexSet copy];
}

@end
