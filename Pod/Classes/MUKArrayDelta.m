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
        
        // Inserted indexes
        {
            MUKArrayDeltaIndexedArray *const source = [[MUKArrayDeltaIndexedArray alloc] initWithArray:sourceArray];
            MUKArrayDeltaIndexedArray *const destination = [[MUKArrayDeltaIndexedArray alloc] initWithArray:destinationArray];
            _insertedIndexes = [[self class] insertedIndexesFromSourceArray:source toDestinationArray:destination matchTest:matchTest];
        }
        
        // Deleted indexes
        {
            MUKArrayDeltaIndexedArray *const source = [[MUKArrayDeltaIndexedArray alloc] initWithArray:sourceArray];
            MUKArrayDeltaIndexedArray *const destination = [[MUKArrayDeltaIndexedArray alloc] initWithArray:destinationArray excludingIndexes:_insertedIndexes];
            _deletedIndexes = [[self class] deletedIndexesFromSourceArray:source toDestinationArray:destination matchTest:matchTest];
        }
        
        if (!usesDefaultMatchTest) {
            // Default match test can't spot changes
           
            MUKArrayDeltaIndexedArray *const source = [[MUKArrayDeltaIndexedArray alloc] initWithArray:sourceArray excludingIndexes:_deletedIndexes];
            MUKArrayDeltaIndexedArray *const destination = [[MUKArrayDeltaIndexedArray alloc] initWithArray:destinationArray excludingIndexes:_insertedIndexes];
            
            _changedIndexes = [[self class] changedIndexesFromSourceArray:source toDestinationArray:destination matchTest:matchTest];
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
    return [destination.array indexesOfObjectsAtIndexes:destination.indexes options:0 passingTest:^BOOL(id dstObj, NSUInteger dstIdx, BOOL *stop)
    {
        NSUInteger const srcIdx = [source.array indexOfObjectAtIndexes:source.indexes options:0 passingTest:^BOOL(id srcObj, NSUInteger srcIdx, BOOL *stop)
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
