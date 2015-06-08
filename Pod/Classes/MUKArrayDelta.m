//
//  MUKArrayDelta.m
//  
//
//  Created by Marco on 08/06/15.
//
//

#import "MUKArrayDelta.h"

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

@end


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
        
        _insertedIndexes = [[self class] insertedIndexesFromSourceArray:sourceArray toDestinationArray:destinationArray matchTest:matchTest];
        
        {
            NSArray *const filteredDestinationArray = [[self class] array:destinationArray removingIndexes:_insertedIndexes];
            _deletedIndexes = [[self class] deletedIndexesFromSourceArray:sourceArray toDestinationArray:filteredDestinationArray matchTest:matchTest];
        }
        
        if (!usesDefaultMatchTest) {
            // Default match test can't spot changes
            NSArray *const filteredSourceArray = [[self class] array:sourceArray removingIndexes:_deletedIndexes];
            NSArray *const filteredDestinationArray = [[self class] array:destinationArray removingIndexes:_insertedIndexes];

            _changedIndexes = [[self class] changedIndexesFromSourceArray:filteredSourceArray toDestinationArray:filteredDestinationArray matchTest:matchTest];
        }
    }

    return self;
}

#pragma mark - Private

+ (MUKArrayDeltaMatchTest)defaultMatchTest {
    return ^(id obj1, id obj2) {
        if ([obj1 isEqual:obj2]) {
            return MUKArrayDeltaMatchTypeEqual;
        }
        
        return MUKArrayDeltaMatchTypeNone;
    };
}

+ (NSArray *)array:(NSArray *)array removingIndexes:(NSIndexSet *)discardedIndexes
{
    if (discardedIndexes.count == 0) {
        return array;
    }
    
    NSMutableIndexSet *const indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, array.count)];
    [indexes removeIndexes:discardedIndexes];
    return [array objectsAtIndexes:indexes];
}

+ (NSIndexSet *)insertedIndexesFromSourceArray:(NSArray *)sourceArray toDestinationArray:(NSArray *)destinationArray matchTest:(MUKArrayDeltaMatchTest)matchTest
{
    return [destinationArray indexesOfObjectsPassingTest:^BOOL(id dstObj, NSUInteger dstIdx, BOOL *stop)
    {
        NSUInteger const srcIdx = [sourceArray indexOfObjectPassingTest:^BOOL(id srcObj, NSUInteger srcIdx, BOOL *stop)
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

+ (NSIndexSet *)deletedIndexesFromSourceArray:(NSArray *)sourceArray toDestinationArray:(NSArray *)destinationArray matchTest:(MUKArrayDeltaMatchTest)matchTest
{
    return [sourceArray indexesOfObjectsPassingTest:^BOOL(id srcObj, NSUInteger srcIdx, BOOL *stop)
    {
        NSUInteger const dstIdx = [destinationArray indexOfObjectPassingTest:^BOOL(id dstObj, NSUInteger dstIdx, BOOL *stop)
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

+ (NSIndexSet *)changedIndexesFromSourceArray:(NSArray *)sourceArray toDestinationArray:(NSArray *)destinationArray matchTest:(MUKArrayDeltaMatchTest)matchTest
{
    return [destinationArray indexesOfObjectsPassingTest:^BOOL(id dstObj, NSUInteger dstIdx, BOOL *stop)
    {
        NSUInteger const srcIdx = [sourceArray indexOfObjectPassingTest:^BOOL(id srcObj, NSUInteger srcIdx, BOOL *stop)
        {
            MUKArrayDeltaMatchType const matchType = matchTest(srcObj, dstObj);
            
            if (matchType == MUKArrayDeltaMatchTypeChange) {
                // Partial match
                *stop = YES;
                return YES;
            }
            
            return NO;
        }]; // indexOfObjectPassingTest:
        
        if (srcIdx != NSNotFound) {
            return YES;
        }
        
        return NO;
    }]; // indexesOfObjectsPassingTest:
}

@end
